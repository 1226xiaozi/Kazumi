part of 'collect_library_view.dart';

class _CollectCategories extends StatelessWidget {
  const _CollectCategories({
    super.key,
    required this.controller,
    required this.selected,
    required this.count,
  });

  final TabController controller;
  final ValueListenable<CollectType?> selected;
  final int Function(CollectType?) count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Each lerped weight is a new font instance, so TabBar animates only the
    // color and the selected label turns bold once per category change.
    final labelStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500);
    return TabBar(
      key: const PageStorageKey('collect-filter-strip'),
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerHeight: 0,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 2),
      indicator: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      indicatorAnimation: TabIndicatorAnimation.elastic,
      labelColor: colors.onPrimaryContainer,
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      tabs: [
        for (final type in _collectCategories)
          Tab(
            height: 48,
            child: Semantics(
              label: '${type?.label ?? '全部'}，${count(type)} 部',
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ValueListenableBuilder(
                    valueListenable: selected,
                    builder: (context, value, _) => Text(
                      type?.label ?? '全部',
                      textAlign: TextAlign.center,
                      style: value == type
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
