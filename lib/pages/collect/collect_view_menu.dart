import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/pages/collect/collect_library_query.dart';

/// Folds sorting and the card/list layout into one app bar button so the top
/// row can also hold the search toggle and the sync action.
class CollectViewMenuButton extends StatelessWidget {
  const CollectViewMenuButton({
    super.key,
    required this.sort,
    required this.layout,
    required this.onSortChanged,
    required this.onLayoutChanged,
  });

  final CollectSort sort;
  final CollectLayout layout;
  final ValueChanged<CollectSort> onSortChanged;
  final ValueChanged<CollectLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget section(String label) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        );

    return KazumiMenuButton(
      menuChildren: [
        section('排序'),
        for (final value in CollectSort.values)
          KazumiMenuItem(
            selected: value == sort,
            onPressed: () => onSortChanged(value),
            label: value.label,
          ),
        const Divider(indent: 16, endIndent: 16),
        section('布局'),
        for (final value in CollectLayout.values)
          KazumiMenuItem(
            selected: value == layout,
            onPressed: () => onLayoutChanged(value),
            label: value.label,
          ),
      ],
      builder: (context, toggle) => IconButton(
        tooltip: '排序与布局',
        onPressed: toggle,
        icon: const Icon(Icons.tune_rounded),
      ),
    );
  }
}
