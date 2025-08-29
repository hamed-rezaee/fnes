import 'dart:typed_data';
import 'package:fnes/mappers/mapper.dart';

class Mapper004 extends Mapper {
  Mapper004(super.programBankCount, super.totalCharBanks) {
    programRam = Uint8List(8 * 1024);
    reset();
  }

  int _targetRegister = 0;
  bool _programBankMode = false;
  bool _charA12Inversion = false;
  MapperMirror _mirrorMode = MapperMirror.horizontal;

  bool _programRamEnabled = true;
  bool _programRamWriteProtect = false;

  final List<int> _bankRegisters = List.filled(8, 0);
  final List<int> _charBanks = List.filled(8, 0);
  final List<int> _programBanks = List.filled(4, 0);

  bool _irqActive = false;
  bool _irqEnabled = false;
  bool _irqReloadPending = false;
  int _irqCounter = 0;
  int _irqLatch = 0;

  late Uint8List programRam;

  @override
  String get name => 'MMC3';

  @override
  void reset() {
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

    for (var i = 0; i < 8; i++) {
      _bankRegisters[i] = 0;
    }

    _updateBanks();
  }

  void _updateBanks() {
    if (_charA12Inversion) {
      _charBanks[0] = _bankRegisters[2] * 0x0400;
      _charBanks[1] = _bankRegisters[3] * 0x0400;
      _charBanks[2] = _bankRegisters[4] * 0x0400;
      _charBanks[3] = _bankRegisters[5] * 0x0400;
      _charBanks[4] = (_bankRegisters[0] & 0xFE) * 0x0400;
      _charBanks[5] = ((_bankRegisters[0] & 0xFE) + 1) * 0x0400;
      _charBanks[6] = (_bankRegisters[1] & 0xFE) * 0x0400;
      _charBanks[7] = ((_bankRegisters[1] & 0xFE) + 1) * 0x0400;
    } else {
      _charBanks[0] = (_bankRegisters[0] & 0xFE) * 0x0400;
      _charBanks[1] = ((_bankRegisters[0] & 0xFE) + 1) * 0x0400;
      _charBanks[2] = (_bankRegisters[1] & 0xFE) * 0x0400;
      _charBanks[3] = ((_bankRegisters[1] & 0xFE) + 1) * 0x0400;
      _charBanks[4] = _bankRegisters[2] * 0x0400;
      _charBanks[5] = _bankRegisters[3] * 0x0400;
      _charBanks[6] = _bankRegisters[4] * 0x0400;
      _charBanks[7] = _bankRegisters[5] * 0x0400;
    }

    if (_programBankMode) {
      _programBanks[0] = (programBankCount * 2 - 2) * 0x2000;
      _programBanks[2] = (_bankRegisters[6] & 0x3F) * 0x2000;
    } else {
      _programBanks[0] = (_bankRegisters[6] & 0x3F) * 0x2000;
      _programBanks[2] = (programBankCount * 2 - 2) * 0x2000;
    }
    _programBanks[1] = (_bankRegisters[7] & 0x3F) * 0x2000;
    _programBanks[3] = (programBankCount * 2 - 1) * 0x2000;
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_programRamEnabled) {
        setData?.call(programRam[address & 0x1FFF]);
      }
      return 0xFFFFFFFF;
    }

    if (address >= 0x8000) {
      final maskedAddress = address & 0xFFFF;
      if (maskedAddress <= 0x9FFF) {
        return _programBanks[0] + (maskedAddress & 0x1FFF);
      }
      if (maskedAddress <= 0xBFFF) {
        return _programBanks[1] + (maskedAddress & 0x1FFF);
      }
      if (maskedAddress <= 0xDFFF) {
        return _programBanks[2] + (maskedAddress & 0x1FFF);
      }

      return _programBanks[3] + (maskedAddress & 0x1FFF);
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
      if ((address & 1) == 0) {
        _targetRegister = data & 0x07;
        _programBankMode = (data & 0x40) != 0;
        _charA12Inversion = (data & 0x80) != 0;
      } else {
        _bankRegisters[_targetRegister] = data;
        _updateBanks();
      }
    } else if (address >= 0xA000 && address <= 0xBFFF) {
      if ((address & 1) == 0) {
        _mirrorMode = (data & 0x01) != 0
            ? MapperMirror.horizontal
            : MapperMirror.vertical;
      } else {
        _programRamEnabled = (data & 0x80) != 0;
        _programRamWriteProtect = (data & 0x40) != 0;
      }
    } else if (address >= 0xC000 && address <= 0xDFFF) {
      if ((address & 1) == 0) {
        _irqLatch = data;
      } else {
        _irqCounter = 0;
        _irqReloadPending = true;
      }
    } else if (address >= 0xE000 && address <= 0xFFFF) {
      if ((address & 1) == 0) {
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
    if (address <= 0x1FFF) {
      final bank = address >> 10;
      final offset = address & 0x03FF;
      return _charBanks[bank] + offset;
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
}
