import 'package:fnes/mappers/mapper.dart';

class Mapper000 extends Mapper {
  Mapper000(super.programBankCount, super.totalCharBanks);

  @override
  String get name => 'NROM';

  @override
  void reset() {
    setPrgBank16k(0, 0);
    setPrgBank16k(1, programBankCount - 1);

    if (totalCharBanks > 0) setChrBank8k(0);
  }

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
      final mask = programBankCount > 1 ? 0x7FFF : 0x3FFF;

      return address & mask;
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) return address;

    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      if (totalCharBanks == 0 || chrRam) return address;
    }

    return null;
  }

  @override
  Map<String, dynamic> saveState() => {};

  @override
  void restoreState(Map<String, dynamic> state) {}
}
