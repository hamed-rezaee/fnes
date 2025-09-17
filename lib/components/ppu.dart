import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fnes/components/cartridge.dart';
import 'package:fnes/mappers/mapper.dart';

class PPU {
  PPU() {
    status = PPUStatus();
    mask = PPUMask();
    control = PPUControl();
    vramAddress = LoopyRegister();
    temporaryAddressRegister = LoopyRegister();

    for (var i = 0; i < 8; i++) {
      spriteScanline.add(ObjectAttributeEntry());
    }

    pOAM2 = ObjectAttributeEntry();

    palScreen = [
      const ui.Color.fromARGB(255, 84, 84, 84),
      const ui.Color.fromARGB(255, 0, 30, 116),
      const ui.Color.fromARGB(255, 8, 16, 144),
      const ui.Color.fromARGB(255, 48, 0, 136),
      const ui.Color.fromARGB(255, 68, 0, 100),
      const ui.Color.fromARGB(255, 92, 0, 48),
      const ui.Color.fromARGB(255, 84, 4, 0),
      const ui.Color.fromARGB(255, 60, 24, 0),
      const ui.Color.fromARGB(255, 32, 42, 0),
      const ui.Color.fromARGB(255, 8, 58, 0),
      const ui.Color.fromARGB(255, 0, 64, 0),
      const ui.Color.fromARGB(255, 0, 60, 0),
      const ui.Color.fromARGB(255, 0, 50, 60),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 152, 150, 152),
      const ui.Color.fromARGB(255, 8, 76, 196),
      const ui.Color.fromARGB(255, 48, 50, 236),
      const ui.Color.fromARGB(255, 92, 30, 228),
      const ui.Color.fromARGB(255, 136, 20, 176),
      const ui.Color.fromARGB(255, 160, 20, 100),
      const ui.Color.fromARGB(255, 152, 34, 32),
      const ui.Color.fromARGB(255, 120, 60, 0),
      const ui.Color.fromARGB(255, 84, 90, 0),
      const ui.Color.fromARGB(255, 40, 114, 0),
      const ui.Color.fromARGB(255, 8, 124, 0),
      const ui.Color.fromARGB(255, 0, 118, 40),
      const ui.Color.fromARGB(255, 0, 102, 120),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 236, 238, 236),
      const ui.Color.fromARGB(255, 76, 154, 236),
      const ui.Color.fromARGB(255, 120, 124, 236),
      const ui.Color.fromARGB(255, 176, 98, 236),
      const ui.Color.fromARGB(255, 228, 84, 236),
      const ui.Color.fromARGB(255, 236, 88, 180),
      const ui.Color.fromARGB(255, 236, 106, 100),
      const ui.Color.fromARGB(255, 212, 136, 32),
      const ui.Color.fromARGB(255, 160, 170, 0),
      const ui.Color.fromARGB(255, 116, 196, 0),
      const ui.Color.fromARGB(255, 76, 208, 32),
      const ui.Color.fromARGB(255, 56, 204, 108),
      const ui.Color.fromARGB(255, 56, 180, 204),
      const ui.Color.fromARGB(255, 60, 60, 60),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 236, 238, 236),
      const ui.Color.fromARGB(255, 168, 204, 236),
      const ui.Color.fromARGB(255, 188, 188, 236),
      const ui.Color.fromARGB(255, 212, 178, 236),
      const ui.Color.fromARGB(255, 236, 174, 236),
      const ui.Color.fromARGB(255, 236, 174, 212),
      const ui.Color.fromARGB(255, 236, 180, 176),
      const ui.Color.fromARGB(255, 228, 196, 144),
      const ui.Color.fromARGB(255, 204, 210, 120),
      const ui.Color.fromARGB(255, 180, 222, 120),
      const ui.Color.fromARGB(255, 168, 226, 144),
      const ui.Color.fromARGB(255, 152, 226, 180),
      const ui.Color.fromARGB(255, 160, 214, 228),
      const ui.Color.fromARGB(255, 160, 162, 160),
      const ui.Color.fromARGB(255, 0, 0, 0),
      const ui.Color.fromARGB(255, 0, 0, 0),
    ];
  }

  Cartridge? cart;
  final Uint8List tableData = Uint8List(2048);
  final Uint8List paletteTable = Uint8List(32);
  final Uint8List patternTable = Uint8List(8192);

  late PPUStatus status;
  late PPUMask mask;
  late PPUControl control;
  late LoopyRegister vramAddress;
  late LoopyRegister temporaryAddressRegister;

  int fineX = 0x00;
  int addressLatch = 0x00;
  int ppuDataBuffer = 0x00;

  int backgroundNextTileId = 0x00;
  int backgroundNextTileAttrib = 0x00;
  int backgroundNextTileLsb = 0x00;
  int backgroundNextTileMsb = 0x00;
  int backgroundShifterPatternLow = 0x0000;
  int backgroundShifterPatternHigh = 0x0000;
  int backgroundShifterAttribLow = 0x0000;
  int backgroundShifterAttribHigh = 0x0000;

  List<ObjectAttributeEntry> spriteScanline = [];
  int spriteCount = 0;
  List<int> spriteShifterPatternLow = List.filled(8, 0);
  List<int> spriteShifterPatternHigh = List.filled(8, 0);
  bool spriteZeroHitPossible = false;
  bool spriteZeroBeingRendered = false;

  int scanline = 0;
  int cycle = 0;
  int frameCounter = 0;

  ui.Image? sprScreen;
  List<List<int>> screenPixels = List.generate(240, (_) => List.filled(256, 0));

  List<ui.Color> palScreen = [];

  final Uint8List pOAM = Uint8List(256);
  late ObjectAttributeEntry pOAM2;

  bool frameComplete = false;
  bool nmi = false;

  void reset() {
    fineX = 0x00;
    addressLatch = 0;
    ppuDataBuffer = 0x00;
    scanline = 0;
    cycle = 0;
    frameCounter = 0;
    backgroundNextTileId = 0x00;
    backgroundNextTileAttrib = 0x00;
    backgroundNextTileLsb = 0x00;
    backgroundNextTileMsb = 0x00;
    backgroundShifterPatternLow = 0x0000;
    backgroundShifterPatternHigh = 0x0000;
    backgroundShifterAttribLow = 0x0000;
    backgroundShifterAttribHigh = 0x0000;
    status.reg = 0x00;
    mask.reg = 0x00;
    control.reg = 0x00;
    vramAddress.reg = 0x0000;
    temporaryAddressRegister.reg = 0x0000;
  }

  int cpuRead(int address, {bool readOnly = false}) {
    var data = 0x00;

    if (readOnly) {
      switch (address) {
        case 0x0000:
          data = control.reg;
        case 0x0001:
          data = mask.reg;
        case 0x0002:
          data = status.reg;
        case 0x0003:
          break;
        case 0x0004:
          break;
        case 0x0005:
          break;
        case 0x0006:
          break;
        case 0x0007:
          break;
      }
    } else {
      switch (address) {
        case 0x0000:
          break;
        case 0x0001:
          break;
        case 0x0002:
          data = (status.reg & 0xE0) | (ppuDataBuffer & 0x1F);
          status.verticalBlank = false;
          addressLatch = 0;
        case 0x0003:
          break;
        case 0x0004:
          data = pOAM[oamAddress];
        case 0x0005:
          break;
        case 0x0006:
          break;
        case 0x0007:
          data = ppuDataBuffer;
          ppuDataBuffer = ppuRead(vramAddress.reg);

          if (vramAddress.reg >= 0x3F00) {
            data = ppuDataBuffer;
          }
          vramAddress.reg += (control.incrementMode ? 32 : 1);
          vramAddress.reg &= 0x3FFF;
      }
    }

    return data;
  }

  void cpuWrite(int address, int data) {
    switch (address) {
      case 0x0000:
        control.reg = data;
        temporaryAddressRegister.nametableX = control.nametableX;
        temporaryAddressRegister.nametableY = control.nametableY;
      case 0x0001:
        mask.reg = data;
      case 0x0002:
        break;
      case 0x0003:
        oamAddress = data;
      case 0x0004:
        pOAM[oamAddress] = data;
      case 0x0005:
        if (addressLatch == 0) {
          fineX = data & 0x07;
          temporaryAddressRegister.coarseX = data >> 3;
          addressLatch = 1;
        } else {
          temporaryAddressRegister.fineY = data & 0x07;
          temporaryAddressRegister.coarseY = data >> 3;
          addressLatch = 0;
        }
      case 0x0006:
        if (addressLatch == 0) {
          temporaryAddressRegister.reg =
              (temporaryAddressRegister.reg & 0x80FF) | ((data & 0x3F) << 8);
          addressLatch = 1;
        } else {
          temporaryAddressRegister.reg =
              (temporaryAddressRegister.reg & 0xFF00) | data;
          vramAddress.reg = temporaryAddressRegister.reg;
          addressLatch = 0;
        }
      case 0x0007:
        ppuWrite(vramAddress.reg, data);
        vramAddress.reg += (control.incrementMode ? 32 : 1);
        vramAddress.reg &= 0x3FFF;
    }
  }

  int ppuRead(int address) {
    var memoryAddress = address;
    var data = 0x00;
    memoryAddress &= 0x3FFF;

    if (cart?.ppuRead(memoryAddress, (value) => data = value) ?? false) {
    } else if (memoryAddress >= 0x0000 && memoryAddress <= 0x1FFF) {
      data = patternTable[memoryAddress];
    } else if (memoryAddress >= 0x2000 && memoryAddress <= 0x3EFF) {
      memoryAddress &= 0x0FFF;

      if (cart?.mirror() == MapperMirror.vertical) {
        if (memoryAddress >= 0x0000 && memoryAddress <= 0x03FF) {
          data = tableData[memoryAddress & 0x03FF];
        }
        if (memoryAddress >= 0x0400 && memoryAddress <= 0x07FF) {
          data = tableData[0x0400 + (memoryAddress & 0x03FF)];
        }
        if (memoryAddress >= 0x0800 && memoryAddress <= 0x0BFF) {
          data = tableData[memoryAddress & 0x03FF];
        }
        if (memoryAddress >= 0x0C00 && memoryAddress <= 0x0FFF) {
          data = tableData[0x0400 + (memoryAddress & 0x03FF)];
        }
      } else if (cart?.mirror() == MapperMirror.horizontal) {
        if (memoryAddress >= 0x0000 && memoryAddress <= 0x03FF) {
          data = tableData[memoryAddress & 0x03FF];
        }
        if (memoryAddress >= 0x0400 && memoryAddress <= 0x07FF) {
          data = tableData[memoryAddress & 0x03FF];
        }
        if (memoryAddress >= 0x0800 && memoryAddress <= 0x0BFF) {
          data = tableData[0x0400 + (memoryAddress & 0x03FF)];
        }
        if (memoryAddress >= 0x0C00 && memoryAddress <= 0x0FFF) {
          data = tableData[0x0400 + (memoryAddress & 0x03FF)];
        }
      } else if (cart?.mirror() == MapperMirror.oneScreenLow) {
        data = tableData[memoryAddress & 0x03FF];
      } else if (cart?.mirror() == MapperMirror.oneScreenHigh) {
        data = tableData[0x0400 + (memoryAddress & 0x03FF)];
      }
    } else if (memoryAddress >= 0x3F00 && memoryAddress <= 0x3FFF) {
      memoryAddress &= 0x001F;
      if (memoryAddress == 0x0010) memoryAddress = 0x0000;
      if (memoryAddress == 0x0014) memoryAddress = 0x0004;
      if (memoryAddress == 0x0018) memoryAddress = 0x0008;
      if (memoryAddress == 0x001C) memoryAddress = 0x000C;
      data = paletteTable[memoryAddress] & (mask.grayscale ? 0x30 : 0x3F);
    }

    return data;
  }

  void ppuWrite(int address, int data) {
    var memoryAddress = address;
    memoryAddress &= 0x3FFF;

    if (cart?.ppuWrite(memoryAddress, data) ?? false) {
    } else if (memoryAddress >= 0x0000 && memoryAddress <= 0x1FFF) {
      patternTable[memoryAddress] = data;
    } else if (memoryAddress >= 0x2000 && memoryAddress <= 0x3EFF) {
      memoryAddress &= 0x0FFF;

      if (cart?.mirror() == MapperMirror.vertical) {
        if (memoryAddress >= 0x0000 && memoryAddress <= 0x03FF) {
          tableData[memoryAddress & 0x03FF] = data;
        }
        if (memoryAddress >= 0x0400 && memoryAddress <= 0x07FF) {
          tableData[0x0400 + (memoryAddress & 0x03FF)] = data;
        }
        if (memoryAddress >= 0x0800 && memoryAddress <= 0x0BFF) {
          tableData[memoryAddress & 0x03FF] = data;
        }
        if (memoryAddress >= 0x0C00 && memoryAddress <= 0x0FFF) {
          tableData[0x0400 + (memoryAddress & 0x03FF)] = data;
        }
      } else if (cart?.mirror() == MapperMirror.horizontal) {
        if (memoryAddress >= 0x0000 && memoryAddress <= 0x03FF) {
          tableData[memoryAddress & 0x03FF] = data;
        }
        if (memoryAddress >= 0x0400 && memoryAddress <= 0x07FF) {
          tableData[memoryAddress & 0x03FF] = data;
        }
        if (memoryAddress >= 0x0800 && memoryAddress <= 0x0BFF) {
          tableData[0x0400 + (memoryAddress & 0x03FF)] = data;
        }
        if (memoryAddress >= 0x0C00 && memoryAddress <= 0x0FFF) {
          tableData[0x0400 + (memoryAddress & 0x03FF)] = data;
        }
      } else if (cart?.mirror() == MapperMirror.oneScreenLow) {
        tableData[memoryAddress & 0x03FF] = data;
      } else if (cart?.mirror() == MapperMirror.oneScreenHigh) {
        tableData[0x0400 + (memoryAddress & 0x03FF)] = data;
      }
    } else if (memoryAddress >= 0x3F00 && memoryAddress <= 0x3FFF) {
      memoryAddress &= 0x001F;
      if (memoryAddress == 0x0010) memoryAddress = 0x0000;
      if (memoryAddress == 0x0014) memoryAddress = 0x0004;
      if (memoryAddress == 0x0018) memoryAddress = 0x0008;
      if (memoryAddress == 0x001C) memoryAddress = 0x000C;
      paletteTable[memoryAddress] = data;
    }
  }

  void clock() {
    void incrementScrollX() {
      if (mask.renderBackground || mask.renderSprites) {
        if (vramAddress.coarseX == 31) {
          vramAddress.coarseX = 0;
          vramAddress.nametableX = ~vramAddress.nametableX;
        } else {
          vramAddress.coarseX++;
        }
      }
    }

    void incrementScrollY() {
      if (mask.renderBackground || mask.renderSprites) {
        if (vramAddress.fineY < 7) {
          vramAddress.fineY++;
        } else {
          vramAddress.fineY = 0;
          if (vramAddress.coarseY == 29) {
            vramAddress.coarseY = 0;
            vramAddress.nametableY = ~vramAddress.nametableY;
          } else if (vramAddress.coarseY == 31) {
            vramAddress.coarseY = 0;
          } else {
            vramAddress.coarseY++;
          }
        }
      }
    }

    void transferAddressX() {
      if (mask.renderBackground || mask.renderSprites) {
        vramAddress.nametableX = temporaryAddressRegister.nametableX;
        vramAddress.coarseX = temporaryAddressRegister.coarseX;
      }
    }

    void transferAddressY() {
      if (mask.renderBackground || mask.renderSprites) {
        vramAddress.fineY = temporaryAddressRegister.fineY;
        vramAddress.nametableY = temporaryAddressRegister.nametableY;
        vramAddress.coarseY = temporaryAddressRegister.coarseY;
      }
    }

    void loadBackgroundShifters() {
      backgroundShifterPatternLow =
          (backgroundShifterPatternLow & 0xFF00) | backgroundNextTileLsb;
      backgroundShifterPatternHigh =
          (backgroundShifterPatternHigh & 0xFF00) | backgroundNextTileMsb;

      backgroundShifterAttribLow = (backgroundShifterAttribLow & 0xFF00) |
          ((backgroundNextTileAttrib & 0x01) != 0 ? 0xFF : 0x00);
      backgroundShifterAttribHigh = (backgroundShifterAttribHigh & 0xFF00) |
          ((backgroundNextTileAttrib & 0x02) != 0 ? 0xFF : 0x00);
    }

    void updateShifters() {
      if (mask.renderBackground) {
        backgroundShifterPatternLow <<= 1;
        backgroundShifterPatternHigh <<= 1;
        backgroundShifterAttribLow <<= 1;
        backgroundShifterAttribHigh <<= 1;
      }

      if (mask.renderSprites && cycle >= 1 && cycle < 258) {
        for (var i = 0; i < spriteCount; i++) {
          if (spriteScanline[i].x > 0) {
            spriteScanline[i].x--;
          } else {
            spriteShifterPatternLow[i] <<= 1;
            spriteShifterPatternHigh[i] <<= 1;
          }
        }
      }
    }

    if (scanline >= -1 && scanline < 240) {
      if (scanline == 0 &&
          cycle == 0 &&
          (mask.renderBackground || mask.renderSprites) &&
          (frameCounter & 1) == 1) {
        cycle = 1;
      }

      if (scanline == -1 && cycle == 1) {
        status.verticalBlank = false;

        status.spriteOverflow = false;

        status.spriteZeroHit = false;

        for (var i = 0; i < 8; i++) {
          spriteShifterPatternLow[i] = 0;
          spriteShifterPatternHigh[i] = 0;
        }
      }

      if ((cycle >= 2 && cycle < 258) || (cycle >= 321 && cycle < 338)) {
        updateShifters();

        switch ((cycle - 1) % 8) {
          case 0:
            loadBackgroundShifters();

            backgroundNextTileId = ppuRead(0x2000 | (vramAddress.reg & 0x0FFF));
          case 2:
            backgroundNextTileAttrib = ppuRead(
              0x23C0 |
                  (vramAddress.nametableY << 11) |
                  (vramAddress.nametableX << 10) |
                  ((vramAddress.coarseY >> 2) << 3) |
                  (vramAddress.coarseX >> 2),
            );

            if ((vramAddress.coarseY & 0x02) != 0) {
              backgroundNextTileAttrib >>= 4;
            }
            if ((vramAddress.coarseX & 0x02) != 0) {
              backgroundNextTileAttrib >>= 2;
            }
            backgroundNextTileAttrib &= 0x03;
          case 4:
            backgroundNextTileLsb = ppuRead(
              (control.patternBackground << 12) +
                  (backgroundNextTileId << 4) +
                  (vramAddress.fineY) +
                  0,
            );
          case 6:
            backgroundNextTileMsb = ppuRead(
              (control.patternBackground << 12) +
                  (backgroundNextTileId << 4) +
                  (vramAddress.fineY) +
                  8,
            );
          case 7:
            incrementScrollX();
        }
      }

      if (cycle == 256) {
        incrementScrollY();
      }

      if (cycle == 257) {
        loadBackgroundShifters();
        transferAddressX();
      }

      if (cycle == 260) {
        if (mask.renderBackground || mask.renderSprites) {
          cart?.getMapper().scanline();
        }
      }

      if (cycle == 338 || cycle == 340) {
        backgroundNextTileId = ppuRead(0x2000 | (vramAddress.reg & 0x0FFF));
      }

      if (scanline == -1 && cycle >= 280 && cycle < 305) {
        transferAddressY();
      }

      if (cycle == 257 && scanline >= 0) {
        for (var i = 0; i < spriteScanline.length; i++) {
          spriteScanline[i] = ObjectAttributeEntry();
        }
        spriteCount = 0;

        for (var i = 0; i < 8; i++) {
          spriteShifterPatternLow[i] = 0;
          spriteShifterPatternHigh[i] = 0;
        }

        var nOAMEntry = 0;
        spriteZeroHitPossible = false;
        while (nOAMEntry < 64 && spriteCount < 8) {
          final diff = scanline - pOAM[nOAMEntry * 4];
          if (diff >= 0 && diff < (control.spriteSize ? 16 : 8)) {
            if (nOAMEntry == 0) {
              spriteZeroHitPossible = true;
            }

            spriteScanline[spriteCount].y = pOAM[nOAMEntry * 4];
            spriteScanline[spriteCount].id = pOAM[nOAMEntry * 4 + 1];
            spriteScanline[spriteCount].attribute = pOAM[nOAMEntry * 4 + 2];
            spriteScanline[spriteCount].x = pOAM[nOAMEntry * 4 + 3];
            spriteCount++;
          }
          nOAMEntry++;
        }

        while (nOAMEntry < 64) {
          final diff = scanline - pOAM[nOAMEntry * 4];
          if (diff >= 0 && diff < (control.spriteSize ? 16 : 8)) {
            status.spriteOverflow = true;
            break;
          }
          nOAMEntry++;
        }
      }

      if (cycle == 340) {
        for (var i = 0; i < spriteCount; i++) {
          int spritePatternBitsLow;
          int spritePatternBitsHigh;
          int spritePatternAddrLow;
          int spritePatternAddrHigh;

          if (!control.spriteSize) {
            if ((spriteScanline[i].attribute & 0x80) == 0) {
              spritePatternAddrLow = (control.patternSprite << 12) |
                  (spriteScanline[i].id << 4) |
                  (scanline - spriteScanline[i].y);
            } else {
              spritePatternAddrLow = (control.patternSprite << 12) |
                  (spriteScanline[i].id << 4) |
                  (7 - (scanline - spriteScanline[i].y));
            }
          } else {
            if ((spriteScanline[i].attribute & 0x80) == 0) {
              if (scanline - spriteScanline[i].y < 8) {
                spritePatternAddrLow = ((spriteScanline[i].id & 0x01) << 12) |
                    ((spriteScanline[i].id & 0xFE) << 4) |
                    ((scanline - spriteScanline[i].y) & 0x07);
              } else {
                spritePatternAddrLow = ((spriteScanline[i].id & 0x01) << 12) |
                    (((spriteScanline[i].id & 0xFE) + 1) << 4) |
                    ((scanline - spriteScanline[i].y) & 0x07);
              }
            } else {
              if (scanline - spriteScanline[i].y < 8) {
                spritePatternAddrLow = ((spriteScanline[i].id & 0x01) << 12) |
                    (((spriteScanline[i].id & 0xFE) + 1) << 4) |
                    ((7 - (scanline - spriteScanline[i].y)) & 0x07);
              } else {
                spritePatternAddrLow = ((spriteScanline[i].id & 0x01) << 12) |
                    ((spriteScanline[i].id & 0xFE) << 4) |
                    ((7 - (scanline - spriteScanline[i].y)) & 0x07);
              }
            }
          }

          spritePatternAddrHigh = spritePatternAddrLow + 8;
          spritePatternBitsLow = ppuRead(spritePatternAddrLow);
          spritePatternBitsHigh = ppuRead(spritePatternAddrHigh);

          if ((spriteScanline[i].attribute & 0x40) != 0) {
            spritePatternBitsLow = ((spritePatternBitsLow & 0xF0) >> 4) |
                ((spritePatternBitsLow & 0x0F) << 4);
            spritePatternBitsLow = ((spritePatternBitsLow & 0xCC) >> 2) |
                ((spritePatternBitsLow & 0x33) << 2);
            spritePatternBitsLow = ((spritePatternBitsLow & 0xAA) >> 1) |
                ((spritePatternBitsLow & 0x55) << 1);

            spritePatternBitsHigh = ((spritePatternBitsHigh & 0xF0) >> 4) |
                ((spritePatternBitsHigh & 0x0F) << 4);
            spritePatternBitsHigh = ((spritePatternBitsHigh & 0xCC) >> 2) |
                ((spritePatternBitsHigh & 0x33) << 2);
            spritePatternBitsHigh = ((spritePatternBitsHigh & 0xAA) >> 1) |
                ((spritePatternBitsHigh & 0x55) << 1);
          }

          spriteShifterPatternLow[i] = spritePatternBitsLow;
          spriteShifterPatternHigh[i] = spritePatternBitsHigh;
        }
      }
    }

    if (scanline >= 241 && scanline < 261) {
      if (scanline == 241 && cycle == 1) {
        status.verticalBlank = true;
        if (control.enableNmi) {
          nmi = true;
        }
      }
    }

    var backgroundPixel = 0x00;
    var backgroundPalette = 0x00;

    if (mask.renderBackground) {
      if (mask.renderBackgroundLeft || (cycle >= 9)) {
        final bitMux = 0x8000 >> fineX;

        final p0Pixel = (backgroundShifterPatternLow & bitMux) > 0 ? 1 : 0;
        final p1Pixel = (backgroundShifterPatternHigh & bitMux) > 0 ? 1 : 0;
        backgroundPixel = (p1Pixel << 1) | p0Pixel;

        final backgroundPal0 =
            (backgroundShifterAttribLow & bitMux) > 0 ? 1 : 0;
        final backgroundPal1 =
            (backgroundShifterAttribHigh & bitMux) > 0 ? 1 : 0;
        backgroundPalette = (backgroundPal1 << 1) | backgroundPal0;
      }
    }

    var fgPixel = 0x00;
    var fgPalette = 0x00;
    var fgPriority = 0x00;

    if (mask.renderSprites) {
      if (mask.renderSpritesLeft || (cycle >= 9)) {
        spriteZeroBeingRendered = false;

        for (var i = 0; i < spriteCount; i++) {
          if (spriteScanline[i].x == 0) {
            final fgPixelLow = (spriteShifterPatternLow[i] & 0x80) > 0 ? 1 : 0;
            final fgPixelHigh =
                (spriteShifterPatternHigh[i] & 0x80) > 0 ? 1 : 0;
            fgPixel = (fgPixelHigh << 1) | fgPixelLow;

            fgPalette = (spriteScanline[i].attribute & 0x03) + 0x04;
            fgPriority = (spriteScanline[i].attribute & 0x20) == 0 ? 1 : 0;

            if (fgPixel != 0) {
              if (i == 0) {
                spriteZeroBeingRendered = true;
              }
              break;
            }
          }
        }
      }
    }

    if (backgroundPixel != 0 && fgPixel != 0) {
      if (mask.renderBackground && mask.renderSprites) {
        if (mask.renderBackgroundLeft && mask.renderSpritesLeft) {
          if (cycle >= 1 && cycle < 258) {
            if (spriteZeroHitPossible && spriteZeroBeingRendered) {
              status.spriteZeroHit = true;
            }
          }
        } else {
          if (cycle >= 9 && cycle < 258) {
            if (spriteZeroHitPossible && spriteZeroBeingRendered) {
              status.spriteZeroHit = true;
            }
          }
        }
      }
    }

    var pixel = 0x00;
    var palette = 0x00;

    if (backgroundPixel == 0 && fgPixel == 0) {
      pixel = 0x00;
      palette = 0x00;
    } else if (backgroundPixel == 0 && fgPixel > 0) {
      pixel = fgPixel;
      palette = fgPalette;
    } else if (backgroundPixel > 0 && fgPixel == 0) {
      pixel = backgroundPixel;
      palette = backgroundPalette;
    } else if (backgroundPixel > 0 && fgPixel > 0) {
      if (fgPriority != 0) {
        pixel = fgPixel;
        palette = fgPalette;
      } else {
        pixel = backgroundPixel;
        palette = backgroundPalette;
      }
    }

    final colorIndex = ppuRead(0x3F00 + (palette << 2) + pixel) & 0x3F;

    if (scanline >= 0 && scanline < 240 && cycle >= 1 && cycle < 257) {
      screenPixels[scanline][cycle - 1] = colorIndex;
    }

    cycle++;
    if (cycle >= 341) {
      cycle = 0;
      scanline++;
      if (scanline >= 261) {
        scanline = -1;
        frameComplete = true;
        frameCounter++;
      }
    }
  }

  int oamAddress = 0x00;
}

class PPUStatus {
  int reg = 0x00;

  bool get unused => (reg & 0x1F) != 0;
  set unused(bool value) => reg = value ? (reg | 0x1F) : (reg & ~0x1F);

  bool get spriteOverflow => (reg & 0x20) != 0;
  set spriteOverflow(bool value) => reg = value ? (reg | 0x20) : (reg & ~0x20);

  bool get spriteZeroHit => (reg & 0x40) != 0;
  set spriteZeroHit(bool value) => reg = value ? (reg | 0x40) : (reg & ~0x40);

  bool get verticalBlank => (reg & 0x80) != 0;
  set verticalBlank(bool value) => reg = value ? (reg | 0x80) : (reg & ~0x80);
}

class PPUMask {
  int reg = 0x00;

  bool get grayscale => (reg & 0x01) != 0;
  set grayscale(bool value) => reg = value ? (reg | 0x01) : (reg & ~0x01);

  bool get renderBackgroundLeft => (reg & 0x02) != 0;
  set renderBackgroundLeft(bool value) =>
      reg = value ? (reg | 0x02) : (reg & ~0x02);

  bool get renderSpritesLeft => (reg & 0x04) != 0;
  set renderSpritesLeft(bool value) =>
      reg = value ? (reg | 0x04) : (reg & ~0x04);

  bool get renderBackground => (reg & 0x08) != 0;
  set renderBackground(bool value) =>
      reg = value ? (reg | 0x08) : (reg & ~0x08);

  bool get renderSprites => (reg & 0x10) != 0;
  set renderSprites(bool value) => reg = value ? (reg | 0x10) : (reg & ~0x10);

  bool get enhanceRed => (reg & 0x20) != 0;
  set enhanceRed(bool value) => reg = value ? (reg | 0x20) : (reg & ~0x20);

  bool get enhanceGreen => (reg & 0x40) != 0;
  set enhanceGreen(bool value) => reg = value ? (reg | 0x40) : (reg & ~0x40);

  bool get enhanceBlue => (reg & 0x80) != 0;
  set enhanceBlue(bool value) => reg = value ? (reg | 0x80) : (reg & ~0x80);
}

class PPUControl {
  int reg = 0x00;

  int get nametableX => reg & 0x01;
  set nametableX(int value) => reg = (reg & ~0x01) | (value & 0x01);

  int get nametableY => (reg & 0x02) >> 1;
  set nametableY(int value) => reg = (reg & ~0x02) | ((value & 0x01) << 1);

  bool get incrementMode => (reg & 0x04) != 0;
  set incrementMode(bool value) => reg = value ? (reg | 0x04) : (reg & ~0x04);

  int get patternSprite => (reg & 0x08) >> 3;
  set patternSprite(int value) => reg = (reg & ~0x08) | ((value & 0x01) << 3);

  int get patternBackground => (reg & 0x10) >> 4;
  set patternBackground(int value) =>
      reg = (reg & ~0x10) | ((value & 0x01) << 4);

  bool get spriteSize => (reg & 0x20) != 0;
  set spriteSize(bool value) => reg = value ? (reg | 0x20) : (reg & ~0x20);

  bool get slaveMode => (reg & 0x40) != 0;
  set slaveMode(bool value) => reg = value ? (reg | 0x40) : (reg & ~0x40);

  bool get enableNmi => (reg & 0x80) != 0;
  set enableNmi(bool value) => reg = value ? (reg | 0x80) : (reg & ~0x80);
}

class LoopyRegister {
  int reg = 0x0000;

  int get coarseX => reg & 0x001F;
  set coarseX(int value) => reg = (reg & ~0x001F) | (value & 0x001F);

  int get coarseY => (reg & 0x03E0) >> 5;
  set coarseY(int value) => reg = (reg & ~0x03E0) | ((value & 0x001F) << 5);

  int get nametableX => (reg & 0x0400) >> 10;
  set nametableX(int value) => reg = (reg & ~0x0400) | ((value & 0x0001) << 10);

  int get nametableY => (reg & 0x0800) >> 11;
  set nametableY(int value) => reg = (reg & ~0x0800) | ((value & 0x0001) << 11);

  int get fineY => (reg & 0x7000) >> 12;
  set fineY(int value) => reg = (reg & ~0x7000) | ((value & 0x0007) << 12);
}

class ObjectAttributeEntry {
  int y = 0;
  int id = 0;
  int attribute = 0;
  int x = 0;
}
