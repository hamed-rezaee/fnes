import 'dart:typed_data';

import 'package:fnes/mappers/mapper.dart';

class Mapper005 extends Mapper {
  Mapper005(super.programBankCount, super.totalCharBanks) {
    _prgRam = Uint8List(64 * 1024);
    _exRam = Uint8List(1024);

    reset();
  }

  late final Uint8List _prgRam;
  late final Uint8List _exRam;
  final Uint8List _internalNametableRam = Uint8List(2048);

  int _prgMode = 3;
  int _chrMode = 3;
  int _prgRamProtect1 = 0;
  int _prgRamProtect2 = 0;
  int _exRamMode = 0;
  int _chrHighBits = 0;
  int _fillTile = 0;
  int _fillColor = 0;

  final List<int> _nametableMapping = List.filled(4, 0);
  final List<int> _prgRegs = List.filled(5, 0);
  final List<int> _chrRegs = List.filled(12, 0);

  int _lastBgBank = 0;
  int _lastPalette = 0;

  int _vSplitMode = 0;
  int _vSplitScroll = 0;
  int _vSplitBank = 0;

  int _irqLineCompare = 0;
  bool _irqEnabled = false;
  bool _irqPending = false;
  bool _inFrame = false;
  int _scanlineC = 0;
  bool _inSplitRegion = false;
  int _bgFetchRemaining = 0;

  int _bgTileCount = 0;
  int _scanlineReads = 0;

  int _multiplierA = 0;
  int _multiplierB = 0;

  @override
  String get name => 'MMC5';

  @override
  void reset() {
    _internalNametableRam.fillRange(0, 2048, 0);
    _prgRegs.fillRange(0, 5, 0);
    _prgRegs[4] = 0xFF;

    _chrRegs.fillRange(0, 12, 0);
    _nametableMapping.fillRange(0, 4, 0);

    _prgMode = 3;
    _chrMode = 3;
    _exRamMode = 0;
    _chrHighBits = 0;
    _irqEnabled = false;
    _irqPending = false;
    _irqLineCompare = 0;
    _vSplitMode = 0;
    _vSplitScroll = 0;
    _vSplitBank = 0;
    _inFrame = false;
    _scanlineC = 0;
    _inSplitRegion = false;
    _lastBgBank = 0;
    _lastPalette = 0;
    _bgFetchRemaining = 0;
    _bgTileCount = 0;
    _prgRamProtect1 = 0;
    _prgRamProtect2 = 0;
  }

  @override
  int? cpuMapRead(int address, [void Function(int data)? setData]) {
    if (address >= 0x6000 && address <= 0x7FFF) {
      final ramBank = _prgRegs[0] & 0x07;

      setData?.call(_prgRam[(ramBank * 8192) + (address & 0x1FFF)]);

      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final (isRam, offset) = _resolvePrgBank(address);

      if (isRam) {
        setData?.call(_prgRam[offset & 0xFFFF]);

        return 0xFFFFFFFF;
      } else {
        return offset % prgRomData.length;
      }
    }

    if (address >= 0x5000 && address <= 0x5FFF) {
      return _readRegister(address, setData);
    }

    return null;
  }

  @override
  int? cpuMapWrite(int address, int data, [int cycles = 0]) {
    if (address >= 0x5000 && address <= 0x5FFF) {
      _writeRegister(address, data);

      return 0xFFFFFFFF;
    }

    if (address >= 0x6000 && address <= 0x7FFF) {
      if (_canWriteRam()) {
        final ramBank = _prgRegs[0] & 0x07;
        _prgRam[(ramBank * 8192) + (address & 0x1FFF)] = data;
      }

      return 0xFFFFFFFF;
    }

    if (address >= 0x8000 && address <= 0xFFFF) {
      final (isRam, offset) = _resolvePrgBank(address);

      if (isRam && _canWriteRam()) {
        _prgRam[offset & 0xFFFF] = data;
      }

      return 0xFFFFFFFF;
    }

    return null;
  }

  bool _canWriteRam() {
    return _prgRamProtect1 == 0x02 && _prgRamProtect2 == 0x01;
  }

  (bool, int) _resolvePrgBank(int address) {
    var bankRegValue = 0;

    if (_prgMode == 0) {
      bankRegValue = _prgRegs[4];
      final bankIndex = (bankRegValue & 0x7F) & 0x7C;
      final isRam = (bankRegValue & 0x80) == 0;
      return (isRam, (bankIndex * 8192) + (address & 0x7FFF));
    } else if (_prgMode == 1) {
      if (address < 0xC000) {
        bankRegValue = _prgRegs[2];
      } else {
        bankRegValue = _prgRegs[4];
      }

      final bankIndex = (bankRegValue & 0x7F) & 0x7E;
      final isRam = (bankRegValue & 0x80) == 0;

      return (isRam, (bankIndex * 8192) + (address & 0x3FFF));
    } else if (_prgMode == 2) {
      if (address < 0xC000) {
        bankRegValue = _prgRegs[2];
        final bankIndex = (bankRegValue & 0x7F) & 0x7E;
        final isRam = (bankRegValue & 0x80) == 0;

        return (isRam, (bankIndex * 8192) + (address & 0x3FFF));
      } else if (address < 0xE000) {
        bankRegValue = _prgRegs[3];
        final bankIndex = bankRegValue & 0x7F;
        final isRam = (bankRegValue & 0x80) == 0;

        return (isRam, (bankIndex * 8192) + (address & 0x1FFF));
      } else {
        bankRegValue = _prgRegs[4];
        final bankIndex = bankRegValue & 0x7F;
        final isRam = (bankRegValue & 0x80) == 0;

        return (isRam, (bankIndex * 8192) + (address & 0x1FFF));
      }
    } else {
      if (address < 0xA000) {
        bankRegValue = _prgRegs[1];
      } else if (address < 0xC000) {
        bankRegValue = _prgRegs[2];
      } else if (address < 0xE000) {
        bankRegValue = _prgRegs[3];
      } else {
        bankRegValue = _prgRegs[4];
      }

      final bankIndex = bankRegValue & 0x7F;
      final isRam = (bankRegValue & 0x80) == 0;

      return (isRam, (bankIndex * 8192) + (address & 0x1FFF));
    }
  }

  int? _readRegister(int address, void Function(int)? setData) {
    if (address == 0x5204) {
      var status = 0;

      if (_irqPending) status |= 0x80;
      if (_inFrame) status |= 0x40;

      _irqPending = false;
      setData?.call(status);

      return 0xFFFFFFFF;
    }
    if (address == 0x5205) {
      setData?.call((_multiplierA * _multiplierB) & 0xFF);

      return 0xFFFFFFFF;
    }
    if (address == 0x5206) {
      setData?.call(((_multiplierA * _multiplierB) >> 8) & 0xFF);

      return 0xFFFFFFFF;
    }
    if (address >= 0x5C00 && address <= 0x5FFF) {
      if (_exRamMode <= 1 || _exRamMode == 2 || _exRamMode == 3) {
        setData?.call(_exRam[address - 0x5C00]);

        return 0xFFFFFFFF;
      }
      setData?.call(0);

      return 0xFFFFFFFF;
    }

    return null;
  }

  void _writeRegister(int address, int data) {
    if (address == 0x5100) {
      _prgMode = data & 0x03;
    } else if (address == 0x5101) {
      _chrMode = data & 0x03;
    } else if (address == 0x5102) {
      _prgRamProtect1 = data & 0x03;
    } else if (address == 0x5103) {
      _prgRamProtect2 = data & 0x03;
    } else if (address == 0x5104) {
      _exRamMode = data & 0x03;
    } else if (address == 0x5105) {
      for (var i = 0; i < 4; i++) {
        _nametableMapping[i] = (data >> (i * 2)) & 0x03;
      }
    } else if (address == 0x5106) {
      _fillTile = data;
    } else if (address == 0x5107) {
      final c = data & 0x03;
      _fillColor = c | (c << 2) | (c << 4) | (c << 6);
    } else if (address >= 0x5113 && address <= 0x5117) {
      _prgRegs[address - 0x5113] = data;
    } else if (address >= 0x5120 && address <= 0x512B) {
      _chrRegs[address - 0x5120] = data | (_chrHighBits << 8);
    } else if (address == 0x5130) {
      _chrHighBits = data & 0x03;
    } else if (address == 0x5200) {
      _vSplitMode = data;
    } else if (address == 0x5201) {
      _vSplitScroll = data;
    } else if (address == 0x5202) {
      _vSplitBank = data;
    } else if (address == 0x5203) {
      _irqLineCompare = data;
    } else if (address == 0x5204) {
      _irqEnabled = (data & 0x80) != 0;
    } else if (address == 0x5205) {
      _multiplierA = data;
    } else if (address == 0x5206) {
      _multiplierB = data;
    } else if (address >= 0x5C00 && address <= 0x5FFF) {
      if (_exRamMode != 3) {
        _exRam[address - 0x5C00] = data;
      }
    }
  }

  @override
  int? ppuMapRead(int address, [void Function(int data)? setData]) {
    if (address < 0x2000) {
      if (_inFrame) {
        _scanlineReads++;
      }

      final isSprite = _bgFetchRemaining == 0;

      if (!isSprite) _bgFetchRemaining--;

      return _mapChr(address, isSprite);
    }

    if (address >= 0x2000 && address <= 0x3EFF) {
      if (_inFrame) {
        _scanlineReads++;
      }
      return _mapNametable(address, setData);
    }

    return null;
  }

  int? _mapNametable(int address, [void Function(int data)? setData]) {
    final offset = address & 0x0FFF;
    final isAttribute = (offset & 0x3FF) >= 0x3C0;

    final isDummy = _scanlineReads >= 9 && _scanlineReads <= 11;

    if (!isAttribute) {
      if (isDummy) {
        _bgFetchRemaining = 0;
      } else {
        _bgFetchRemaining = 2;
      }
    } else {
      _bgFetchRemaining = 2;
    }

    if (_inSplitRegion && isAttribute) {
      setData?.call(
        _lastPalette |
            (_lastPalette << 2) |
            (_lastPalette << 4) |
            (_lastPalette << 6),
      );

      return 0xFFFFFFFF;
    }

    if (!isAttribute && !isDummy) {
      final coarseX = _bgTileCount;

      _bgTileCount++;

      if ((_vSplitMode & 0x80) != 0) {
        final splitTile = _vSplitMode & 0x1F;
        final rightSide = (_vSplitMode & 0x40) == 0;

        if (rightSide ? (coarseX >= splitTile) : (coarseX < splitTile)) {
          _inSplitRegion = true;

          var y = _scanlineC;
          if (y < 0) y = 0;

          var scrolly = y + _vSplitScroll;

          if (scrolly >= 240) scrolly -= 240;

          final exAddr = ((scrolly >> 3) * 32) + coarseX;
          final val = _exRam[exAddr & 0x3FF];

          _lastBgBank = (val & 0x3F) | (_chrHighBits << 6);
          _lastPalette = (val >> 6) & 0x03;

          setData?.call(val);

          return 0xFFFFFFFF;
        } else {
          _inSplitRegion = false;
        }
      } else {
        _inSplitRegion = false;
      }
    }

    if (_exRamMode == 1) {
      if (!isAttribute) {
        final exAddr = offset & 0x3FF;
        final val = _exRam[exAddr];

        _lastBgBank = (val & 0x3F) | (_chrHighBits << 6);
        _lastPalette = (val >> 6) & 0x03;
      } else {
        final p = _lastPalette;
        setData?.call(p | (p << 2) | (p << 4) | (p << 6));

        return 0xFFFFFFFF;
      }
    }

    final ntIndex = (address >> 10) & 0x03;
    final mode = _nametableMapping[ntIndex];

    if (mode == 0) {
      setData?.call(_internalNametableRam[offset & 0x3FF]);

      return 0xFFFFFFFF;
    } else if (mode == 1) {
      setData?.call(_internalNametableRam[0x400 + (offset & 0x3FF)]);

      return 0xFFFFFFFF;
    } else if (mode == 2) {
      setData?.call(_exRam[offset & 0x3FF]);
      return 0xFFFFFFFF;
    } else if (mode == 3) {
      if (isAttribute) {
        setData?.call(_fillColor);
      } else {
        setData?.call(_fillTile);
      }

      return 0xFFFFFFFF;
    }

    return null;
  }

  int _mapChr(int address, bool isSprite) {
    if (_inSplitRegion && !isSprite) {
      return (_vSplitBank * 4096) + (address & 0x0FFF);
    }

    if (!isSprite && _exRamMode == 1) {
      return (_lastBgBank * 4096) + (address & 0x0FFF);
    }

    if (_chrMode == 3) {
      if (isSprite) {
        final page = address >> 10;
        final bank = _chrRegs[page & 0x07];

        return (bank * 1024) + (address & 0x3FF);
      } else {
        final bgPage = (address >> 10) & 0x07;
        final regIndex = 8 + (bgPage % 4);
        final bank = _chrRegs[regIndex];

        return (bank * 1024) + (address & 0x3FF);
      }
    } else if (_chrMode == 2) {
      final page = address >> 11;
      final bank = _chrRegs[(page * 2) + 1];

      return (bank * 2048) + (address & 0x7FF);
    } else if (_chrMode == 1) {
      final page = address >> 12;
      final bank = _chrRegs[(page * 4) + 3];

      return (bank * 4096) + (address & 0xFFF);
    } else {
      final bank = _chrRegs[7];

      return (bank * 8192) + (address & 0x1FFF);
    }
  }

  @override
  int? ppuMapWrite(int address) {
    if (address >= 0x2000 && address <= 0x3EFF) {
      final ntIndex = (address >> 10) & 0x03;
      final mode = _nametableMapping[ntIndex];

      if (mode == 0 || mode == 1 || mode == 2) return 0xFFFFFFFF;
    }

    return null;
  }

  @override
  MapperMirror mirror() => switch (_nametableMapping) {
    [0 || 2 || 3, 0 || 2 || 3, 1 || 2 || 3, 1 || 2 || 3] =>
      MapperMirror.horizontal,
    [0 || 2 || 3, 1 || 2 || 3, 0 || 2 || 3, 1 || 2 || 3] =>
      MapperMirror.vertical,
    [0 || 2 || 3, 0 || 2 || 3, 0 || 2 || 3, 0 || 2 || 3] =>
      MapperMirror.oneScreenLow,
    [1 || 2 || 3, 1 || 2 || 3, 1 || 2 || 3, 1 || 2 || 3] =>
      MapperMirror.oneScreenHigh,
    _ => MapperMirror.vertical,
  };

  @override
  void scanline(int row) {
    _inSplitRegion = false;
    _bgTileCount = -2;
    _scanlineReads = 0;

    _scanlineC = row + 1;

    if (_scanlineC >= 0 && _scanlineC < 240) {
      _inFrame = true;
      if (_scanlineC == _irqLineCompare) {
        if (_irqEnabled) {
          _irqPending = true;
        }
      }
    } else {
      _inFrame = false;
      _irqPending = false;
    }
  }

  @override
  void clock(int cycles) {}

  @override
  bool irqState() => _irqEnabled && _irqPending;

  @override
  void irqClear() => _irqPending = false;

  @override
  void ppuWriteNotify(int address, int data) {
    if (address >= 0x2000 && address <= 0x3EFF) {
      final ntIndex = (address >> 10) & 0x03;
      final mode = _nametableMapping[ntIndex];
      final offset = address & 0x0FFF;

      if (mode == 0) {
        _internalNametableRam[offset & 0x3FF] = data;
      } else if (mode == 1) {
        _internalNametableRam[0x400 + (offset & 0x3FF)] = data;
      } else if (mode == 2 && (_exRamMode == 0 || _exRamMode == 1)) {
        _exRam[offset & 0x3FF] = data;
      } else if (mode == 3) {
        final mirrorMode = mirror();
        final targetPage = switch (mirrorMode) {
          MapperMirror.vertical => ntIndex & 1,
          MapperMirror.horizontal => (ntIndex >> 1) & 1,
          MapperMirror.oneScreenLow => 0,
          MapperMirror.oneScreenHigh => 1,
          _ => 0,
        };

        if (targetPage == 0) {
          _internalNametableRam[offset & 0x3FF] = data;
        } else {
          _internalNametableRam[0x400 + (offset & 0x3FF)] = data;
        }
      }
    }
  }
}
