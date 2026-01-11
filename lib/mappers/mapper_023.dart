import 'dart:typed_data';

import 'package:fnes/mappers/mapper.dart';

class Mapper023 extends Mapper {
  Mapper023(super.programBankCount, super.totalCharBanks) {
    chrRam = totalCharBanks == 0;
  }

  final Uint8List _prgRam = Uint8List(8192);

  @override
  String get name => 'VRC2b/VRC4e';

  final List<int> _chrBanks = List<int>.filled(8, 0);

  int _prgBank8000 = 0;
  int _prgBankA000 = 0;

  int _mirroring = 0;

  bool _irqEnabled = false;
  bool _irqEnableAfterAck = false;
  bool _irqCycleMode = false;
  int _irqCounter = 0;
  int _irqLatch = 0;
  int _irqPrescaler = 0;
  int _irqPrescalerCounter = 0;

  @override
  void reset() {
    _prgBank8000 = 0;
    _prgBankA000 = 0;

    for (var i = 0; i < 8; i++) {
      _chrBanks[i] = 0;
    }

    _mirroring = 0;
    _irqEnabled = false;
    _irqEnableAfterAck = false;
    _irqCycleMode = false;
    _irqCounter = 0;
    _irqLatch = 0;
    _irqPrescaler = 0;
    _irqPrescalerCounter = 0;

    _updateBanks();
  }

  void _updateBanks() {
    setPrgBank8k(0, _prgBank8000);
    setPrgBank8k(1, _prgBankA000);
    setPrgBank8k(2, programBankCount * 2 - 2);
    setPrgBank8k(3, programBankCount * 2 - 1);

    for (var i = 0; i < 8; i++) {
      setChrBank1k(i, _chrBanks[i]);
    }
  }

  @override
  MapperMirror mirror() => switch (_mirroring & 0x03) {
    0 => MapperMirror.vertical,
    1 => MapperMirror.horizontal,
    2 => MapperMirror.oneScreenLow,
    _ => MapperMirror.oneScreenHigh,
  };

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address < 0x8000) {
      setData?.call(_prgRam[address - 0x6000]);

      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final bank = (address >> 13) & 0x03;
      final offset = address & 0x1FFF;

      return prgBank[bank] * 0x2000 + offset;
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
      final reg = _decodeRegister(address);

      switch (reg) {
        case 0x8000:
        case 0x8001:
        case 0x8002:
        case 0x8003:
          _prgBank8000 = data & 0x1F;
          _updateBanks();
        case 0x9000:
        case 0x9001:
          _mirroring = data & 0x03;
        case 0x9002:
        case 0x9003:
          break;
        case 0xA000:
        case 0xA001:
        case 0xA002:
        case 0xA003:
          _prgBankA000 = data & 0x1F;
          _updateBanks();
        case 0xB000:
          _chrBanks[0] = (_chrBanks[0] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xB001:
        case 0xB004:
          _chrBanks[0] = (_chrBanks[0] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xB002:
        case 0xB008:
          _chrBanks[1] = (_chrBanks[1] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xB003:
        case 0xB00C:
          _chrBanks[1] = (_chrBanks[1] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xC000:
          _chrBanks[2] = (_chrBanks[2] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xC001:
        case 0xC004:
          _chrBanks[2] = (_chrBanks[2] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xC002:
        case 0xC008:
          _chrBanks[3] = (_chrBanks[3] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xC003:
        case 0xC00C:
          _chrBanks[3] = (_chrBanks[3] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xD000:
          _chrBanks[4] = (_chrBanks[4] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xD001:
        case 0xD004:
          _chrBanks[4] = (_chrBanks[4] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xD002:
        case 0xD008:
          _chrBanks[5] = (_chrBanks[5] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xD003:
        case 0xD00C:
          _chrBanks[5] = (_chrBanks[5] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xE000:
          _chrBanks[6] = (_chrBanks[6] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xE001:
        case 0xE004:
          _chrBanks[6] = (_chrBanks[6] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xE002:
        case 0xE008:
          _chrBanks[7] = (_chrBanks[7] & 0xF0) | (data & 0x0F);
          _updateBanks();
        case 0xE003:
        case 0xE00C:
          _chrBanks[7] = (_chrBanks[7] & 0x0F) | ((data & 0x0F) << 4);
          _updateBanks();
        case 0xF000:
          _irqLatch = (_irqLatch & 0xF0) | (data & 0x0F);
        case 0xF001:
        case 0xF004:
          _irqLatch = (_irqLatch & 0x0F) | ((data & 0x0F) << 4);
        case 0xF002:
        case 0xF008:
          _irqEnableAfterAck = (data & 0x01) != 0;
          _irqEnabled = (data & 0x02) != 0;
          _irqCycleMode = (data & 0x04) != 0;

          if (_irqEnabled) {
            _irqCounter = _irqLatch;
            _irqPrescaler = 0;
            _irqPrescalerCounter = 0;
          }
        case 0xF003:
        case 0xF00C:
          _irqEnabled = _irqEnableAfterAck;
      }

      return 0xFFFFFFFF;
    }

    return null;
  }

  int _decodeRegister(int address) {
    final baseReg = address & 0xF000;
    final subReg = address & 0x000F;

    return baseReg | subReg;
  }

  @override
  int? ppuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x0000 && address <= 0x1FFF) {
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
  void clock(int cycles) {
    if (!_irqEnabled) return;

    if (_irqCycleMode) {
      _irqCounter += cycles;

      if (_irqCounter >= 0x100) {
        _irqCounter = _irqLatch;
        irqClear();
      }
    } else {
      _irqPrescalerCounter += cycles;

      while (_irqPrescalerCounter >= 114) {
        _irqPrescalerCounter -= 114;
        _irqPrescaler++;

        if (_irqPrescaler >= 3) {
          _irqPrescaler = 0;

          if (_irqCounter == 0xFF) {
            _irqCounter = _irqLatch;
            irqClear();
          } else {
            _irqCounter++;
          }
        }
      }
    }
  }

  @override
  bool irqState() => !_irqEnabled;

  @override
  void irqClear() {}

  @override
  Map<String, dynamic> saveState() => {
    'prgBank8000': _prgBank8000,
    'prgBankA000': _prgBankA000,
    'chrBanks': _chrBanks.toList(),
    'mirroring': _mirroring,
    'irqEnabled': _irqEnabled,
    'irqEnableAfterAck': _irqEnableAfterAck,
    'irqCycleMode': _irqCycleMode,
    'irqCounter': _irqCounter,
    'irqLatch': _irqLatch,
    'irqPrescaler': _irqPrescaler,
    'irqPrescalerCounter': _irqPrescalerCounter,
    'prgRam': _prgRam.toList(),
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _prgBank8000 = (state['prgBank8000'] as int?) ?? 0;
    _prgBankA000 = (state['prgBankA000'] as int?) ?? 0;
    _mirroring = (state['mirroring'] as int?) ?? 0;
    _irqEnabled = (state['irqEnabled'] as bool?) ?? false;
    _irqEnableAfterAck = (state['irqEnableAfterAck'] as bool?) ?? false;
    _irqCycleMode = (state['irqCycleMode'] as bool?) ?? false;
    _irqCounter = (state['irqCounter'] as int?) ?? 0;
    _irqLatch = (state['irqLatch'] as int?) ?? 0;
    _irqPrescaler = (state['irqPrescaler'] as int?) ?? 0;
    _irqPrescalerCounter = (state['irqPrescalerCounter'] as int?) ?? 0;

    if (state['chrBanks'] != null) {
      final list = state['chrBanks'] as List;
      for (var i = 0; i < list.length && i < _chrBanks.length; i++) {
        _chrBanks[i] = list[i] as int;
      }
    }

    if (state['prgRam'] != null) {
      final list = state['prgRam'] as List;
      for (var i = 0; i < list.length && i < _prgRam.length; i++) {
        _prgRam[i] = list[i] as int;
      }
    }

    _updateBanks();
  }
}
