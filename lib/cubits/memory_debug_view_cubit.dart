import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/cubits/memory_debug_view_state.dart';

class MemoryDebugViewCubit extends Cubit<MemoryDebugViewState> {
  MemoryDebugViewCubit() : super(const MemoryDebugViewState());

  MemoryRegion get selectedRegion => state.selectedRegion;

  void selectRegion(MemoryRegion region) =>
      emit(MemoryDebugViewState(selectedRegion: region));
}
