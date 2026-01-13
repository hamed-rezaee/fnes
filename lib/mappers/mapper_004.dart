import 'dart:typed_data';
import 'package:fnes/mappers/mapper.dart';

class Mapper004 extends Mapper {
  Mapper004(super.programBankCount, super.totalCharBanks) {
    programRam = Uint8List(8 * 1024);

    reset();
  }

  late Uint8List programRam;
  late List<int> bankRegisters;

  MapperMirror _mirrorMode = MapperMirror.horizontal;

  int _targetRegister = 0;
  bool _prgBankMode = false;
  bool _chrBankMode = false;
  bool _fourScreenMode = false;
  bool _prgRamChipEnable = true;
  bool _prgRamWriteProtect = false;

  int _irqLatch = 0;
  int _irqCounter = 0;
  bool _irqReload = false;
  bool _irqEnable = false;
  bool _irqActive = false;

  @override
  String get name => 'MMC3';

  @override
  void reset() {
    bankRegisters = List.filled(8, 0);

    _targetRegister = 0;
    _prgBankMode = false;
    _chrBankMode = false;
    _mirrorMode = MapperMirror.horizontal;
    _prgRamChipEnable = true;
    _prgRamWriteProtect = false;

    _irqLatch = 0;
    _irqCounter = 0;
    _irqReload = false;
    _irqEnable = false;
    _irqActive = false;

    _syncBanking();
  }

  void _syncBanking() {
    _syncChrBanking();
    _syncPrgBanking();
  }

  void _syncChrBanking() {
    if (_chrBankMode) {
      setChrBank1k(Mapper.chr0000, bankRegisters[2]);
      setChrBank1k(Mapper.chr0400, bankRegisters[3]);
      setChrBank1k(Mapper.chr0800, bankRegisters[4]);
      setChrBank1k(Mapper.chr0c00, bankRegisters[5]);

      setChrBank2k(2, bankRegisters[0] >> 1);
      setChrBank2k(3, bankRegisters[1] >> 1);
    } else {
      setChrBank1k(Mapper.chr1000, bankRegisters[2]);
      setChrBank1k(Mapper.chr1400, bankRegisters[3]);
      setChrBank1k(Mapper.chr1800, bankRegisters[4]);
      setChrBank1k(Mapper.chr1c00, bankRegisters[5]);

      setChrBank2k(0, bankRegisters[0] >> 1);
      setChrBank2k(1, bankRegisters[1] >> 1);
    }
  }

  void _syncPrgBanking() {
    final lastBank = prgRomPageCount8k - 1;
    final secondLastBank = prgRomPageCount8k - 2;

    if (_prgBankMode) {
      setPrgBank8k(Mapper.prgC000, bankRegisters[6] & 0x3F);
      setPrgBank8k(Mapper.prgA000, bankRegisters[7] & 0x3F);
      setPrgBank8k(Mapper.prg8000, secondLastBank);
      setPrgBank8k(Mapper.prgE000, lastBank);
    } else {
      setPrgBank8k(Mapper.prg8000, bankRegisters[6] & 0x3F);
      setPrgBank8k(Mapper.prgA000, bankRegisters[7] & 0x3F);
      setPrgBank8k(Mapper.prgC000, secondLastBank);
      setPrgBank8k(Mapper.prgE000, lastBank);
    }
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_prgRamChipEnable) setData?.call(programRam[address & 0x1FFF]);

      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final bankIndex = (address >> 13) & 0x03;
      final bankOffset = address & 0x1FFF;

      return (prgBank[bankIndex] * 0x2000) + bankOffset;
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data, [int cycles = 0]) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_prgRamChipEnable && !_prgRamWriteProtect) {
        programRam[address & 0x1FFF] = data;
      }

      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      _handleRegisterWrite(address, data);
    }

    return null;
  }

  void _handleRegisterWrite(int address, int data) {
    final maskedAddress = address & 0xE001;

    switch (maskedAddress) {
      case 0x8000:
        _writeBankSelect(data);
      case 0x8001:
        _writeBankData(data);
      case 0xA000:
        _writeMirroring(data);
      case 0xA001:
        _writePrgRamProtect(data);
      case 0xC000:
        _writeIrqLatch(data);
      case 0xC001:
        _writeIrqReload();
      case 0xE000:
        _writeIrqDisable();
      case 0xE001:
        _writeIrqEnable();
    }
  }

  void _writeBankSelect(int data) {
    final oldPrgMode = _prgBankMode;
    final oldChrMode = _chrBankMode;

    _targetRegister = data & 0x07;
    _prgBankMode = (data & 0x40) != 0;
    _chrBankMode = (data & 0x80) != 0;

    if (_prgBankMode != oldPrgMode) _syncPrgBanking();
    if (_chrBankMode != oldChrMode) _syncChrBanking();
  }

  void _writeBankData(int data) {
    bankRegisters[_targetRegister] = data;

    _targetRegister <= 5 ? _syncChrBanking() : _syncPrgBanking();
  }

  void _writeMirroring(int data) {
    if (_fourScreenMode) return;

    _mirrorMode = (data & 0x01) != 0
        ? MapperMirror.horizontal
        : MapperMirror.vertical;

    setMirroring(data & 0x01);
  }

  void _writePrgRamProtect(int data) {
    _prgRamChipEnable = (data & 0x80) != 0;
    _prgRamWriteProtect = (data & 0x40) != 0;
  }

  void _writeIrqLatch(int data) => _irqLatch = data;

  void _writeIrqReload() {
    _irqCounter = 0;
    _irqReload = true;
  }

  void _writeIrqDisable() {
    _irqEnable = false;
    _irqActive = false;
  }

  void _writeIrqEnable() => _irqEnable = true;

  @override
  int? ppuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x0000 && address <= 0x1FFF) {
      final bankIndex = address >> 10;
      final bankOffset = address & 0x03FF;

      return (chrBank[bankIndex] * 0x0400) + bankOffset;
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

  @override
  void scanline(int row) {
    if (_irqCounter == 0 || _irqReload) {
      _irqCounter = _irqLatch;
      _irqReload = false;
    } else {
      _irqCounter--;
    }

    if (_irqCounter == 0 && _irqEnable) {
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
    'prgBankMode': _prgBankMode,
    'chrBankMode': _chrBankMode,
    'mirrorMode': _mirrorMode.index,
    'fourScreenMode': _fourScreenMode,
    'prgRamChipEnable': _prgRamChipEnable,
    'prgRamWriteProtect': _prgRamWriteProtect,
    'bankRegisters': bankRegisters.toList(),
    'irqLatch': _irqLatch,
    'irqCounter': _irqCounter,
    'irqReload': _irqReload,
    'irqEnable': _irqEnable,
    'irqActive': _irqActive,
    'programRam': programRam.toList(),
  };

  @override
  void restoreState(Map<String, dynamic> state) {
    _targetRegister = state['targetRegister'] as int;
    _prgBankMode = state['prgBankMode'] as bool;
    _chrBankMode = state['chrBankMode'] as bool;
    _mirrorMode = MapperMirror.values[state['mirrorMode'] as int];
    _fourScreenMode = state['fourScreenMode'] as bool? ?? false;
    _prgRamChipEnable = state['prgRamChipEnable'] as bool;
    _prgRamWriteProtect = state['prgRamWriteProtect'] as bool;

    final bankRegs = (state['bankRegisters'] as List).cast<int>();
    for (var i = 0; i < bankRegs.length; i++) {
      bankRegisters[i] = bankRegs[i];
    }

    _irqLatch = state['irqLatch'] as int;
    _irqCounter = state['irqCounter'] as int;
    _irqReload = state['irqReload'] as bool;
    _irqEnable = state['irqEnable'] as bool;
    _irqActive = state['irqActive'] as bool;

    programRam.setAll(0, (state['programRam'] as List).cast<int>());

    _syncBanking();
  }
}
