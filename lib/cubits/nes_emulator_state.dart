import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';

abstract class NESEmulatorState extends Equatable {
  const NESEmulatorState();

  @override
  List<Object?> get props => [];
}

class NESEmulatorInitial extends NESEmulatorState {
  const NESEmulatorInitial();
}

class NESEmulatorLoadingROM extends NESEmulatorState {
  const NESEmulatorLoadingROM();
}

class NESEmulatorROMLoaded extends NESEmulatorState {
  const NESEmulatorROMLoaded({required this.fileName});

  final String fileName;

  @override
  List<Object?> get props => [fileName];
}

class NESEmulatorRunning extends NESEmulatorState {
  const NESEmulatorRunning({
    required this.currentFPS,
    required this.frameCount,
  });

  final double currentFPS;
  final int frameCount;

  @override
  List<Object?> get props => [currentFPS, frameCount];
}

class NESEmulatorPaused extends NESEmulatorState {
  const NESEmulatorPaused();
}

class NESEmulatorStepped extends NESEmulatorState {
  const NESEmulatorStepped();
}

class NESEmulatorError extends NESEmulatorState {
  const NESEmulatorError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class NESEmulatorFilterQualityChanged extends NESEmulatorState {
  const NESEmulatorFilterQualityChanged({required this.filterQuality});

  final FilterQuality filterQuality;

  @override
  List<Object?> get props => [filterQuality];
}

class NESEmulatorFrameUpdated extends NESEmulatorState {
  const NESEmulatorFrameUpdated({
    required this.currentFPS,
    required this.frameCount,
  });

  final double currentFPS;
  final int frameCount;

  @override
  List<Object?> get props => [currentFPS, frameCount];
}

class NESEmulatorDebuggerToggled extends NESEmulatorState {
  const NESEmulatorDebuggerToggled({required this.isDebuggerVisible});

  final bool isDebuggerVisible;

  @override
  List<Object?> get props => [isDebuggerVisible];
}

class NESEmulatorOnScreenControllerToggled extends NESEmulatorState {
  const NESEmulatorOnScreenControllerToggled({
    required this.isOnScreenControllerVisible,
  });

  final bool isOnScreenControllerVisible;

  @override
  List<Object?> get props => [isOnScreenControllerVisible];
}
