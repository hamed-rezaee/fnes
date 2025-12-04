enum MapperMirror {
  hardware,
  horizontal,
  vertical,
  oneScreenLow,
  oneScreenHigh,
}

abstract class Mapper {
  Mapper(this.programBankCount, this.totalCharBanks) {
    reset();
  }

  int programBankCount = 0;

  int totalCharBanks = 0;

  String get name;

  int? cpuMapRead(int address, [void Function(int data)? setData]);

  int? cpuMapWrite(int address, int data);

  int? ppuMapRead(int address);

  int? ppuMapWrite(int address);

  void reset() {}

  MapperMirror mirror() => MapperMirror.hardware;

  bool irqState() => false;

  void irqClear() {}

  void scanline() {}

  void ppuWriteNotify(int address, int data) {}

  Map<String, dynamic> saveState() => {};

  void restoreState(Map<String, dynamic> state) {}
}
