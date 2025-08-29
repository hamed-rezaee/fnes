import 'package:fnes/mappers/mapper.dart';

class Mapper007 extends Mapper {
  Mapper007(super.programBankCount, super.totalCharBanks) {
    reset();
  }

  int _programBankSelect = 0;

  bool _singleScreenHigh = false;

  @override
  String get name => 'AxROM';

  @override
  void reset() {
    _programBankSelect = 0;
    _singleScreenHigh = false;
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      return (_programBankSelect * 0x8000) + (address & 0x7FFF);
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data) {
    if (address >= 0x8000 && address <= 0xFFFF) {
      _programBankSelect = data & 0x07;

      _singleScreenHigh = (data & 0x10) != 0;
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
    if (address >= 0x0000 && address <= 0x1FFF) return address;

    return null;
  }

  @override
  MapperMirror mirror() => _singleScreenHigh
      ? MapperMirror.oneScreenHigh
      : MapperMirror.oneScreenLow;
}
