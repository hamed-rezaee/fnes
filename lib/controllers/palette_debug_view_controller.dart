import 'package:fnes/main.dart';
import 'package:signals/signals_flutter.dart';

class PaletteDebugViewController {
  PaletteDebugViewController() {
    effect(() => nesController.frameUpdateTrigger.value);
  }

  final Signal<int> selectedPalette = signal(0);
  final Signal<int> selectedPatternTable = signal(0);

  void changePalette(int palette) => selectedPalette.value = palette;

  void changePatternTable(int patternTable) =>
      selectedPatternTable.value = patternTable;
}
