import 'package:signals/signals_flutter.dart';

enum MemoryRegion {
  zeroPage('Zero Page (0x0000 - 0x00FF)'),
  stack('Stack (0x0100 - 0x01FF)'),
  programRom('Program ROM (0x8000 - 0x80FF)');

  const MemoryRegion(this.title);

  final String title;
}

class MemoryDebugViewController {
  final Signal<MemoryRegion> selectedRegion = signal(MemoryRegion.zeroPage);

  void selectRegion(MemoryRegion region) => selectedRegion.value = region;
}
