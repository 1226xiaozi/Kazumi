import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/bean/widget/empty_state_widget.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/modules/collect/collect_module.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/pages/collect/collect_library_query.dart';

part 'collect_library_card.dart';
part 'collect_library_controls.dart';

const _collectCategories = <CollectType?>[
  null,
  CollectType.watching,
  CollectType.planToWatch,
  CollectType.watched,
  CollectType.onHold,
  CollectType.abandoned,
];

class CollectLibraryView extends StatefulWidget {
  const CollectLibraryView({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onChangeType,
    required this.canEdit,
    required this.layout,
    required this.sort,
    required this.searchExpanded,
    required this.onSearchExpandedChanged,
    required this.count,
  });

  final List<CollectedBangumi> entries;
  final ValueChanged<BangumiItem> onOpen;
  final void Function(BangumiItem, CollectType) onChangeType;
  final bool Function(BangumiItem) canEdit;
  final CollectLayout layout;
  final CollectSort sort;
  final bool searchExpanded;
  final ValueChanged<bool> onSearchExpandedChanged;

  /// Mirrors the visible category's total into the app bar title.
  final ValueNotifier<int> count;

  @override
  State<CollectLibraryView> createState() => _CollectLibraryViewState();
}

class _CollectLibraryViewState extends State<CollectLibraryView>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _libraryFocus = FocusNode();
  // Keep tab animations alive when the category scroll view is replaced.
  final _categoriesKey = GlobalKey();
  late TabController _tabController;
  bool? _disableAnimations;
  final _scrollControllers = {
    for (final type in _collectCategories) type: ScrollController(),
  };
  PageStorageBucket _resultsStorage = PageStorageBucket();
  String _query = '';
  CollectLibraryQuery? _lastQuery;

  // The tapped tab while a tap animates, otherwise the dominant page so swipes
  // update mid-gesture. Tab switches rebuild nothing but its listeners.
  final _selectedType = ValueNotifier<CollectType?>(CollectType.watching);

  @override
  void initState() {
    super.initState();
    _selectedType.addListener(_libraryFocus.requestFocus);
    _selectedType.addListener(_reportCount);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations == disableAnimations) return;
    if (_disableAnimations != null) {
      _tabController.dispose();
    }
    _disableAnimations = disableAnimations;
    _tabController = TabController(
      length: _collectCategories.length,
      initialIndex: _collectCategories.indexOf(_selectedType.value),
      animationDuration: disableAnimations ? Duration.zero : null,
      vsync: this,
    )
      ..addListener(_syncSelectedType)
      ..animation!.addListener(_syncSelectedType);
  }

  void _syncSelectedType() {
    final index = _tabController.indexIsChanging
        ? _tabController.index
        : _tabController.animation!.value
            .round()
            .clamp(0, _collectCategories.length - 1);
    _selectedType.value = _collectCategories[index];
  }

  @override
  void didUpdateWidget(covariant CollectLibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout || oldWidget.sort != widget.sort) {
      _resetResults();
    }
    if (oldWidget.searchExpanded != widget.searchExpanded) {
      if (widget.searchExpanded) {
        _openSearch();
      } else {
        _clearSearch();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selectedType.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _libraryFocus.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetResults() {
    // Reset saved offsets for unmounted categories too.
    _resultsStorage = PageStorageBucket();
    for (final controller in _scrollControllers.values) {
      if (controller.hasClients) controller.jumpTo(0);
    }
  }

  /// Mirrors the visible category total into the app bar title.
  void _reportCount() {
    final query = _lastQuery;
    if (query == null) return;
    final value = query.count(_selectedType.value);
    if (widget.count.value == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.count.value != value) widget.count.value = value;
    });
  }

  void _openSearch() {
    final controller = _scrollControllers[_selectedType.value]!;
    if (controller.hasClients) controller.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _focusSearch() => widget.onSearchExpandedChanged(true);

  void _closeSearch() => widget.onSearchExpandedChanged(false);

  void _clearSearch() {
    _searchController.clear();
    _query = '';
    _resetResults();
    _libraryFocus.requestFocus();
  }

  void _search(String value) {
    setState(() {
      _query = value;
      _resetResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = CollectLibraryQuery(widget.entries, _query);
    _lastQuery = query;
    _reportCount();
    final platform = Theme.of(context).platform;
    final mobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
      },
      child: Focus(
        focusNode: _libraryFocus,
        autofocus: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final paged = mobile &&
              MediaQuery.orientationOf(context) == Orientation.portrait &&
              constraints.maxHeight > 320;
          final width = constraints.maxWidth.clamp(0.0, 1560.0);
          final inset =
              (constraints.maxWidth - width) / 2 + (compact ? 16.0 : 32.0);
          final header = _header(query);
          return PageStorage(
            bucket: _resultsStorage,
            child: paged
                ? Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: inset),
                        child: header,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            for (final type in _collectCategories)
                              ValueListenableBuilder(
                                valueListenable: _selectedType,
                                builder: (context, selected, child) => HeroMode(
                                  enabled: type == selected,
                                  child: child!,
                                ),
                                child: _results(query, type, inset: inset),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ValueListenableBuilder(
                    valueListenable: _selectedType,
                    builder: (context, selected, _) =>
                        _results(query, selected, inset: inset, header: header),
                  ),
          );
        }),
      ),
    );
  }

  Widget _header(CollectLibraryQuery query) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CollectCategories(
          key: _categoriesKey,
          controller: _tabController,
          selected: _selectedType,
          count: query.count,
        ),
        if (widget.searchExpanded) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _searchBar(),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _searchBar() => Semantics(
        label: '搜索收藏',
        child: SearchBar(
          controller: _searchController,
          focusNode: _searchFocus,
          leading: const Icon(Icons.search_rounded, size: 22),
          trailing: [
            if (_query.isNotEmpty)
              IconButton(
                tooltip: '清除搜索',
                onPressed: () {
                  _searchController.clear();
                  _search('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
          ],
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.surfaceContainerLow),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16)),
          constraints: const BoxConstraints(minHeight: 48),
          onChanged: _search,
          onSubmitted: (_) => _libraryFocus.requestFocus(),
        ),
      );

  Widget _results(CollectLibraryQuery query, CollectType? type,
      {required double inset, Widget? header}) {
    return LayoutBuilder(builder: (context, constraints) {
      final entries = query.results(type, widget.sort);
      final contentWidth = constraints.maxWidth - inset * 2;
      return ScrollbarTheme(
        data: ScrollbarTheme.of(context).copyWith(crossAxisMargin: 0),
        child: CustomScrollView(
          key: PageStorageKey('collect-results-${type?.value ?? 'all'}'),
          controller: _scrollControllers[type],
          semanticChildCount: entries.length,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            if (header != null)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                sliver: SliverToBoxAdapter(child: header),
              ),
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  child: _emptyState(query.count(null), type: type),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    inset, 0, inset, 24 + MediaQuery.paddingOf(context).bottom),
                sliver: widget.layout == CollectLayout.cards
                    ? _grid(entries, contentWidth, type: type)
                    : _list(entries, contentWidth),
              ),
          ],
        ),
      );
    });
  }

  Widget _list(List<CollectedBangumi> entries, double contentWidth) {
    const spacing = 12.0;
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, double.infinity);
    final minWidth = 300 + 160 * (textScale - 1);
    final preferredWidth = 400 + 160 * (textScale - 1);
    final maxColumns =
        ((contentWidth + spacing) / (minWidth + spacing)).floor().clamp(1, 12);
    final columns = ((contentWidth + spacing) / (preferredWidth + spacing))
        .ceil()
        .clamp(1, maxColumns);

    Widget tile(int index) => IndexedSemantics(
          index: index,
          child: _CollectListTile(
            key: ValueKey('collect-${entries[index].bangumiItem.id}'),
            entry: entries[index],
            onOpen: () => widget.onOpen(entries[index].bangumiItem),
            onChangeType: _changeTypeFor(entries[index]),
          ),
        );

    return SliverList.builder(
      itemCount: (entries.length + columns - 1) ~/ columns,
      addSemanticIndexes: false,
      itemBuilder: (context, row) {
        final first = row * columns;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: columns == 1
              ? tile(first)
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: spacing,
                    children: [
                      for (var column = 0; column < columns; column++)
                        Expanded(
                          child: first + column < entries.length
                              ? tile(first + column)
                              : const SizedBox(),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  ValueChanged<CollectType>? _changeTypeFor(CollectedBangumi entry) =>
      widget.canEdit(entry.bangumiItem)
          ? (type) => widget.onChangeType(entry.bangumiItem, type)
          : null;

  Widget _grid(List<CollectedBangumi> entries, double contentWidth,
      {required CollectType? type}) {
    final scaler = MediaQuery.textScalerOf(context);
    const spacing = 12.0;
    // Three columns on a phone, more once the window is genuinely wide.
    final columns = contentWidth < 600
        ? 3
        : ((contentWidth + spacing) / (168 + spacing)).floor().clamp(3, 12);
    final width = (contentWidth - spacing * (columns - 1)) / columns;
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: _CollectPosterCard.extent(width, scaler),
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _CollectPosterCard(
        key: ValueKey('collect-${entries[index].bangumiItem.id}'),
        entry: entries[index],
        showStatus: type == null,
        onOpen: () => widget.onOpen(entries[index].bangumiItem),
        onChangeType: _changeTypeFor(entries[index]),
      ),
    );
  }

  Widget _emptyState(int matchCount, {required CollectType? type}) {
    final searching = _query.trim().isNotEmpty;
    final String title;

    if (searching) {
      title = matchCount > 0 ? '当前分类没有匹配的番剧' : '没有找到匹配的番剧';
    } else if (matchCount == 0) {
      title = '还没有收藏的番剧';
    } else {
      title = switch (type) {
        CollectType.watching => '还没有在追的番剧',
        CollectType.planToWatch => '还没有想看的番剧',
        CollectType.watched => '还没有看过的番剧',
        CollectType.onHold => '没有搁置的番剧',
        CollectType.abandoned => '没有弃追的番剧',
        _ => '还没有收藏的番剧',
      };
    }
    return GeneralEmptyState(
      icon: searching ? Icons.search_off_rounded : Icons.video_library_outlined,
      title: title,
    );
  }
}
