part of 'collect_library_view.dart';

class _CollectPosterCard extends StatelessWidget {
  const _CollectPosterCard({
    super.key,
    required this.entry,
    required this.showStatus,
    required this.onOpen,
  });

  final CollectedBangumi entry;
  final bool showStatus;
  final VoidCallback onOpen;

  static const _coverRatio = 0.62;
  // Padding above and below the title under the cover.
  static const _footerPadding = 8.0;
  static const _footerInset = 10.0;
  static const _titleSize = 13.0;
  static bool _isCompact(double width) => width < 160;
  static double _titleHeight(TextScaler scaler) =>
      (scaler.scale(_titleSize) * 2.7).ceilToDouble();

  static double extent(double width, TextScaler scaler) =>
      width / _coverRatio + _footerPadding * 2 + _titleHeight(scaler);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final item = entry.bangumiItem;
    final title = CollectLibraryQuery.titleOf(entry);
    final year = DateTime.tryParse(item.airDate)?.year;
    final type = CollectType.fromValue(entry.type);

    return LayoutBuilder(builder: (context, constraints) {
      final compact = _isCompact(constraints.maxWidth);
      final titleBlock = ExcludeSemantics(
        child: SizedBox(
          height: _titleHeight(scaler),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: _titleSize,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      final footer = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _footerInset,
          vertical: _footerPadding,
        ),
        child: titleBlock,
      );

      return Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: [
            title,
            if (showStatus) type.label,
            if (year != null) '$year 年',
          ].join('，'),
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: _coverRatio,
                  child: ExcludeSemantics(child: _CollectCover(item: item)),
                ),
                Expanded(child: footer),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CollectCover extends StatelessWidget {
  const _CollectCover({required this.item});
  final BangumiItem item;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Hero(
          tag: item.id,
          transitionOnUserGestures: true,
          flightShuttleBuilder: NetworkImgLayer.heroFlightShuttleBuilder,
          child: NetworkImgLayer(
            src: item.images['large'] ?? item.images['common'] ?? '',
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
        ),
      );
}

