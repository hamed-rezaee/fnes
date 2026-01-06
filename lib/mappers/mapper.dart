enum MapperMirror {
  hardware,
  horizontal,
  vertical,
  oneScreenLow,
  oneScreenHigh,
  fourScreen,
}

abstract class Mapper {
  Mapper(this.programBankCount, this.totalCharBanks) {
    _initializeBanking();
    reset();
  }

  static const int chr0000 = 0;
  static const int chr0400 = 1;
  static const int chr0800 = 2;
  static const int chr0c00 = 3;
  static const int chr1000 = 4;
  static const int chr1400 = 5;
  static const int chr1800 = 6;
  static const int chr1c00 = 7;

  static const int prg8000 = 0;
  static const int prgA000 = 1;
  static const int prgC000 = 2;
  static const int prgE000 = 3;

  int programBankCount = 0;
  int totalCharBanks = 0;
  int prgRomPageCount8k = 0;
  int prgRomPageCount16k = 0;
  int prgRomPageCount32k = 0;
  int chrRomPageCount1k = 0;
  int chrRomPageCount2k = 0;
  int chrRomPageCount4k = 0;

  final List<int> prgBank = List<int>.filled(4, 0);
  final List<int> chrBank = List<int>.filled(8, 0);
  final List<int> patternBank = List<int>.filled(8, 0);

  int mirroringMode = 0;
  bool hasSram = false;
  bool writeProtectSram = false;
  bool chrRam = false;
  int submapper = 0;

  late List<int> prgRomData;
  late List<int> chrRomData;

  String get name;

  void _initializeBanking() {
    prgRomPageCount8k = programBankCount * 2;
    prgRomPageCount16k = programBankCount;
    prgRomPageCount32k = programBankCount ~/ 2;

    chrRomPageCount1k = totalCharBanks * 8;
    chrRomPageCount2k = totalCharBanks * 4;
    chrRomPageCount4k = totalCharBanks * 2;
  }

  int? cpuMapRead(int address, [void Function(int data)? setData]);

  int? cpuMapWrite(int address, int data, [int cycles = 0]);

  int? ppuMapRead(int address, [void Function(int data)? setData]);

  int? ppuMapWrite(int address);

  void reset() {}

  MapperMirror mirror() => MapperMirror.hardware;

  bool irqState() => false;

  void irqClear() {}

  void scanline(int row) {}

  void ppuWriteNotify(int address, int data) {}

  void clock(int cycles) {}

  void setPrgBank8k(int bank, int value) {
    if (bank >= 0 && bank < 4) {
      prgBank[bank] = value % prgRomPageCount8k;
    }
  }

  void setPrgBank16k(int bank, int value) {
    if (bank >= 0 && bank < 2) {
      final base = bank * 2;
      prgBank[base] = (value * 2) % prgRomPageCount8k;
      prgBank[base + 1] = ((value * 2) + 1) % prgRomPageCount8k;
    }
  }

  void setPrgBank32k(int value) {
    prgBank[0] = (value * 4) % prgRomPageCount8k;
    prgBank[1] = ((value * 4) + 1) % prgRomPageCount8k;
    prgBank[2] = ((value * 4) + 2) % prgRomPageCount8k;
    prgBank[3] = ((value * 4) + 3) % prgRomPageCount8k;
  }

  void setChrBank1k(int bank, int value) {
    if (bank >= 0 && bank < 8) {
      chrBank[bank] = value % chrRomPageCount1k;
      patternBank[bank] = chrBank[bank];
    }
  }

  void setChrBank2k(int bank, int value) {
    if (bank >= 0 && bank < 4) {
      final base = bank * 2;
      chrBank[base] = (value * 2) % chrRomPageCount1k;
      chrBank[base + 1] = ((value * 2) + 1) % chrRomPageCount1k;
      patternBank[base] = chrBank[base];
      patternBank[base + 1] = chrBank[base + 1];
    }
  }

  void setChrBank4k(int bank, int value) {
    if (bank >= 0 && bank < 2) {
      final base = bank * 4;
      for (var i = 0; i < 4; i++) {
        chrBank[base + i] = ((value * 4) + i) % chrRomPageCount1k;
        patternBank[base + i] = chrBank[base + i];
      }
    }
  }

  void setChrBank8k(int value) {
    for (var i = 0; i < 8; i++) {
      chrBank[i] = ((value * 8) + i) % chrRomPageCount1k;
      patternBank[i] = chrBank[i];
    }
  }

  void setMirroring(int mode) => mirroringMode = mode;

  int readChr(int address) => 0;

  void writeChr(int address, int value) {}

  void setPrgRomData(List<int> data) => prgRomData = data;

  void setChrRomData(List<int> data) => chrRomData = data;

  Map<String, dynamic> saveState() => {};

  void restoreState(Map<String, dynamic> state) {}
}
