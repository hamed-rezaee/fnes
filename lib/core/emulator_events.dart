import 'dart:ui';

import 'package:fnes/components/cartridge.dart';
import 'package:fnes/components/emulator_state.dart';
import 'package:fnes/core/event.dart';

abstract class ROMEvent extends Event {
  ROMEvent({super.timestamp});
}

class ROMLoadedEvent extends ROMEvent {
  ROMLoadedEvent({
    required this.romName,
    required this.cartridge,
    required this.mapper,
    super.timestamp,
  });

  final String romName;
  final Cartridge cartridge;
  final int mapper;

  @override
  String toString() => 'ROMLoadedEvent(name: $romName, mapper: $mapper)';
}

class ROMLoadFailedEvent extends ROMEvent {
  ROMLoadFailedEvent({
    required this.error,
    required this.fileName,
    super.timestamp,
  });

  final String error;
  final String? fileName;

  @override
  String toString() => 'ROMLoadFailedEvent(error: $error)';
}

class ROMEjectedEvent extends ROMEvent {
  ROMEjectedEvent({required this.romName, super.timestamp});

  final String romName;

  @override
  String toString() => 'ROMEjectedEvent(name: $romName)';
}

abstract class EmulationEvent extends Event {
  EmulationEvent({super.timestamp});
}

class EmulationStartedEvent extends EmulationEvent {
  EmulationStartedEvent({super.timestamp});

  @override
  String toString() => 'EmulationStartedEvent()';
}

class EmulationPausedEvent extends EmulationEvent {
  EmulationPausedEvent({super.timestamp});

  @override
  String toString() => 'EmulationPausedEvent()';
}

class EmulationResumedEvent extends EmulationEvent {
  EmulationResumedEvent({super.timestamp});

  @override
  String toString() => 'EmulationResumedEvent()';
}

class EmulationStoppedEvent extends EmulationEvent {
  EmulationStoppedEvent({super.timestamp});

  @override
  String toString() => 'EmulationStoppedEvent()';
}

class EmulationResetEvent extends EmulationEvent {
  EmulationResetEvent({required this.hardReset, super.timestamp});

  final bool hardReset;

  @override
  String toString() => 'EmulationResetEvent(hard: $hardReset)';
}

class SystemTypeChangedEvent extends EmulationEvent {
  SystemTypeChangedEvent({
    required this.isPal,
    required this.targetFps,
    super.timestamp,
  });

  final bool isPal;
  final double targetFps;

  @override
  String toString() => 'SystemTypeChangedEvent(PAL: $isPal, fps: $targetFps)';
}

abstract class RenderEvent extends Event {
  RenderEvent({super.timestamp});
}

class FrameRenderedEvent extends RenderEvent {
  FrameRenderedEvent({
    required this.frameNumber,
    required this.fps,
    required this.renderTimeMs,
    super.timestamp,
  });

  final int frameNumber;
  final double fps;
  final double renderTimeMs;

  @override
  String toString() =>
      'FrameRenderedEvent(frame: $frameNumber, fps: ${fps.toStringAsFixed(1)})';
}

class ScreenImageUpdatedEvent extends RenderEvent {
  ScreenImageUpdatedEvent({required this.image, super.timestamp});

  final Image image;

  @override
  String toString() => 'ScreenImageUpdatedEvent()';
}

class VBlankStartedEvent extends RenderEvent {
  VBlankStartedEvent({required this.frameNumber, super.timestamp});

  final int frameNumber;

  @override
  String toString() => 'VBlankStartedEvent(frame: $frameNumber)';
}

class VBlankEndedEvent extends RenderEvent {
  VBlankEndedEvent({required this.frameNumber, super.timestamp});

  final int frameNumber;

  @override
  String toString() => 'VBlankEndedEvent(frame: $frameNumber)';
}

class RenderModeChangedEvent extends RenderEvent {
  RenderModeChangedEvent({required this.mode, super.timestamp});

  final String mode;

  @override
  String toString() => 'RenderModeChangedEvent(mode: $mode)';
}

abstract class CPUEvent extends Event {
  CPUEvent({super.timestamp});
}

class CPUInstructionExecutedEvent extends CPUEvent {
  CPUInstructionExecutedEvent({
    required this.opcode,
    required this.mnemonic,
    required this.address,
    required this.cycles,
    super.timestamp,
  });

  final int opcode;
  final String mnemonic;
  final int address;
  final int cycles;

  @override
  String toString() =>
      'CPUInstructionExecutedEvent(0x${address.toRadixString(16)}: $mnemonic)';
}

class CPUInterruptEvent extends CPUEvent {
  CPUInterruptEvent({
    required this.type,
    required this.vector,
    super.timestamp,
  });

  @override
  final String type;
  final int vector;

  @override
  String toString() =>
      'CPUInterruptEvent(type: $type, vector: 0x${vector.toRadixString(16)})';
}

class CPUStateChangedEvent extends CPUEvent {
  CPUStateChangedEvent({
    required this.pc,
    required this.a,
    required this.x,
    required this.y,
    required this.status,
    super.timestamp,
  });

  final int pc;
  final int a;
  final int x;
  final int y;
  final int status;

  @override
  String toString() =>
      'CPUStateChangedEvent(PC: 0x${pc.toRadixString(16)}, A: 0x${a.toRadixString(16)})';
}

abstract class PPUEvent extends Event {
  PPUEvent({super.timestamp});
}

class PPUScanlineEvent extends PPUEvent {
  PPUScanlineEvent({
    required this.scanline,
    required this.cycle,
    super.timestamp,
  });

  final int scanline;
  final int cycle;

  @override
  String toString() => 'PPUScanlineEvent(line: $scanline, cycle: $cycle)';
}

class PPUSpriteEvaluationEvent extends PPUEvent {
  PPUSpriteEvaluationEvent({
    required this.spriteCount,
    required this.sprite0Hit,
    super.timestamp,
  });

  final int spriteCount;
  final bool sprite0Hit;

  @override
  String toString() =>
      'PPUSpriteEvaluationEvent(count: $spriteCount, sprite0: $sprite0Hit)';
}

class PPURegisterAccessEvent extends PPUEvent {
  PPURegisterAccessEvent({
    required this.register,
    required this.value,
    required this.isWrite,
    super.timestamp,
  });

  final int register;
  final int value;
  final bool isWrite;

  @override
  String toString() =>
      'PPURegisterAccessEvent(reg: 0x${register.toRadixString(16)}, ${isWrite ? "write" : "read"}: 0x${value.toRadixString(16)})';
}

abstract class AudioEvent extends Event {
  AudioEvent({super.timestamp});
}

class AudioBufferFilledEvent extends AudioEvent {
  AudioBufferFilledEvent({
    required this.sampleCount,
    required this.bufferSize,
    super.timestamp,
  });

  final int sampleCount;
  final int bufferSize;

  @override
  String toString() =>
      'AudioBufferFilledEvent(samples: $sampleCount, buffer: $bufferSize)';
}

class APUChannelChangedEvent extends AudioEvent {
  APUChannelChangedEvent({
    required this.channel,
    required this.enabled,
    required this.frequency,
    super.timestamp,
  });

  final String channel;
  final bool enabled;
  final double frequency;

  @override
  String toString() =>
      'APUChannelChangedEvent(channel: $channel, enabled: $enabled, freq: ${frequency.toStringAsFixed(2)})';
}

class AudioMuteChangedEvent extends AudioEvent {
  AudioMuteChangedEvent({required this.isMuted, super.timestamp});

  final bool isMuted;

  @override
  String toString() => 'AudioMuteChangedEvent(muted: $isMuted)';
}

abstract class MemoryEvent extends Event {
  MemoryEvent({super.timestamp});
}

class MemoryReadEvent extends MemoryEvent {
  MemoryReadEvent({
    required this.address,
    required this.value,
    super.timestamp,
  });

  final int address;
  final int value;

  @override
  String toString() =>
      'MemoryReadEvent(addr: 0x${address.toRadixString(16)}, value: 0x${value.toRadixString(16)})';
}

class MemoryWriteEvent extends MemoryEvent {
  MemoryWriteEvent({
    required this.address,
    required this.value,
    super.timestamp,
  });

  final int address;
  final int value;

  @override
  String toString() =>
      'MemoryWriteEvent(addr: 0x${address.toRadixString(16)}, value: 0x${value.toRadixString(16)})';
}

class DMATransferEvent extends MemoryEvent {
  DMATransferEvent({
    required this.page,
    required this.bytesTransferred,
    super.timestamp,
  });

  final int page;
  final int bytesTransferred;

  @override
  String toString() =>
      'DMATransferEvent(page: 0x${page.toRadixString(16)}, bytes: $bytesTransferred)';
}

class MapperSwitchedEvent extends MemoryEvent {
  MapperSwitchedEvent({
    required this.mapperId,
    required this.bank,
    super.timestamp,
  });

  final int mapperId;
  final int bank;

  @override
  String toString() => 'MapperSwitchedEvent(mapper: $mapperId, bank: $bank)';
}

abstract class InputEvent extends Event {
  InputEvent({super.timestamp});
}

class ControllerButtonPressedEvent extends InputEvent {
  ControllerButtonPressedEvent({
    required this.controller,
    required this.button,
    super.timestamp,
  });

  final int controller;
  final String button;

  @override
  String toString() =>
      'ControllerButtonPressedEvent(controller: $controller, button: $button)';
}

class ControllerButtonReleasedEvent extends InputEvent {
  ControllerButtonReleasedEvent({
    required this.controller,
    required this.button,
    super.timestamp,
  });

  final int controller;
  final String button;

  @override
  String toString() =>
      'ControllerButtonReleasedEvent(controller: $controller, button: $button)';
}

class ZapperTriggerEvent extends InputEvent {
  ZapperTriggerEvent({
    required this.x,
    required this.y,
    required this.hit,
    super.timestamp,
  });

  final double x;
  final double y;
  final bool hit;

  @override
  String toString() =>
      'ZapperTriggerEvent(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, hit: $hit)';
}

abstract class SaveStateEvent extends Event {
  SaveStateEvent({super.timestamp});
}

class SaveStateCreatedEvent extends SaveStateEvent {
  SaveStateCreatedEvent({
    required this.stateName,
    required this.state,
    super.timestamp,
  });

  final String stateName;
  final EmulatorState state;

  @override
  String toString() => 'SaveStateCreatedEvent(name: $stateName)';
}

class SaveStateLoadedEvent extends SaveStateEvent {
  SaveStateLoadedEvent({
    required this.stateName,
    required this.state,
    super.timestamp,
  });

  final String stateName;
  final EmulatorState state;

  @override
  String toString() => 'SaveStateLoadedEvent(name: $stateName)';
}

class SaveStateFailedEvent extends SaveStateEvent {
  SaveStateFailedEvent({
    required this.operation,
    required this.error,
    super.timestamp,
  });

  final String operation;
  final String error;

  @override
  String toString() => 'SaveStateFailedEvent(op: $operation, error: $error)';
}

class RewindActivatedEvent extends SaveStateEvent {
  RewindActivatedEvent({required this.framesBack, super.timestamp});

  final int framesBack;

  @override
  String toString() => 'RewindActivatedEvent(frames: $framesBack)';
}

abstract class CheatEvent extends Event {
  CheatEvent({super.timestamp});
}

class CheatEnabledEvent extends CheatEvent {
  CheatEnabledEvent({
    required this.cheatCode,
    required this.description,
    super.timestamp,
  });

  final String cheatCode;
  final String description;

  @override
  String toString() => 'CheatEnabledEvent(code: $cheatCode)';
}

class CheatDisabledEvent extends CheatEvent {
  CheatDisabledEvent({required this.cheatCode, super.timestamp});

  final String cheatCode;

  @override
  String toString() => 'CheatDisabledEvent(code: $cheatCode)';
}

class CheatsAppliedEvent extends CheatEvent {
  CheatsAppliedEvent({required this.count, super.timestamp});

  final int count;

  @override
  String toString() => 'CheatsAppliedEvent(count: $count)';
}

abstract class DebugEvent extends Event {
  DebugEvent({super.timestamp});
}

class BreakpointHitEvent extends DebugEvent {
  BreakpointHitEvent({
    required this.type,
    required this.address,
    super.timestamp,
  });

  @override
  final String type;
  final int address;

  @override
  String toString() =>
      'BreakpointHitEvent(addr: 0x${address.toRadixString(16)}, type: $type)';
}

class WatchpointTriggeredEvent extends DebugEvent {
  WatchpointTriggeredEvent({
    required this.address,
    required this.oldValue,
    required this.newValue,
    super.timestamp,
  });

  final int address;
  final int oldValue;
  final int newValue;

  @override
  String toString() =>
      'WatchpointTriggeredEvent(addr: 0x${address.toRadixString(16)}, 0x${oldValue.toRadixString(16)} -> 0x${newValue.toRadixString(16)})';
}

class DebugModeChangedEvent extends DebugEvent {
  DebugModeChangedEvent({required this.enabled, super.timestamp});

  final bool enabled;

  @override
  String toString() => 'DebugModeChangedEvent(enabled: $enabled)';
}

class PerformanceMetricsEvent extends DebugEvent {
  PerformanceMetricsEvent({
    required this.fps,
    required this.frameTimeMs,
    required this.cpuTimeMs,
    required this.ppuTimeMs,
    required this.apuTimeMs,
    super.timestamp,
  });

  final double fps;
  final double frameTimeMs;
  final double cpuTimeMs;
  final double ppuTimeMs;
  final double apuTimeMs;

  @override
  String toString() =>
      'PerformanceMetricsEvent(fps: ${fps.toStringAsFixed(1)}, frame: ${frameTimeMs.toStringAsFixed(2)}ms)';
}

abstract class ErrorEvent extends Event {
  ErrorEvent({super.timestamp});
}

class EmulatorErrorEvent extends ErrorEvent {
  EmulatorErrorEvent({
    required this.message,
    required this.component,
    this.stackTrace,
    super.timestamp,
  });

  final String message;
  final String component;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'EmulatorErrorEvent(component: $component, message: $message)';
}

class EmulatorWarningEvent extends ErrorEvent {
  EmulatorWarningEvent({
    required this.message,
    required this.component,
    super.timestamp,
  });

  final String message;
  final String component;

  @override
  String toString() =>
      'EmulatorWarningEvent(component: $component, message: $message)';
}
