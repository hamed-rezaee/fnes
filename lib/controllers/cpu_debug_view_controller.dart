import 'package:fnes/components/bus.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

class CpuDebugViewController {
  CpuDebugViewController({
    required this.bus,
    required this.nesEmulatorController,
  }) {
    effect(() {
      nesEmulatorController.frameUpdateTrigger.value;

      _updateDebugger();
    });
  }

  final Bus bus;
  final NESEmulatorController nesEmulatorController;

  late final Signal<String> flags = signal('');
  late final Signal<String> pc = signal('');
  late final Signal<String> xRegister = signal('');
  late final Signal<String> yRegister = signal('');
  late final Signal<String> stackPointer = signal('');
  late final Signal<String> acRegister = signal('');
  late final Signal<String> disassembly = signal('');

  void _updateDebugger() {
    final cpu = bus.cpu;

    flags.value = _formatFlags(cpu.getFlags());
    pc.value =
        "0x${cpu.programCounter.toRadixString(16).padLeft(4, '0').toUpperCase()}";
    xRegister.value =
        "0x${cpu.xRegister.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    yRegister.value =
        "0x${cpu.yRegister.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    stackPointer.value =
        "0x${cpu.stackPointer.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    acRegister.value =
        "0x${cpu.accumulator.toRadixString(16).padLeft(2, '0').toUpperCase()}";

    final currentPC = cpu.programCounter;
    final baseAddress = (currentPC - 30) & 0xFFFF;
    final calculatedEndAddress = (currentPC + 30) & 0xFFFF;
    final disassembledMap = cpu.disassemble(baseAddress, calculatedEndAddress);

    final lines = <String>[
      ...disassembledMap.entries.map((entry) {
        final instruction = entry.value;

        if (entry.key == currentPC) return '-> $instruction';

        return '   $instruction';
      }),
    ];

    disassembly.value = lines.join('\n');
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
