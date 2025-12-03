import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

enum PatternTable {
  patternTable0('Background'),
  patternTable1('Sprite');

  const PatternTable(this.label);

  final String label;
}

class PaletteDebugViewController {
  PaletteDebugViewController({
    required this.nesEmulatorController,
  }) {
    effect(() => nesEmulatorController.frameUpdateTrigger.value);
  }

  final NESEmulatorController nesEmulatorController;

  final Signal<int> selectedPalette = signal(0);
  final Signal<PatternTable> selectedPatternTable =
      signal(PatternTable.patternTable0);

  void changePalette(int palette) => selectedPalette.value = palette;

  void changePatternTable(PatternTable patternTable) =>
      selectedPatternTable.value = patternTable;
}
