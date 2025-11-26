import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

class PaletteDebugViewController {
  PaletteDebugViewController({
    required this.nesEmulatorController,
  }) {
    effect(() => nesEmulatorController.frameUpdateTrigger.value);
  }

  final NESEmulatorController nesEmulatorController;

  final Signal<int> selectedPalette = signal(0);
  final Signal<int> selectedPatternTable = signal(0);

  void changePalette(int palette) => selectedPalette.value = palette;

  void changePatternTable(int patternTable) =>
      selectedPatternTable.value = patternTable;
}
