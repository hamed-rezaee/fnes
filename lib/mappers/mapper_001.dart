import 'dart:typed_data';
import 'package:fnes/mappers/mapper.dart';

class Mapper001 extends Mapper {
  Mapper001(super.programBankCount, super.totalCharBanks) {
    programRAM = Uint8List(32 * 1024);
    regs = [0, 0, 0, 0];
    reset();
  }

  late Uint8List programRAM;
  late List<int> regs;
  int ignoreWrites = 0;
  int cycleCount = 1;

  int _selectedCharBankLow = 0x00;
  int _selectedCharBankHigh = 0x00;
  int _selectedCharBank = 0x00;

  int _selectedProgramBankLow = 0x00;
  int _selectedProgramBankHigh = 0x00;
  int _selectedProgramBank = 0x00;

  int _loadRegister = 0x00;
  int _loadRegisterCount = 0x00;
  int _controlRegister = 0x00;

  bool _programRamEnable = true;

  MapperMirror _mirrorMode = MapperMirror.horizontal;

  @override
  String get name => 'MMC1';

  @override
  void reset() {
    regs[0] = 0x0C;
    regs[1] = 0;
    regs[2] = 0;
    regs[3] = 0;

    _loadRegister = 0x00;
    _loadRegisterCount = 0x00;
    _controlRegister = 0x1C;
    _programRamEnable = true;

    _selectedCharBankLow = 0;
    _selectedCharBankHigh = 0;
    _selectedCharBank = 0;

    _selectedProgramBank = 0;
    _selectedProgramBankLow = 0;
    _selectedProgramBankHigh = programBankCount - 1;
    _mirrorMode = MapperMirror.horizontal;

    ignoreWrites = 0;
    cycleCount = 1;

    _syncBanking();
  }

  @override
  void clock(int cycles) {
    ignoreWrites = 0;
  }

  void _syncBanking() {
    _syncPrg();
    _syncChr();
    _syncMirror();
  }

  void _syncPrg() {
    if ((regs[0] & 0x08) != 0) {
      if ((regs[0] & 0x04) != 0) {
        setPrgBank16k(Mapper.prg8000, regs[3] & 0x0F);
        setPrgBank16k(Mapper.prgC000, programBankCount - 1);
      } else {
        setPrgBank16k(Mapper.prg8000, 0);
        setPrgBank16k(Mapper.prgC000, regs[3] & 0x0F);
      }
    } else {
      setPrgBank32k((regs[3] & 0x0F) >> 1);
    }
  }

  void _syncChr() {
    if ((regs[0] & 0x10) != 0) {
      setChrBank4k(Mapper.chr0000, regs[1] & 0x1F);
      setChrBank4k(Mapper.chr1000, regs[2] & 0x1F);
    } else {
      setChrBank8k((regs[1] & 0x1F) >> 1);
    }
  }

  void _syncMirror() {
    switch (regs[0] & 0x03) {
      case 0x00:
        _mirrorMode = MapperMirror.oneScreenLow;
        setMirroring(0);
      case 0x01:
        _mirrorMode = MapperMirror.oneScreenHigh;
        setMirroring(1);
      case 0x02:
        _mirrorMode = MapperMirror.vertical;
        setMirroring(1);
      case 0x03:
        _mirrorMode = MapperMirror.horizontal;
        setMirroring(0);
    }
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_programRamEnable) {
        setData?.call(programRAM[address & 0x1FFF]);

        return 0xFFFFFFFF;
      }
      return null;
    }

    if (address >= 0x8000) {
      if ((_controlRegister & 0x08) != 0) {
        if (address >= 0x8000 && address <= 0xBFFF) {
          return _selectedProgramBankLow * 0x4000 + (address & 0x3FFF);
        }
        if (address >= 0xC000 && address <= 0xFFFF) {
          return _selectedProgramBankHigh * 0x4000 + (address & 0x3FFF);
        }
      } else {
        return _selectedProgramBank * 0x8000 + (address & 0x7FFF);
      }
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_programRamEnable) {
        programRAM[address & 0x1FFF] = data;
        return 0xFFFFFFFF;
      }
      return null;
    }

    if (address >= 0x8000 && ignoreWrites == 0) {
      ignoreWrites = 1;
      if ((data & 0x80) != 0) {
        _loadRegister = 0;
        _loadRegisterCount = 0;
        regs[0] |= 0x0C;
      } else {
        _loadRegister |= (data & 0x01) << _loadRegisterCount++;
        if (_loadRegisterCount == 5) {
          final targetRegister = (address >> 13) & 0x03;
          regs[targetRegister] = _loadRegister;
          _loadRegisterCount = 0;
          _loadRegister = 0;
          _syncBanking();
        }
      }
    }

    return null;
  }

  @override
  int? ppuMapRead(int address) {
    if (address < 0x2000) {
      if (totalCharBanks == 0) {
        return address;
      } else {
        if ((_controlRegister & 0x10) != 0) {
          if (address <= 0x0FFF) {
            return _selectedCharBankLow * 0x1000 + (address & 0x0FFF);
          } else {
            return _selectedCharBankHigh * 0x1000 + (address & 0x0FFF);
          }
        } else {
          return _selectedCharBank * 0x2000 + (address & 0x1FFF);
        }
      }
    }

    return null;
  }

  @override
  int? ppuMapWrite(int address) {
    if (address < 0x2000) {
      if (totalCharBanks == 0) return address;
    }

    return null;
  }

  @override
  MapperMirror mirror() => _mirrorMode;

  @override
  Map<String, dynamic> saveState() => {
        'selectedCharBankLow': _selectedCharBankLow,
        'selectedCharBankHigh': _selectedCharBankHigh,
        'selectedCharBank': _selectedCharBank,
        'selectedProgramBankLow': _selectedProgramBankLow,
        'selectedProgramBankHigh': _selectedProgramBankHigh,
        'selectedProgramBank': _selectedProgramBank,
        'loadRegister': _loadRegister,
        'loadRegisterCount': _loadRegisterCount,
        'controlRegister': _controlRegister,
        'programRamEnable': _programRamEnable,
        'mirrorMode': _mirrorMode.index,
        'programRAM': programRAM.toList(),
      };

  @override
  void restoreState(Map<String, dynamic> state) {
    _selectedCharBankLow = state['selectedCharBankLow'] as int;
    _selectedCharBankHigh = state['selectedCharBankHigh'] as int;
    _selectedCharBank = state['selectedCharBank'] as int;
    _selectedProgramBankLow = state['selectedProgramBankLow'] as int;
    _selectedProgramBankHigh = state['selectedProgramBankHigh'] as int;
    _selectedProgramBank = state['selectedProgramBank'] as int;
    _loadRegister = state['loadRegister'] as int;
    _loadRegisterCount = state['loadRegisterCount'] as int;
    _controlRegister = state['controlRegister'] as int;
    _programRamEnable = state['programRamEnable'] as bool;
    _mirrorMode = MapperMirror.values[state['mirrorMode'] as int];
    programRAM.setAll(0, (state['programRAM'] as List).cast<int>());
  }
}
