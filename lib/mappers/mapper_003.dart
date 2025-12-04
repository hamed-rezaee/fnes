import 'package:fnes/mappers/mapper.dart';

class Mapper003 extends Mapper {
  Mapper003(super.programBankCount, super.totalCharBanks) {
    reset();
  }

  int _selectedCharBank = 0x00;

  @override
  String get name => 'CNROM';

  @override
  void reset() => _selectedCharBank = 0;

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      final mask = programBankCount > 1 ? 0x7FFF : 0x3FFF;

      return address & mask;
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      _selectedCharBank = data & 0x03;
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      return _selectedCharBank * 0x2000 + (address & 0x1FFF);
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) => null;

  @override
  Map<String, dynamic> saveState() => {
        'selectedCharBank': _selectedCharBank,
      };

  @override
  void restoreState(Map<String, dynamic> state) {
    _selectedCharBank = state['selectedCharBank'] as int;
  }
}
