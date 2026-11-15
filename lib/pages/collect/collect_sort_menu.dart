import 'package:flutter/material.dart';
import 'package:kazumi/bean/widget/kazumi_menu.dart';
import 'package:kazumi/pages/collect/collect_library_query.dart';

/// The app bar's sort menu. The collection is cards only, so it carries no
/// layout entry.
class CollectSortMenuButton extends StatelessWidget {
  const CollectSortMenuButton({
    super.key,
    required this.sort,
    required this.onSortChanged,
  });

  final CollectSort sort;
  final ValueChanged<CollectSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return KazumiMenuButton(
      menuChildren: [
        for (final value in CollectSort.values)
          KazumiMenuItem(
            selected: value == sort,
            onPressed: () => onSortChanged(value),
            label: value.label,
          ),
      ],
      builder: (context, toggle) => IconButton(
        tooltip: '排序：${sort.label}',
        onPressed: toggle,
        icon: const Icon(Icons.tune_rounded),
      ),
    );
  }
}
