import 'package:equatable/equatable.dart';

abstract class PaletteDebugViewState extends Equatable {
  const PaletteDebugViewState({
    this.selectedPalette = 0,
    this.selectedPatternTable = 0,
  });

  final int selectedPalette;
  final int selectedPatternTable;

  @override
  List<Object?> get props => [selectedPalette, selectedPatternTable];
}

class CharacterTileViewerChanged extends PaletteDebugViewState {
  const CharacterTileViewerChanged({
    super.selectedPalette,
    super.selectedPatternTable,
  });
}
