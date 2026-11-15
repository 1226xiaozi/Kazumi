part of 'search_page.dart';

const _searchSortLabels = {
  'heat': '热度',
  'rank': '排名',
  'score': '评分',
  'match': '匹配',
};

String _sortLabel(String sort) => _searchSortLabels[sort] ?? '热度';

String _filterSummary(SearchFilterState state) => [
      ...state.tags,
      if (state.season.isNotEmpty) state.season,
      if (state.season.isEmpty && state.dateRange != null)
        '${state.dateRange!.start} 至 ${state.dateRange!.end}',
      if (state.scoreRange?.isValid == true)
        '评分 ${state.scoreRange!.toToken()}',
      if (state.rankRange?.isValid == true) '排名 ${state.rankRange!.toToken()}',
      if (state.weekdays.isNotEmpty)
        '周${state.weekdays.map((day) => '一二三四五六日'[day - 1]).join('、')}',
    ].join(' · ');

String _readableQuery(String query) {
  final state = SearchParser(query).toFilterState();
  final summary = _filterSummary(state);
  return [
    if (state.keyword.isNotEmpty) state.keyword,
    if (state.id.isNotEmpty) '条目 ${state.id}',
    if (summary.isNotEmpty) summary,
    if (state.sort != 'heat') '${_sortLabel(state.sort)}排序',
  ].join(' · ');
}

class _SearchSortMenu extends StatelessWidget {
  const _SearchSortMenu({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KazumiMenuButton(
      animated: true,
      menuChildren: [
        for (final sort in _searchSortLabels.entries)
          KazumiMenuItem(
            label: '按${sort.value}排序',
            selected: sort.key == value,
            onPressed: () => onChanged(sort.key),
          ),
      ],
      builder: (context, toggle) => Tooltip(
        message: '排序方式',
        child: TextButton.icon(
          onPressed: toggle,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          label: Text(_sortLabel(value)),
        ),
      ),
    );
  }
}

class _SearchResultGrid extends StatelessWidget {
  const _SearchResultGrid({
    required this.items,
    required this.width,
  });

  final List<BangumiItem> items;
  final double width;

  static const _columns = 3;
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (width - _spacing * (_columns - 1)) / _columns;
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        crossAxisSpacing: _spacing,
        mainAxisSpacing: _spacing,
        mainAxisExtent: cardWidth / _SearchResultCard.coverAspectRatio +
            _SearchResultCard.footerHeight,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => _SearchResultCard(item: items[index]),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.item});

  static const coverAspectRatio = 0.62;
  static const titleSize = 13.0;
  static const titleHeight = 36.0;
  static const footerHeight = 16.0 + titleHeight;

  final BangumiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.nameCn.isNotEmpty ? item.nameCn : item.name;
    return Material(
      type: MaterialType.transparency,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
          onTap: () => context.pushNamed('/info/', arguments: item),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: coverAspectRatio,
                  child: LayoutBuilder(
                      builder: (_, constraints) => NetworkImgLayer(
                            src: item.images['large'] ??
                                item.images['common'] ??
                                '',
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          )),
                )),
            SizedBox(
                height: footerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: titleSize,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
          ])),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(children: [
          const LoadingIndicator(size: 40),
          const SizedBox(height: 20),
          Semantics(
              liveRegion: true,
              child: Text('正在搜索番剧',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium)),
        ]));
  }
}
