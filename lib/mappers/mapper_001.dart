import 'dart:typed_data';

import 'package:fnes/mappers/mapper.dart';

class Mapper001 extends Mapper {
  Mapper001(super.programBankCount, super.totalCharBanks) {
    chrRam = totalCharBanks == 0;
  }

  final Uint8List _prgRam = Uint8List(8192);

  @override
  String get name => 'MMC1';

  int _shiftRegister = 0x10;
  int _writeCount = 0;
  int _control = 0x0C;
  int _chrBank0 = 0;
  int _chrBank1 = 0;
  int _prgBank = 0;
  int _lastWriteCycles = 0;

  @override
  void reset() {
    _shiftRegister = 0x10;
    _writeCount = 0;
    _control = 0x0C;
    _chrBank0 = 0;
    _chrBank1 = 0;
    _prgBank = 0;
  }

  @override
  MapperMirror mirror() => switch (_control & 0x03) {
    0 => MapperMirror.oneScreenLow,
    1 => MapperMirror.oneScreenHigh,
    2 => MapperMirror.vertical,
    _ => MapperMirror.horizontal,
  };

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address < 0x8000) {
      setData?.call(_prgRam[address - 0x6000]);
      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final prgMode = (_control >> 2) & 0x03;
      final bankSize16k = programBankCount;

      if (prgMode == 0 || prgMode == 1) {
        final bank = (_prgBank >> 1) % (bankSize16k ~/ 2);
        return bank * 0x8000 + (address & 0x7FFF);
      } else if (prgMode == 2) {
        if (address < 0xC000) {
          return address & 0x3FFF;
        } else {
          final bank = _prgBank % bankSize16k;
          return bank * 0x4000 + (address & 0x3FFF);
        }
      } else {
        if (address < 0xC000) {
          final bank = _prgBank % bankSize16k;
          return bank * 0x4000 + (address & 0x3FFF);
        } else {
          final lastBank = bankSize16k - 1;
          return lastBank * 0x4000 + (address & 0x3FFF);
        }
      }
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data, [int cycles = 0]) {
    if (address >= 0x6000 && address < 0x8000) {
      _prgRam[address - 0x6000] = data;
      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final consecutive = cycles > 0 && cycles - _lastWriteCycles < 6;
      _lastWriteCycles = cycles;

      if (consecutive) return null;

      if ((data & 0x80) != 0) {
        _shiftRegister = 0x10;
        _writeCount = 0;
        _control |= 0x0C;
      } else {
        _shiftRegister >>= 1;
        _shiftRegister |= (data & 0x01) << 4;
        _writeCount++;

        if (_writeCount == 5) {
          final value = _shiftRegister;
          _shiftRegister = 0x10;
          _writeCount = 0;

          if (address < 0xA000) {
            _control = value & 0x1F;
          } else if (address < 0xC000) {
            _chrBank0 = value & 0x1F;
          } else if (address < 0xE000) {
            _chrBank1 = value & 0x1F;
          } else {
            _prgBank = value & 0x1F;
          }
        }
      }

      return null;
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      // CHR RAM: just return address directly
      if (totalCharBanks == 0) {
        return address;
      }

      final chrMode = (_control >> 4) & 0x01;

      if (chrMode == 0) {
        // 8k mode: ignore bit 0 of bank number
        final bank = (_chrBank0 >> 1) % totalCharBanks;
        return bank * 0x2000 + (address & 0x1FFF);
      } else {
        // 4k mode: two separate banks
        if (address < 0x1000) {
          final bank = _chrBank0 % (totalCharBanks * 2);
          return bank * 0x1000 + (address & 0x0FFF);
        } else {
          final bank = _chrBank1 % (totalCharBanks * 2);
          return bank * 0x1000 + (address & 0x0FFF);
        }
      }
    }
    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (address >= 0x0000 && address <= 0x1FFF && chrRam) return address;

    return null;
  }

  @override
  Map<String, dynamic> saveState() => {
    'shiftRegister': _shiftRegister,
    'writeCount': _writeCount,
    'control': _control,
    'chrBank0': _chrBank0,
    'chrBank1': _chrBank1,
    'prgBank': _prgBank,
    'prgRam': _prgRam.toList(),
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _shiftRegister = (state['shiftRegister'] as int?) ?? 0x10;
    _writeCount = (state['writeCount'] as int?) ?? 0;
    _control = (state['control'] as int?) ?? 0x0C;
    _chrBank0 = (state['chrBank0'] as int?) ?? 0;
    _chrBank1 = (state['chrBank1'] as int?) ?? 0;
    _prgBank = (state['prgBank'] as int?) ?? 0;

    if (state.containsKey('prgRam')) {
      final ram = (state['prgRam'] as List).cast<int>();

      _prgRam.setAll(0, ram);
    }
  }
}
