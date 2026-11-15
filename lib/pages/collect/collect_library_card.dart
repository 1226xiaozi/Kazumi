part of 'collect_library_view.dart';

class _CollectPosterCard extends StatelessWidget {
  const _CollectPosterCard({
    super.key,
    required this.entry,
    required this.showStatus,
    required this.onOpen,
    required this.onChangeType,
  });

  final CollectedBangumi entry;
  final bool showStatus;
  final VoidCallback onOpen;
  final ValueChanged<CollectType>? onChangeType;

  static const _coverRatio = 0.62;
  // Padding above and below the title under the cover.
  static const _footerPadding = 8.0;
  static const _footerInset = 10.0;
  static const _titleSize = 15.0;
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
      final menu = _CollectEntryMenu(
        entry: entry,
        onChanged: onChangeType,
        overlay: true,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ExcludeSemantics(child: _CollectCover(item: item)),
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: menu,
                      ),
                    ],
                  ),
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

class _CollectListTile extends StatelessWidget {
  const _CollectListTile({
    super.key,
    required this.entry,
    required this.onOpen,
    required this.onChangeType,
  });

  final CollectedBangumi entry;
  final VoidCallback onOpen;
  final ValueChanged<CollectType>? onChangeType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final item = entry.bangumiItem;
    final title = CollectLibraryQuery.titleOf(entry);
    final airDate = DateTime.tryParse(item.airDate);
    final metadata = [
      if (airDate != null) '${airDate.year} 年',
    ];

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Isolate menu focus and taps from card navigation.
          Positioned.fill(
            child: Semantics(
              button: true,
              label: [title, ...metadata].join('，'),
              child: InkWell(onTap: onOpen),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 80,
                      height: 120,
                      child: _CollectCover(
                        item: item,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 76),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (metadata.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        metadata.join('  ·  '),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _CollectEntryMenu(
                        entry: entry,
                        onChanged: onChangeType,
                        showStatusLabel: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectCover extends StatelessWidget {
  const _CollectCover({
    required this.item,
    this.borderRadius,
  });
  final BangumiItem item;
  final BorderRadius? borderRadius;

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
            borderRadius: borderRadius,
          ),
        ),
      );
}

class _CollectEntryMenu extends StatelessWidget {
  const _CollectEntryMenu({
    required this.entry,
    required this.onChanged,
    this.showStatusLabel = false,
    this.overlay = false,
  });
  final CollectedBangumi entry;
  final ValueChanged<CollectType>? onChanged;
  final bool showStatusLabel;

  /// Draws the button as a translucent circle floating over the cover.
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final type = CollectType.fromValue(entry.type);
    final title = CollectLibraryQuery.titleOf(entry);
    return KazumiMenuButton(
      enabled: onChanged != null,
      style: MenuStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(showStatusLabel ? 16 : 20),
        )),
      ),
      menuChildren: [
        for (final status
            in CollectType.values.where((type) => type.isCollected))
          KazumiMenuItem(
            selected: status == type,
            onPressed: onChanged == null || status == type
                ? null
                : () => onChanged!(status),
            label: status.label,
          ),
        const Divider(indent: 16, endIndent: 16),
        KazumiMenuItem(
          onPressed:
              onChanged == null ? null : () => onChanged!(CollectType.none),
          label: '取消收藏',
          destructive: true,
        ),
      ],
      builder: (context, toggle) {
        if (overlay) {
          return IconButton(
            tooltip: '管理《$title》 · ${type.label}',
            onPressed: toggle,
            style: IconButton.styleFrom(
              foregroundColor: colors.onSurface,
              disabledForegroundColor: colors.onSurface.withValues(alpha: 0.6),
              backgroundColor: colors.surface.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
          );
        }
        return showStatusLabel
            ? Tooltip(
                message: '调整《$title》的观看状态',
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.padded,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
                  ),
                  onPressed: toggle,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(type.label),
                ),
              )
            : IconButton(
                tooltip: '管理《$title》 · ${type.label}',
                onPressed: toggle,
                style: IconButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  minimumSize: const Size(48, 48),
                  visualDensity: VisualDensity.standard,
                ),
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
              );
      },
    );
  }
}
