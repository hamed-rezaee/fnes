import 'package:flutter/material.dart';
import 'package:fnes/components/bus.dart';

class CpuDebugView extends StatelessWidget {
  CpuDebugView({required this.bus, super.key}) {
    _updateDebugger();
  }

  final Bus bus;

  late final String flags;
  late final String pc;
  late final String xRegister;
  late final String yRegister;
  late final String stackPointer;
  late final String acRegister;
  late final String disassembly;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black,
                fontFamily: 'MonospaceFont',
              ),
              children: [
                const TextSpan(
                  text: 'PC ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: pc),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black,
                fontFamily: 'MonospaceFont',
              ),
              children: [
                const TextSpan(
                  text: 'SP ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: stackPointer),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black,
                fontFamily: 'MonospaceFont',
              ),
              children: [
                const TextSpan(
                  text: 'AC ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: acRegister),
                const TextSpan(
                  text: ' | X ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: xRegister),
                const TextSpan(
                  text: ' | Y ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: yRegister),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 9,
                color: Colors.black,
                fontFamily: 'MonospaceFont',
              ),
              children: [
                const TextSpan(
                  text: 'Flags ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: flags),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (disassembly.isNotEmpty) ...[
            const Text(
              'Disassembler',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            RichText(
              text: _getDisassemblyRichText(),
            ),
          ],
        ],
      );

  TextSpan _getDisassemblyRichText() {
    var lines = disassembly.split('\n');
    final pcIndex = lines.indexWhere((line) => line.startsWith('-> '));

    if (pcIndex == -1) return const TextSpan();

    final startIndex = (pcIndex - 10).clamp(0, lines.length);
    final endIndex = (pcIndex + 11).clamp(0, lines.length);
    lines = lines.sublist(startIndex, endIndex);

    final spans = <TextSpan>[];

    const cpuDebugTextStyle = TextStyle(
      fontSize: 9,
      color: Colors.black,
      fontFamily: 'MonospaceFont',
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('-> ')) {
        final content = line.substring(3);
        final parts = content.split(' ');

        if (parts.isNotEmpty) {
          spans
            ..add(const TextSpan(text: '➜ ', style: cpuDebugTextStyle))
            ..add(
              TextSpan(
                text: '${parts[0]} ',
                style: cpuDebugTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );

          if (parts.length > 1) {
            spans.add(
              TextSpan(
                text: parts.sublist(1).join(' '),
                style: cpuDebugTextStyle,
              ),
            );
          }
        }
      } else if (line.startsWith('  ')) {
        final content = line.substring(3);
        final parts = content.split(' ');

        if (parts.isNotEmpty) {
          spans
            ..add(const TextSpan(text: '   ', style: cpuDebugTextStyle))
            ..add(
              TextSpan(
                text: '${parts[0]} ',
                style: cpuDebugTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );

          if (parts.length > 1) {
            spans.add(
              TextSpan(
                text: parts.sublist(1).join(' '),
                style: cpuDebugTextStyle,
              ),
            );
          }
        }
      } else {
        spans.add(TextSpan(text: line, style: cpuDebugTextStyle));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n', style: cpuDebugTextStyle));
      }
    }

    return TextSpan(children: spans);
  }

  void _updateDebugger() {
    final cpu = bus.cpu;

    flags = _formatFlags(cpu.getFlags());
    pc =
        "0x${cpu.programCounter.toRadixString(16).padLeft(4, '0').toUpperCase()}";
    xRegister =
        "0x${cpu.xRegister.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    yRegister =
        "0x${cpu.yRegister.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    stackPointer =
        "0x${cpu.stackPointer.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    acRegister =
        "0x${cpu.accumulator.toRadixString(16).padLeft(2, '0').toUpperCase()}";

    final currentPC = cpu.programCounter;
    final baseAddress = (currentPC - 30) & 0xFFFF;
    final calculatedEndAddress = (currentPC + 30) & 0xFFFF;
    final disassembledMap = cpu.disassemble(baseAddress, calculatedEndAddress);

    disassembly = disassembledMap.entries.map((entry) {
      final instruction = entry.value;

      if (entry.key == currentPC) {
        return '-> $instruction';
      }

      return '   $instruction';
    }).join('\n');
  }

  String _formatFlags(String rawFlags) {
    final flagLabels = ['N', 'V', 'U', 'B', 'D', 'I', 'Z', 'C'];
    final buffer = StringBuffer();

    for (var i = 0; i < flagLabels.length; i++) {
      final color = rawFlags[i] == '1' ? '🟩' : '🟥';

      buffer.write('$color${flagLabels[i]} ');
    }

    return '$buffer'.trim();
  }
}
