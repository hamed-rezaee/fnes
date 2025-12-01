import 'dart:typed_data';

import 'package:fnes/components/apu.dart';
import 'package:fnes/components/cartridge.dart';
import 'package:fnes/components/cpu.dart';
import 'package:fnes/components/ppu.dart';

class Bus {
  Bus({required this.cpu, required this.ppu, required this.apu}) {
    cpu.connect(this);
  }

  final CPU cpu;
  final PPU ppu;
  final APU apu;

  Cartridge? cart;

  final List<int> controller = [0, 0];
  final Uint8List _cpuRam = Uint8List(2048);

  double _audioSample = 0;
  double _audioTime = 0;
  double _audioTimePerNESClock = 0;
  double _audioTimePerSystemSample = 0;
  final List<double> _audioBuffer = [];
  static const int _audioBufferSize = 1024;
  int _audioBufferIndex = 0;

  int _systemClockCounter = 0;

  final List<int> _controllerState = [0, 0];

  int _dmaPage = 0x00;
  int _dmaAddress = 0x00;
  int _dmaData = 0x00;
  bool _dmaDummy = true;
  bool _dmaTransfer = false;

  void setSampleFrequency(int sampleRate) {
    _audioTimePerSystemSample = 1 / sampleRate;
    _audioTimePerNESClock = 1 / 5369318.0;
  }

  void cpuWrite(int address, int data) {
    if (cart?.cpuWrite(address, data) ?? false) return;

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
    } else if (address >= 0x4016 && address <= 0x4017) {
      if ((data & 0x01) == 0) {
        _controllerState[address & 0x0001] = controller[address & 0x0001];
      }
    }
  }

  int cpuRead(int address, {bool readOnly = false}) {
    var data = 0x00;

    if (cart?.cpuRead(address, (v) => data = v) ?? false) {
      return data;
    }

    if (address >= 0x0000 && address <= 0x1FFF) {
      data = _cpuRam[address & 0x07FF];
    } else if (address >= 0x2000 && address <= 0x3FFF) {
      data = ppu.cpuRead(address & 0x0007, readOnly: readOnly);
    } else if (address == 0x4015) {
      data = apu.cpuRead(address);
    } else if (address >= 0x4016 && address <= 0x4017) {
      data = (_controllerState[address & 0x0001] & 0x80) > 0 ? 1 : 0;
      if (!readOnly) {
        _controllerState[address & 0x0001] =
            (_controllerState[address & 0x0001] << 1) & 0xFF;
      }
    }

    return data;
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
    _dmaPage = 0x00;
    _dmaAddress = 0x00;
    _dmaData = 0x00;
    _dmaDummy = true;
    _dmaTransfer = false;
  }

  bool clock() {
    ppu.clock();
    apu.clock();

    if (_systemClockCounter % 3 == 0) {
      if (_dmaTransfer) {
        if (_dmaDummy) {
          if (_systemClockCounter.isOdd) {
            _dmaDummy = false;
          }
        } else {
          if (_systemClockCounter.isEven) {
            _dmaData = cpuRead((_dmaPage << 8) | _dmaAddress);
          } else {
            ppu.pOAM[_dmaAddress] = _dmaData;
            _dmaAddress = (_dmaAddress + 1) & 0xFF;
            if (_dmaAddress == 0x00) {
              _dmaTransfer = false;
              _dmaDummy = true;
            }
          }
        }
      } else {
        cpu.clock();
      }
    }

    var audioSampleReady = false;
    _audioTime += _audioTimePerNESClock;

    if (_audioTime >= _audioTimePerSystemSample) {
      _audioTime -= _audioTimePerSystemSample;
      _audioSample = apu.getOutputSample();

      if (_audioBuffer.length < _audioBufferSize) {
        _audioBuffer.add(_audioSample);
      } else {
        _audioBuffer[_audioBufferIndex] = _audioSample;
        _audioBufferIndex = (_audioBufferIndex + 1) % _audioBufferSize;
      }

      audioSampleReady = true;
    }

    if (ppu.nmi) {
      ppu.nmi = false;
      cpu.nmi();
    }

    if (cart?.getMapper().irqState() ?? false) {
      cpu.irq();
    }

    _systemClockCounter++;

    return audioSampleReady;
  }

  List<double> getAudioBuffer() {
    final buffer = <double>[];

    if (_audioBuffer.length < _audioBufferSize) {
      buffer.addAll(_audioBuffer);
    } else {
      buffer
        ..addAll(_audioBuffer.sublist(_audioBufferIndex))
        ..addAll(_audioBuffer.sublist(0, _audioBufferIndex));
    }

    _audioBuffer.clear();
    _audioBufferIndex = 0;

    return buffer;
  }

  bool hasAudioData() => _audioBuffer.isNotEmpty;
}
