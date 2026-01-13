import 'dart:typed_data';

import 'package:fnes/components/apu.dart';
import 'package:fnes/components/cartridge.dart';
import 'package:fnes/components/cheat_engine.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/components/emulator_state.dart';
import 'package:fnes/components/ppu.dart';
import 'package:fnes/components/zapper.dart';
import 'package:fnes/core/emulator_events.dart';
import 'package:fnes/core/event.dart';

class Bus {
  Bus({
    required this.cpu,
    required this.ppu,
    required this.apu,
    required this.zapper,
    required this.cheatEngine,
  }) {
    cpu.connect(this);

    apu.dmcMemoryRead = (int address) => cpuRead(address, readOnly: true);
  }

  final CPU cpu;
  final PPU ppu;
  final APU apu;
  final Zapper zapper;
  final CheatEngine cheatEngine;
  Cartridge? cart;

  EventBus? get eventBus => _eventBus;
  EventBus? _eventBus;

  set eventBus(EventBus? bus) {
    _eventBus = bus;
    ppu.eventBus = bus;
    apu.eventBus = bus;
  }

  final Uint8List controller = Uint8List(2);
  final Uint8List _cpuRam = Uint8List(2048);

  double _audioSample = 0;
  double _audioTime = 0;
  double _audioTimePerNESClock = 0;
  double _audioTimePerSystemSample = 0;
  final Float64List _audioBuffer = Float64List(_audioBufferSize);
  static const int _audioBufferSize = 1024;
  int _audioBufferIndex = 0;
  int _audioBufferCount = 0;

  int _systemClockCounter = 0;
  int _cpuClockCounter = 0;
  double _cpuClockAccumulator = 0;
  bool _isPal = false;

  final Uint8List _controllerState = Uint8List(2);

  int _dmaPage = 0x00;
  int _dmaAddress = 0x00;
  int _dmaData = 0x00;
  bool _dmaDummy = true;
  bool _dmaTransfer = false;

  void setSystemType({required bool isPal}) {
    _isPal = isPal;
    ppu.setSystemType(isPal: isPal);
    apu.setSystemType(isPal: isPal);

    final clockFreq = isPal ? 5320342.0 : 5369318.0;

    _audioTimePerNESClock = 1.0 / clockFreq;
  }

  void setSampleFrequency(int sampleRate) {
    _audioTimePerSystemSample = 1 / sampleRate;

    if (_audioTimePerNESClock == 0) _audioTimePerNESClock = 1 / 5369318.0;
  }

  @pragma('vm:prefer-inline')
  void cpuWrite(int address, int data) {
    if (cart?.cpuWrite(address, data, _systemClockCounter) ?? false) return;

    if (address >= 0x0000 && address <= 0x1FFF) {
      _cpuRam[address & 0x07FF] = data;
    } else if (address >= 0x2000 && address <= 0x3FFF) {
      ppu.cpuWrite(address & 0x0007, data);
    } else if ((address >= 0x4000 && address <= 0x4013) ||
        address == 0x4015 ||
        address == 0x4017) {
      apu.cpuWrite(address, data);
    } else if (address == 0x4014) {
      _dmaPage = data;
      _dmaAddress = 0x00;
      _dmaTransfer = true;

      eventBus?.dispatch(DMATransferEvent(page: data, bytesTransferred: 256));
    } else if (address >= 0x4016 && address <= 0x4017) {
      if ((data & 0x01) == 0) {
        _controllerState[address & 0x0001] = controller[address & 0x0001];
      }
    }
  }

  @pragma('vm:prefer-inline')
  int cpuRead(int address, {bool readOnly = false}) {
    var data = 0x00;

    if (cart?.cpuRead(address, (v) => data = v) ?? false) {
      return cheatEngine.applyCheatToRead(address, data);
    }

    if (address >= 0x0000 && address <= 0x1FFF) {
      data = _cpuRam[address & 0x07FF];
    } else if (address >= 0x2000 && address <= 0x3FFF) {
      data = ppu.cpuRead(address & 0x0007, readOnly: readOnly);
    } else if (address == 0x4015) {
      data = apu.cpuRead(address);
    } else if (address >= 0x4016 && address <= 0x4017) {
      final controllerIndex = address & 0x0001;

      data = (_controllerState[controllerIndex] & 0x80) > 0 ? 1 : 0;

      if (!readOnly) {
        _controllerState[controllerIndex] =
            (_controllerState[controllerIndex] << 1) & 0xFF;
      }

      if (controllerIndex == 1 && zapper.enabled) {
        final lightDetected = zapper.detectLight(ppu.screenPixels);

        lightDetected ? data &= ~0x08 : data |= 0x08;
        zapper.triggerPressed ? data &= ~0x10 : data |= 0x10;
      }
    }

    return cheatEngine.applyCheatToRead(address, data);
  }

  void insertCartridge(Cartridge cartridge) {
    cart = cartridge;
    ppu.cart = cartridge;
  }

  void reset() {
    cart?.reset();
    cpu.reset();
    ppu.reset();

    _systemClockCounter = 0;
    _cpuClockCounter = 0;
    _cpuClockAccumulator = 0.0;
    _dmaPage = 0x00;
    _dmaAddress = 0x00;
    _dmaData = 0x00;
    _dmaDummy = true;
    _dmaTransfer = false;
    _audioBufferIndex = 0;
    _audioBufferCount = 0;
  }

  void step() {
    var cycles = 0;

    if (ppu.nmi) {
      ppu.nmi = false;
      cycles = cpu.nmi();
    } else if (cart?.getMapper().irqState() ?? false) {
      cycles = cpu.irq();
      cart?.getMapper().irqClear();
    } else if (apu.frameIrq) {
      cycles = cpu.irq();
    }

    if (cycles == 0) {
      if (_dmaTransfer) {
        for (var i = 0; i < 256; i++) {
          ppu.pOAM[(ppu.oamAddress + i) & 0xFF] = cpuRead((_dmaPage << 8) | i);
        }

        _dmaTransfer = false;
        _dmaDummy = true;
        cycles = 513;

        if (_cpuClockCounter.isOdd) cycles++;
      } else {
        cycles = cpu.step();
      }
    }

    final cpuRatio = _isPal ? 3.2 : 3.0;
    var ppuCyclesToRun = (cycles * cpuRatio).round();
    _cpuClockAccumulator += (cycles * cpuRatio) - ppuCyclesToRun;

    if (_cpuClockAccumulator.abs() >= 1.0) {
      final fix = _cpuClockAccumulator.truncate();
      ppuCyclesToRun += fix;
      _cpuClockAccumulator -= fix;
    }

    for (var i = 0; i < ppuCyclesToRun; i++) {
      ppu.clock();
      _systemClockCounter++;

      _audioTime += _audioTimePerNESClock;
      if (_audioTime >= _audioTimePerSystemSample) {
        _audioTime -= _audioTimePerSystemSample;
        _audioSample = apu.getOutputSample();

        _audioBuffer[_audioBufferIndex] = _audioSample;
        _audioBufferIndex = (_audioBufferIndex + 1) % _audioBufferSize;
        if (_audioBufferCount < _audioBufferSize) _audioBufferCount++;
      }
    }

    for (var i = 0; i < cycles; i++) {
      apu.clock();
    }

    _cpuClockCounter += cycles;
  }

  void runFrame() {
    while (!ppu.frameComplete) {
      step();
    }

    ppu.frameComplete = false;
  }

  List<double> getAudioBuffer() {
    if (_audioBufferCount == 0) return const [];

    final buffer = Float64List(_audioBufferCount);

    if (_audioBufferCount < _audioBufferSize) {
      buffer.setRange(0, _audioBufferCount, _audioBuffer);
    } else {
      final firstChunkSize = _audioBufferSize - _audioBufferIndex;

      buffer
        ..setRange(0, firstChunkSize, _audioBuffer, _audioBufferIndex)
        ..setRange(firstChunkSize, _audioBufferSize, _audioBuffer, 0);
    }

    _audioBufferIndex = 0;
    _audioBufferCount = 0;

    return buffer;
  }

  bool hasAudioData() => _audioBufferCount > 0;

  EmulatorState saveState() => EmulatorState(
    cpuState: cpu.saveState(),
    ppuState: ppu.saveState(),
    apuState: apu.saveState(),
    busState: BusState(
      cpuRam: Uint8List.fromList(_cpuRam),
      controller: Uint8List.fromList(controller),
      controllerState: Uint8List.fromList(_controllerState),
      systemClockCounter: _systemClockCounter,
      dmaPage: _dmaPage,
      dmaAddress: _dmaAddress,
      dmaData: _dmaData,
      dmaDummy: _dmaDummy,
      dmaTransfer: _dmaTransfer,
      zapperEnabled: zapper.enabled,
      zapperTriggerPressed: zapper.triggerPressed,
      zapperPointerOnScreen: zapper.pointerOnScreen,
      zapperX: zapper.pointerX,
      zapperY: zapper.pointerY,
    ),
    mapperState: cart?.saveMapperState() ?? {},
    timestamp: DateTime.now(),
  );

  void restoreState(EmulatorState state) {
    cpu.restoreState(state.cpuState);
    ppu.restoreState(state.ppuState);
    apu.restoreState(state.apuState);

    cart?.restoreMapperState(state.mapperState);

    final busState = state.busState;

    _cpuRam.setRange(0, busState.cpuRam.length, busState.cpuRam);
    controller.setRange(0, 2, busState.controller);
    _controllerState.setRange(0, 2, busState.controllerState);
    _systemClockCounter = busState.systemClockCounter;
    _dmaPage = busState.dmaPage;
    _dmaAddress = busState.dmaAddress;
    _dmaData = busState.dmaData;
    _dmaDummy = busState.dmaDummy;
    _dmaTransfer = busState.dmaTransfer;

    zapper.restorePersistentState(
      enabledState: busState.zapperEnabled,
      triggerState: busState.zapperTriggerPressed,
      x: busState.zapperX,
      y: busState.zapperY,
      pointerVisible: busState.zapperPointerOnScreen,
    );

    _audioBufferIndex = 0;
    _audioBufferCount = 0;
  }
}
