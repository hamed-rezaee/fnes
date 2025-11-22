import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/cubits/memory_debug_view_cubit.dart';
import 'package:fnes/cubits/memory_debug_view_state.dart';

class MemoryDebugView extends StatelessWidget {
  const MemoryDebugView({required this.cpu, super.key});

  final CPU cpu;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => MemoryDebugViewCubit(),
        child: BlocBuilder<MemoryDebugViewCubit, MemoryDebugViewState>(
          builder: (context, state) {
            final cubit = context.read<MemoryDebugViewCubit>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown<MemoryRegion>(
                  context: context,
                  label: 'Region',
                  value: state.selectedRegion,
                  items: MemoryRegion.values
                      .map(
                        (region) => DropdownMenuItem(
                          value: region,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              region.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: cubit.selectedRegion == region
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
                    if (value != null) {
                      cubit.selectRegion(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: RichText(
                    text: _getMemoryWindowRichText(state.selectedRegion),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isDense: true,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontFamily: 'MonospaceFont',
                ),
                dropdownColor: Colors.white,
                focusColor: Colors.white,
              ),
            ),
          ),
        ],
      );

  TextSpan _getMemoryWindowRichText(MemoryRegion region) {
    final spans = <TextSpan>[];
    final int startAddress;
    final int length;

    switch (region) {
      case MemoryRegion.stack:
        startAddress = 0x0100;
        length = 0x0100;
      case MemoryRegion.zeroPage:
        startAddress = 0x0000;
        length = 0x0100;
      case MemoryRegion.programRom:
        startAddress = 0x8000;
        length = 0x0100;
    }

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
            text: rowData.toString(),
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
