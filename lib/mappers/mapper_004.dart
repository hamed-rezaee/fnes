import 'dart:typed_data';
import 'package:fnes/mappers/mapper.dart';

class Mapper004 extends Mapper {
  Mapper004(super.programBankCount, super.totalCharBanks) {
    programRam = Uint8List(8 * 1024);
    reset();
  }

  late Uint8List programRam;
  late List<int> bankRegisters;

  int _targetRegister = 0;
  bool _programBankMode = false;
  bool _charA12Inversion = false;
  MapperMirror _mirrorMode = MapperMirror.horizontal;

  bool _programRamEnabled = true;
  bool _programRamWriteProtect = false;

  bool _irqActive = false;
  bool _irqEnabled = false;
  bool _irqReloadPending = false;
  int _irqCounter = 0;
  int _irqLatch = 0;

  @override
  String get name => 'MMC3';

  @override
  void reset() {
    bankRegisters = List.filled(8, 0);

    _targetRegister = 0;
    _programBankMode = false;
    _charA12Inversion = false;
    _mirrorMode = MapperMirror.horizontal;
    _programRamEnabled = true;
    _programRamWriteProtect = false;

    _irqActive = false;
    _irqEnabled = false;
    _irqReloadPending = false;
    _irqCounter = 0;
    _irqLatch = 0;

    _syncBanking();
  }

  void _syncBanking() {
    _syncChrBanking();
    _syncPrgBanking();
  }

  void _syncChrBanking() {
    if (_charA12Inversion) {
      setChrBank1k(Mapper.chr0000, bankRegisters[2]);
      setChrBank1k(Mapper.chr0400, bankRegisters[3]);
      setChrBank1k(Mapper.chr0800, bankRegisters[4]);
      setChrBank1k(Mapper.chr0c00, bankRegisters[5]);
      setChrBank1k(Mapper.chr1000, bankRegisters[0] & 0xFE);
      setChrBank1k(Mapper.chr1400, (bankRegisters[0] & 0xFE) + 1);
      setChrBank1k(Mapper.chr1800, bankRegisters[1] & 0xFE);
      setChrBank1k(Mapper.chr1c00, (bankRegisters[1] & 0xFE) + 1);
    } else {
      setChrBank1k(Mapper.chr0000, bankRegisters[0] & 0xFE);
      setChrBank1k(Mapper.chr0400, (bankRegisters[0] & 0xFE) + 1);
      setChrBank1k(Mapper.chr0800, bankRegisters[1] & 0xFE);
      setChrBank1k(Mapper.chr0c00, (bankRegisters[1] & 0xFE) + 1);
      setChrBank1k(Mapper.chr1000, bankRegisters[2]);
      setChrBank1k(Mapper.chr1400, bankRegisters[3]);
      setChrBank1k(Mapper.chr1800, bankRegisters[4]);
      setChrBank1k(Mapper.chr1c00, bankRegisters[5]);
    }
  }

  void _syncPrgBanking() {
    if (_programBankMode) {
      setPrgBank8k(Mapper.prg8000, prgRomPageCount8k - 2);
      setPrgBank8k(Mapper.prgA000, bankRegisters[7] & 0x3F);
      setPrgBank8k(Mapper.prgC000, bankRegisters[6] & 0x3F);
      setPrgBank8k(Mapper.prgE000, prgRomPageCount8k - 1);
    } else {
      setPrgBank8k(Mapper.prg8000, bankRegisters[6] & 0x3F);
      setPrgBank8k(Mapper.prgA000, bankRegisters[7] & 0x3F);
      setPrgBank8k(Mapper.prgC000, prgRomPageCount8k - 2);
      setPrgBank8k(Mapper.prgE000, prgRomPageCount8k - 1);
    }
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_programRamEnabled) {
        setData?.call(programRam[address & 0x1FFF]);
      }
      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final bankIndex = (address >> 13) & 0x3;
      final bankOffset = address & 0x1FFF;

      return (prgBank[bankIndex] * 0x2000) + bankOffset;
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_programRamEnabled && !_programRamWriteProtect) {
        programRam[address & 0x1FFF] = data;
      }
      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0x9FFF) {
      if ((address & 0x0001) == 0) {
        _targetRegister = data & 0x07;
        _programBankMode = (data & 0x40) != 0;
        _charA12Inversion = (data & 0x80) != 0;
      } else {
        bankRegisters[_targetRegister] = data;
        _syncBanking();
      }
    } else if (address >= 0xA000 && address <= 0xBFFF) {
      if ((address & 0x0001) == 0) {
        _mirrorMode = (data & 0x01) != 0
            ? MapperMirror.horizontal
            : MapperMirror.vertical;
        setMirroring(data & 0x01);
      } else {
        _programRamEnabled = (data & 0x80) != 0;
        _programRamWriteProtect = (data & 0x40) != 0;
      }
    } else if (address >= 0xC000 && address <= 0xDFFF) {
      if ((address & 0x0001) == 0) {
        _irqLatch = data;
      } else {
        _irqCounter = 0;
        _irqReloadPending = true;
      }
    } else if (address >= 0xE000 && address <= 0xFFFF) {
      if ((address & 0x0001) == 0) {
        _irqEnabled = false;
        _irqActive = false;
      } else {
        _irqEnabled = true;
      }
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      final bankIndex = address >> 10;
      final bankOffset = address & 0x03FF;

      return (chrBank[bankIndex] * 0x0400) + bankOffset;
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (totalCharBanks == 0 && address <= 0x1FFF) {
      return address;
    }

    return null;
  }

  @override
  void scanline() {
    if (_irqCounter == 0 || _irqReloadPending) {
      _irqCounter = _irqLatch;
      _irqReloadPending = false;
    } else {
      _irqCounter--;
    }

    if (_irqCounter == 0 && _irqEnabled) {
      _irqActive = true;
    }
  }

  @override
  bool irqState() => _irqActive;

  @override
  void irqClear() => _irqActive = false;

  @override
  MapperMirror mirror() => _mirrorMode;

  @override
  Map<String, dynamic> saveState() => {
    'targetRegister': _targetRegister,
    'programBankMode': _programBankMode,
    'charA12Inversion': _charA12Inversion,
    'mirrorMode': _mirrorMode.index,
    'programRamEnabled': _programRamEnabled,
    'programRamWriteProtect': _programRamWriteProtect,
    'bankRegisters': bankRegisters.toList(),
    'irqActive': _irqActive,
    'irqEnabled': _irqEnabled,
    'irqReloadPending': _irqReloadPending,
    'irqCounter': _irqCounter,
    'irqLatch': _irqLatch,
    'programRam': programRam.toList(),
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _targetRegister = state['targetRegister'] as int;
    _programBankMode = state['programBankMode'] as bool;
    _charA12Inversion = state['charA12Inversion'] as bool;
    _mirrorMode = MapperMirror.values[state['mirrorMode'] as int];
    _programRamEnabled = state['programRamEnabled'] as bool;
    _programRamWriteProtect = state['programRamWriteProtect'] as bool;

    final bankRegs = (state['bankRegisters'] as List).cast<int>();

    for (var i = 0; i < bankRegs.length; i++) {
      bankRegisters[i] = bankRegs[i];
    }

    _irqActive = state['irqActive'] as bool;
    _irqEnabled = state['irqEnabled'] as bool;
    _irqReloadPending = state['irqReloadPending'] as bool;
    _irqCounter = state['irqCounter'] as int;
    _irqLatch = state['irqLatch'] as int;
    programRam.setAll(0, (state['programRam'] as List).cast<int>());

    _syncBanking();
  }
}
