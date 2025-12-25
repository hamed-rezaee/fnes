import 'package:fnes/components/cheat_code.dart';

class CheatEngine {
  CheatEngine();

  final List<CheatCode> _cheats = [];

  List<CheatCode> get cheats => List.unmodifiable(_cheats);

  List<CheatCode> get enabledCheats =>
      _cheats.where((cheat) => cheat.enabled).toList();

  void addCheat(CheatCode cheat) => _cheats.add(cheat);

  bool removeCheat(String id) {
    final index = _cheats.indexWhere((cheat) => cheat.id == id);

    if (index != -1) {
      _cheats.removeAt(index);

      return true;
    }

    return false;
  }

  bool updateCheat(CheatCode updatedCheat) {
    final index = _cheats.indexWhere((cheat) => cheat.id == updatedCheat.id);
    if (index != -1) {
      _cheats[index] = updatedCheat;

      return true;
    }

    return false;
  }

  bool toggleCheat({required String id, required bool enabled}) {
    final index = _cheats.indexWhere((cheat) => cheat.id == id);

    if (index != -1) {
      _cheats[index].enabled = enabled;

      return true;
    }

    return false;
  }

  void clearCheats() => _cheats.clear();

  int applyCheatToWrite(int address, int data) => data;

  int applyCheatToRead(int address, int data) {
    for (final cheat in _cheats) {
      if (!cheat.enabled) continue;

      if (cheat.address != address) continue;

      if (cheat.compareValue != null && cheat.compareValue != data) {
        continue;
      }

      return cheat.value;
    }

    return data;
  }

  List<CheatCode> getCheatsForAddress(int address) => _cheats
      .where((cheat) => cheat.address == address && cheat.enabled)
      .toList();

  bool hasCheatForAddress(int address) =>
      _cheats.any((cheat) => cheat.address == address && cheat.enabled);

  int get enabledCheatCount => _cheats.where((cheat) => cheat.enabled).length;

  int get totalCheatCount => _cheats.length;
}
