import 'dart:convert';

import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cheat_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals_flutter.dart';

class CheatController {
  CheatController({required this.bus});

  final Bus bus;

  final Signal<List<CheatCode>> cheats = signal<List<CheatCode>>([]);
  final Signal<int> enabledCheatCount = signal<int>(0);

  static const String _prefsKey = 'nes_cheats';

  Future<void> loadCheats(String? romName) async {
    if (romName?.isEmpty ?? true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefsKey}_$romName';
      final cheatsJson = prefs.getString(key);

      if (cheatsJson != null && cheatsJson.isNotEmpty) {
        final decoded = jsonDecode(cheatsJson) as List<dynamic>;
        final loadedCheats = decoded
            .map((json) => CheatCode.fromJson(json as Map<String, dynamic>))
            .toList();

        bus.cheatEngine.clearCheats();

        loadedCheats.forEach(bus.cheatEngine.addCheat);

        cheats.value = loadedCheats;
        _updateEnabledCount();
      }
    } on Exception catch (_) {
      cheats.value = [];
    }
  }

  Future<void> saveCheats(String? romName) async {
    if (romName?.isEmpty ?? true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_prefsKey}_$romName';

      final cheatsJson = jsonEncode(
        cheats.value.map((cheat) => cheat.toJson()).toList(),
      );

      await prefs.setString(key, cheatsJson);
    } on Exception catch (_) {}
  }

  Future<void> addCheat(CheatCode cheat, String? romName) async {
    bus.cheatEngine.addCheat(cheat);
    cheats.value = [...bus.cheatEngine.cheats];
    _updateEnabledCount();
    await saveCheats(romName);
  }

  Future<void> removeCheat(String id, String? romName) async {
    if (bus.cheatEngine.removeCheat(id)) {
      cheats.value = [...bus.cheatEngine.cheats];
      _updateEnabledCount();
      await saveCheats(romName);
    }
  }

  Future<void> toggleCheat({
    required String id,
    required bool enabled,
    String? romName,
  }) async {
    if (bus.cheatEngine.toggleCheat(id: id, enabled: enabled)) {
      cheats.value = [...bus.cheatEngine.cheats];
      _updateEnabledCount();
      await saveCheats(romName);
    }
  }

  Future<void> updateCheat(CheatCode cheat, String? romName) async {
    if (bus.cheatEngine.updateCheat(cheat)) {
      cheats.value = [...bus.cheatEngine.cheats];
      _updateEnabledCount();
      await saveCheats(romName);
    }
  }

  Future<void> clearAllCheats(String? romName) async {
    bus.cheatEngine.clearCheats();
    cheats.value = [];
    _updateEnabledCount();
    await saveCheats(romName);
  }

  Future<bool> addGameGenieCheat(
    String code,
    String? romName, {
    String? name,
  }) async {
    final cheat = CheatCode.fromGameGenieCode(code, name: name);

    if (cheat == null) return false;

    await addCheat(cheat, romName);

    return true;
  }

  void _updateEnabledCount() =>
      enabledCheatCount.value = bus.cheatEngine.enabledCheatCount;

  void dispose() {
    cheats.dispose();
    enabledCheatCount.dispose();
  }
}
