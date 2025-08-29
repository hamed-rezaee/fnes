import 'dart:typed_data';
import 'package:fnes/mappers/mapper.dart';

class Mapper001 extends Mapper {
  Mapper001(super.programBankCount, super.totalCharBanks) {
    programRAM = Uint8List(32 * 1024);

    reset();
  }

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

  late Uint8List programRAM;

  @override
  String get name => 'MMC1';

  @override
  void reset() {
    _controlRegister = 0x1C;
    _loadRegister = 0x00;
    _loadRegisterCount = 0x00;
    _programRamEnable = true;

    _selectedCharBankLow = 0;
    _selectedCharBankHigh = 0;
    _selectedCharBank = 0;

    _selectedProgramBank = 0;
    _selectedProgramBankLow = 0;
    _selectedProgramBankHigh = programBankCount - 1;
    _mirrorMode = MapperMirror.horizontal;
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

    if (address >= 0x8000) {
      if ((data & 0x80) != 0) {
        _loadRegister = 0x00;
        _loadRegisterCount = 0;
        _controlRegister |= 0x0C;
      } else {
        _loadRegister >>= 1;
        _loadRegister |= (data & 0x01) << 4;
        _loadRegisterCount++;

        if (_loadRegisterCount == 5) {
          final targetRegister = (address >> 13) & 0x03;

          if (targetRegister == 0) {
            _controlRegister = _loadRegister & 0x1F;
            switch (_controlRegister & 0x03) {
              case 0:
                _mirrorMode = MapperMirror.oneScreenLow;
              case 1:
                _mirrorMode = MapperMirror.oneScreenHigh;
              case 2:
                _mirrorMode = MapperMirror.vertical;
              case 3:
                _mirrorMode = MapperMirror.horizontal;
            }
          } else if (targetRegister == 1) {
            if ((_controlRegister & 0x10) != 0) {
              _selectedCharBankLow = _loadRegister & 0x1F;
            } else {
              _selectedCharBank = _loadRegister & 0x1E;
            }
          } else if (targetRegister == 2) {
            if ((_controlRegister & 0x10) != 0) {
              _selectedCharBankHigh = _loadRegister & 0x1F;
            }
          } else if (targetRegister == 3) {
            _programRamEnable = (_loadRegister & 0x10) == 0;

            final programMode = (_controlRegister >> 2) & 0x03;
            if (programMode == 0 || programMode == 1) {
              _selectedProgramBank = (_loadRegister & 0x0E) >> 1;
            } else if (programMode == 2) {
              _selectedProgramBankLow = 0;
              _selectedProgramBankHigh = _loadRegister & 0x0F;
            } else if (programMode == 3) {
              _selectedProgramBankLow = _loadRegister & 0x0F;
              _selectedProgramBankHigh = programBankCount - 1;
            }
          }

          _loadRegister = 0x00;
          _loadRegisterCount = 0;
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
}
