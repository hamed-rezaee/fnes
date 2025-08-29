import 'package:fnes/mappers/mapper.dart';

class Mapper002 extends Mapper {
  Mapper002(super.programBankCount, super.totalCharBanks) {
    reset();
  }

  int _selectedProgramBankLow = 0x00;
  int _selectedProgramBankHigh = 0x00;

  @override
  String get name => 'UxROM';

  @override
  void reset() {
    _selectedProgramBankLow = 0;

    _selectedProgramBankHigh = programBankCount - 1;
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x8000 && address <= 0xBFFF) {
      return _selectedProgramBankLow * 0x4000 + (address & 0x3FFF);
    }

    if (address >= 0xC000 && address <= 0xFFFF) {
      return _selectedProgramBankHigh * 0x4000 + (address & 0x3FFF);
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      _selectedProgramBankLow = data & 0x0F;
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      return address;
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      if (totalCharBanks == 0) return address;
    }

    return null;
  }
}
