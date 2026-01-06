import 'package:fnes/mappers/mapper.dart';

class Mapper066 extends Mapper {
  Mapper066(super.programBankCount, super.totalCharBanks) {
    reset();
  }

  int _charBankSelect = 0x00;
  int _programBankSelect = 0x00;

  @override
  String get name => 'GxROM';

  @override
  void reset() {
    _charBankSelect = 0;
    _programBankSelect = 0;

    setPrgBank32k(0);
    setChrBank8k(0);
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      return (_programBankSelect * 0x8000) + (address & 0x7FFF);
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data, [int cycles = 0]) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      _charBankSelect = data & 0x03;
      _programBankSelect = (data & 0x30) >> 4;

      setChrBank8k(_charBankSelect);
      setPrgBank32k(_programBankSelect);
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      return (_charBankSelect * 0x2000) + (address & 0x1FFF);
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) => null;

  @override
  MapperMirror mirror() => MapperMirror.hardware;

  @override
  Map<String, dynamic> saveState() => {
    'charBankSelect': _charBankSelect,
    'programBankSelect': _programBankSelect,
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _charBankSelect = state['charBankSelect'] as int;
    _programBankSelect = state['programBankSelect'] as int;
  }
}
