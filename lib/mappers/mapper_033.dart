import 'package:fnes/mappers/mapper.dart';

class Mapper033 extends Mapper {
  Mapper033(super.programBankCount, super.totalCharBanks) {
    chrRam = totalCharBanks == 0;

    reset();
  }

  int _prgBank0 = 0;
  int _prgBank1 = 0;
  int _chr2kBank0 = 0;
  int _chr2kBank1 = 0;
  int _chr1kBank0 = 0;
  int _chr1kBank1 = 0;
  int _chr1kBank2 = 0;
  int _chr1kBank3 = 0;
  int _mirroringMode = 0;

  @override
  String get name => 'Taito TC0190/TC0350';

  @override
  void reset() {
    _prgBank0 = 0;
    _prgBank1 = 1;
    _chr2kBank0 = 0;
    _chr2kBank1 = 0;
    _chr1kBank0 = 0;
    _chr1kBank1 = 0;
    _chr1kBank2 = 0;
    _chr1kBank3 = 0;
    _mirroringMode = 0;

    setPrgBank8k(0, 0);
    setPrgBank8k(1, 1);
    setPrgBank8k(2, programBankCount * 2 - 2);
    setPrgBank8k(3, programBankCount * 2 - 1);

    if (totalCharBanks > 0) {
      for (var i = 0; i < 8; i++) {
        setChrBank1k(i, i);
      }
    }
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x8000 && address <= 0x9FFF) {
      return prgBank[0] * 0x2000 + (address & 0x1FFF);
    }

    if (address >= 0xA000 && address <= 0xBFFF) {
      return prgBank[1] * 0x2000 + (address & 0x1FFF);
    }

    if (address >= 0xC000 && address <= 0xDFFF) {
      return prgBank[2] * 0x2000 + (address & 0x1FFF);
    }

    if (address >= 0xE000 && address <= 0xFFFF) {
      return prgBank[3] * 0x2000 + (address & 0x1FFF);
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data, [int cycles = 0]) {
    final reg = address & 0x0003;

    if (address >= 0x8000 && address <= 0x8FFF) {
      if (reg == 0) {
        _prgBank0 = data & 0x3F;
        setPrgBank8k(0, _prgBank0);

        if ((data & 0x40) != 0) {
          _mirroringMode = 0;
        } else {
          _mirroringMode = 1;
        }
      } else if (reg == 1) {
        _prgBank1 = data & 0x3F;
        setPrgBank8k(1, _prgBank1);
      } else if (reg == 2) {
        _chr2kBank0 = data;
        setChrBank2k(0, _chr2kBank0);
      } else if (reg == 3) {
        _chr2kBank1 = data;
        setChrBank2k(1, _chr2kBank1);
      }
    } else if (address >= 0xA000 && address <= 0xAFFF) {
      if (reg == 0) {
        _chr1kBank0 = data;
        setChrBank1k(4, _chr1kBank0);
      } else if (reg == 1) {
        _chr1kBank1 = data;
        setChrBank1k(5, _chr1kBank1);
      } else if (reg == 2) {
        _chr1kBank2 = data;
        setChrBank1k(6, _chr1kBank2);
      } else if (reg == 3) {
        _chr1kBank3 = data;
        setChrBank1k(7, _chr1kBank3);
      }
    }

    return null;
  }

  @override
  int? ppuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      final bank = (address & 0x1C00) >> 10;
      final offset = address & 0x03FF;

      return chrBank[bank] * 0x0400 + offset;
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      if (totalCharBanks == 0 || chrRam) {
        final bank = (address & 0x1C00) >> 10;
        final offset = address & 0x03FF;

        return chrBank[bank] * 0x0400 + offset;
      }
    }

    return null;
  }

  @override
  MapperMirror mirror() =>
      _mirroringMode == 0 ? MapperMirror.horizontal : MapperMirror.vertical;

  @override
  Map<String, dynamic> saveState() => {
    'prgBank0': _prgBank0,
    'prgBank1': _prgBank1,
    'chr2kBank0': _chr2kBank0,
    'chr2kBank1': _chr2kBank1,
    'chr1kBank0': _chr1kBank0,
    'chr1kBank1': _chr1kBank1,
    'chr1kBank2': _chr1kBank2,
    'chr1kBank3': _chr1kBank3,
    'mirroringMode': _mirroringMode,
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _prgBank0 = state['prgBank0'] as int;
    _prgBank1 = state['prgBank1'] as int;
    _chr2kBank0 = state['chr2kBank0'] as int;
    _chr2kBank1 = state['chr2kBank1'] as int;
    _chr1kBank0 = state['chr1kBank0'] as int;
    _chr1kBank1 = state['chr1kBank1'] as int;
    _chr1kBank2 = state['chr1kBank2'] as int;
    _chr1kBank3 = state['chr1kBank3'] as int;
    _mirroringMode = state['mirroringMode'] as int;

    setPrgBank8k(0, _prgBank0);
    setPrgBank8k(1, _prgBank1);
    setChrBank2k(0, _chr2kBank0);
    setChrBank2k(1, _chr2kBank1);
    setChrBank1k(4, _chr1kBank0);
    setChrBank1k(5, _chr1kBank1);
    setChrBank1k(6, _chr1kBank2);
    setChrBank1k(7, _chr1kBank3);
  }
}
