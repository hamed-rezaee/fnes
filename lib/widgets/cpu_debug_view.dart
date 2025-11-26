import 'package:flutter/material.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/controllers/cpu_debug_view_controller.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

class CpuDebugView extends StatefulWidget {
  const CpuDebugView({
    required this.bus,
    required this.nesEmulatorController,
    super.key,
  });

  final Bus bus;
  final NESEmulatorController nesEmulatorController;

  @override
  State<CpuDebugView> createState() => _CpuDebugViewState();
}

class _CpuDebugViewState extends State<CpuDebugView> {
  late final CpuDebugViewController controller;

  @override
  void initState() {
    super.initState();

    controller = CpuDebugViewController(
      bus: widget.bus,
      nesEmulatorController: widget.nesEmulatorController,
    );
  }

  @override
  Widget build(BuildContext context) => Watch((_) {
        final flags = controller.flags.value;
        final pc = controller.pc.value;
        final xRegister = controller.xRegister.value;
        final yRegister = controller.yRegister.value;
        final stackPointer = controller.stackPointer.value;
        final acRegister = controller.acRegister.value;
        final disassembly = controller.disassembly.value;

        return Column(
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
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: acRegister),
                  const TextSpan(
                    text: ' | X ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: xRegister),
                  const TextSpan(
                    text: ' | Y ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: yRegister),
                ],
              ),
            ),
            const SizedBox(height: 4),
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
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: flags),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (disassembly.isNotEmpty) ...[
              const Text(
                'Disassembler',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              RichText(
                text: _getDisassemblyRichText(disassembly),
              ),
            ],
          ],
        );
      });

  TextSpan _getDisassemblyRichText(String disassembly) {
    var lines = disassembly.split('\n');
    final pcIndex = lines.indexWhere((String line) => line.startsWith('-> '));

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
}
