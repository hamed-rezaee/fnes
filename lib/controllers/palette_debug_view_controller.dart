import 'package:signals/signals_flutter.dart';

class PaletteDebugViewController {
  final Signal<int> selectedPalette = signal(0);
  final Signal<int> selectedPatternTable = signal(0);

  void changePalette(int palette) => selectedPalette.value = palette;

  void changePatternTable(int patternTable) =>
      selectedPatternTable.value = patternTable;
}
