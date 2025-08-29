import 'package:equatable/equatable.dart';

enum MemoryRegion {
  zeroPage('Zero Page (0x0000 - 0x00FF)'),
  stack('Stack (0x0100 - 0x01FF)'),
  programRom('Program ROM (0x8000 - 0x80FF)');

  const MemoryRegion(this.title);

  final String title;
}

class MemoryDebugViewState extends Equatable {
  const MemoryDebugViewState({this.selectedRegion = MemoryRegion.zeroPage});

  final MemoryRegion selectedRegion;

  @override
  List<Object> get props => [selectedRegion];
}
