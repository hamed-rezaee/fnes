import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/cubits/palette_debug_view_state.dart';

class PaletteDebugViewCubit extends Cubit<PaletteDebugViewState> {
  PaletteDebugViewCubit() : super(const CharacterTileViewerChanged());

  int get selectedPalette => state.selectedPalette;
  int get selectedPatternTable => state.selectedPatternTable;

  void changePalette(int palette) => emit(
    CharacterTileViewerChanged(
      selectedPalette: palette,
      selectedPatternTable: selectedPatternTable,
    ),
  );

  void changePatternTable(int patternTable) => emit(
    CharacterTileViewerChanged(
      selectedPalette: selectedPalette,
      selectedPatternTable: patternTable,
    ),
  );
}
