import 'package:flutter/material.dart';

class CustomSegmentedButton<T> extends StatelessWidget {
  const CustomSegmentedButton({
    required this.items,
    required this.selectedItems,
    required this.showSelectedIcon,
    required this.multiSelectionEnabled,
    required this.isEmptySelectionAllowed,
    required this.toLabel,
    required this.onSelectedPatternTableChanged,
    super.key,
  });

  final List<T> items;
  final Set<T> selectedItems;
  final bool showSelectedIcon;
  final bool multiSelectionEnabled;
  final bool isEmptySelectionAllowed;
  final String Function(T item) toLabel;
  final void Function(Set<T>) onSelectedPatternTableChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
        showSelectedIcon: showSelectedIcon,
        multiSelectionEnabled: multiSelectionEnabled,
        emptySelectionAllowed: isEmptySelectionAllowed,
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(),
          ),
          textStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 8,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontFamily: 'MonospaceFont',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.grey.shade300;
            }

            return null;
          }),
        ),
        segments: [
          for (final item in items)
            ButtonSegment(value: item, label: Text(toLabel(item))),
        ],
        selected: selectedItems,
        onSelectionChanged: onSelectedPatternTableChanged,
      );
}
