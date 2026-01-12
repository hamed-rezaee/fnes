import 'package:flutter/material.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/controllers/memory_debug_view_controller.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

class MemoryDebugView extends StatefulWidget {
  const MemoryDebugView({
    required this.nesEmulatorController,
    required this.cpu,
    super.key,
  });

  final NESEmulatorController nesEmulatorController;
  final CPU cpu;

  @override
  State<MemoryDebugView> createState() => _MemoryDebugViewState();
}

class _MemoryDebugViewState extends State<MemoryDebugView> {
  late final MemoryDebugViewController controller;

  @override
  void initState() {
    super.initState();

    controller = MemoryDebugViewController();
  }

  @override
  Widget build(BuildContext context) => Watch((_) {
    final selectedRegion = controller.selectedRegion.value;

    widget.nesEmulatorController.frameUpdateTrigger.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        _buildDropdown<MemoryRegion>(
          context: context,
          label: 'Region',
          value: selectedRegion,
          items: MemoryRegion.values
              .map(
                (region) => DropdownMenuItem(
                  value: region,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      region.title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selectedRegion == region
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: 'MonospaceFont',
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.selectRegion(value);
          },
        ),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: RichText(
              text: _getMemoryWindowRichText(
                cpu: widget.cpu,
                region: selectedRegion,
              ),
            ),
          ),
        ),
      ],
    );
  });

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              isDense: true,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontFamily: 'MonospaceFont',
              ),
              dropdownColor: Colors.white,
              focusColor: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );

  TextSpan _getMemoryWindowRichText({
    required CPU cpu,
    required MemoryRegion region,
  }) {
    final spans = <TextSpan>[];
    final (int startAddress, int length) = switch (region) {
      MemoryRegion.stack => (0x0100, 0x0100),
      MemoryRegion.zeroPage => (0x0000, 0x0100),
      MemoryRegion.programRom => (0x8000, 0x0100),
    };

    final header =
        '${' ' * 8}${List.generate(16, (i) => i.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}\n';
    spans.add(
      TextSpan(
        text: header,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'MonospaceFont',
        ),
      ),
    );

    for (var row = 0; row < length ~/ 16; row++) {
      final rowAddress = startAddress + (row * 16);

      spans.add(
        TextSpan(
          text:
              "0x${rowAddress.toRadixString(16).padLeft(4, '0').toUpperCase()}  ",
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'MonospaceFont',
          ),
        ),
      );

      final rowData = StringBuffer();

      for (var columnIndex = 0; columnIndex < 16; columnIndex++) {
        final address = rowAddress + columnIndex;

        if (address >= startAddress + length) break;
        rowData.write(
          "${cpu.read(address).toRadixString(16).padLeft(2, '0').toUpperCase()} ",
        );
      }
      spans
        ..add(
          TextSpan(
            text: '$rowData',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontFamily: 'MonospaceFont',
            ),
          ),
        )
        ..add(
          const TextSpan(
            text: '\n',
            style: TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontFamily: 'MonospaceFont',
            ),
          ),
        );
    }

    return TextSpan(children: spans);
  }
}
