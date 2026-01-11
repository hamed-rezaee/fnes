import 'dart:typed_data';

import 'package:fnes/mappers/mapper.dart';

class Mapper010 extends Mapper {
  Mapper010(super.programBankCount, super.totalCharBanks) {
    chrRam = totalCharBanks == 0;
  }

  final Uint8List _prgRam = Uint8List(8192);

  @override
  String get name => 'MMC4';

  int _prgBank = 0;

  int _chrBank0FD = 0;
  int _chrBank0FE = 0;
  int _chrBank1FD = 0;
  int _chrBank1FE = 0;

  bool _latch0 = false;
  bool _latch1 = false;

  int _mirroring = 0;

  @override
  void reset() {
    _prgBank = 0;
    _chrBank0FD = 0;
    _chrBank0FE = 0;
    _chrBank1FD = 0;
    _chrBank1FE = 0;
    _latch0 = false;
    _latch1 = false;
    _mirroring = 0;

    setPrgBank16k(0, _prgBank);
    setPrgBank16k(1, programBankCount - 1);

    _updateChrBanks();
  }

  void _updateChrBanks() {
    if (_latch0) {
      setChrBank4k(0, _chrBank0FE);
    } else {
      setChrBank4k(0, _chrBank0FD);
    }

    if (_latch1) {
      setChrBank4k(1, _chrBank1FE);
    } else {
      setChrBank4k(1, _chrBank1FD);
    }
  }

  @override
  MapperMirror mirror() =>
      _mirroring == 0 ? MapperMirror.vertical : MapperMirror.horizontal;

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address < 0x8000) {
      setData?.call(_prgRam[address - 0x6000]);

      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final bank = (address >> 14) & 0x01;
      final offset = address & 0x3FFF;

      return prgBank[bank * 2] * 0x2000 + offset;
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data, [int cycles = 0]) {
    if (address >= 0x6000 && address < 0x8000) {
      _prgRam[address - 0x6000] = data;
      return 0xFFFFFFFF;
    }

    if (address >= 0xA000 && address <= 0xFFFF) {
      final registerSelect = (address >> 12) & 0x07;

      switch (registerSelect) {
        case 0x02:
          _prgBank = data & 0x0F;
          setPrgBank16k(0, _prgBank);
        case 0x03:
          _chrBank0FD = data & 0x1F;
          _updateChrBanks();
        case 0x04:
          _chrBank0FE = data & 0x1F;
          _updateChrBanks();
        case 0x05:
          _chrBank1FD = data & 0x1F;
          _updateChrBanks();
        case 0x06:
          _chrBank1FE = data & 0x1F;
          _updateChrBanks();
        case 0x07:
          _mirroring = data & 0x01;
      }

      return 0xFFFFFFFF;
    }

    return null;
  }

  @override
  int? ppuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      if (address == 0x0FD8) {
        _latch0 = false;
        _updateChrBanks();
      } else if (address == 0x0FE8) {
        _latch0 = true;
        _updateChrBanks();
      } else if (address >= 0x1FD8 && address <= 0x1FDF) {
        _latch1 = false;
        _updateChrBanks();
      } else if (address >= 0x1FE8 && address <= 0x1FEF) {
        _latch1 = true;
        _updateChrBanks();
      }

      final bank = (address >> 10) & 0x07;
      final offset = address & 0x03FF;

      return chrBank[bank] * 0x0400 + offset;
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      if (totalCharBanks == 0 || chrRam) {
        final bank = (address >> 10) & 0x07;
        final offset = address & 0x03FF;

        return chrBank[bank] * 0x0400 + offset;
      }
    }

    return null;
  }

  @override
  Map<String, dynamic> saveState() => {
    'prgBank': _prgBank,
    'chrBank0FD': _chrBank0FD,
    'chrBank0FE': _chrBank0FE,
    'chrBank1FD': _chrBank1FD,
    'chrBank1FE': _chrBank1FE,
    'latch0': _latch0,
    'latch1': _latch1,
    'mirroring': _mirroring,
    'prgRam': _prgRam.toList(),
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _prgBank = (state['prgBank'] as int?) ?? 0;
    _chrBank0FD = (state['chrBank0FD'] as int?) ?? 0;
    _chrBank0FE = (state['chrBank0FE'] as int?) ?? 0;
    _chrBank1FD = (state['chrBank1FD'] as int?) ?? 0;
    _chrBank1FE = (state['chrBank1FE'] as int?) ?? 0;
    _latch0 = (state['latch0'] as bool?) ?? false;
    _latch1 = (state['latch1'] as bool?) ?? false;
    _mirroring = (state['mirroring'] as int?) ?? 0;

    if (state['prgRam'] != null) {
      final list = state['prgRam'] as List;
      for (var i = 0; i < list.length && i < _prgRam.length; i++) {
        _prgRam[i] = list[i] as int;
      }
    }

    setPrgBank16k(0, _prgBank);
    setPrgBank16k(1, programBankCount - 1);

    _updateChrBanks();
  }
}
