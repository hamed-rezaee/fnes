import 'dart:io';
import 'dart:typed_data';

import 'package:fnes/mappers/mapper.dart';
import 'package:fnes/mappers/mapper_factory.dart';

class Cartridge {
  Cartridge(String fileName) {
    _loadFromFile(fileName);
  }

  Cartridge.fromBytes(Uint8List bytes) {
    _loadFromBytes(bytes);
  }

  bool _imageValid = false;
  MapperMirror _hwMirror = MapperMirror.horizontal;

  int _mapperId = 0;
  int programBanks = 0;
  int charBanks = 0;

  late Uint8List _programMemory;
  late Uint8List _charMemory;

  late Mapper _mapper;

  void _loadFromFile(String fileName) {
    final file = File(fileName);
    if (!file.existsSync()) {
      _imageValid = false;
      return;
    }

    final bytes = file.readAsBytesSync();
    _loadFromBytes(bytes);
  }

  void _loadFromBytes(Uint8List bytes) {
    if (bytes.length < 16) {
      _imageValid = false;
      return;
    }

    final programRomChunks = bytes[4];
    final charRomChunks = bytes[5];
    final mapper1 = bytes[6];
    final mapper2 = bytes[7];
    final programRamSize = bytes[8];

    var offset = 16;

    if ((mapper1 & 0x04) != 0) {
      offset += 512;
    }

    _mapperId = ((mapper2 >> 4) << 4) | (mapper1 >> 4);
    _hwMirror = (mapper1 & 0x01) != 0
        ? MapperMirror.vertical
        : MapperMirror.horizontal;

    var fileType = 1;
    if ((mapper2 & 0x0C) == 0x08) fileType = 2;

    if (fileType == 1) {
      programBanks = programRomChunks;
      _programMemory = Uint8List(programBanks * 16384);
      if (offset + _programMemory.length <= bytes.length) {
        _programMemory.setAll(
          0,
          bytes.sublist(offset, offset + _programMemory.length),
        );
      }
      offset += _programMemory.length;

      charBanks = charRomChunks;
      if (charBanks == 0) {
        _charMemory = Uint8List(8192);
      } else {
        _charMemory = Uint8List(charBanks * 8192);
        if (offset + _charMemory.length <= bytes.length) {
          _charMemory.setAll(
            0,
            bytes.sublist(offset, offset + _charMemory.length),
          );
        }
      }
      offset += _charMemory.length;
    } else if (fileType == 2) {
      programBanks = ((programRamSize & 0x07) << 8) | programRomChunks;
      _programMemory = Uint8List(programBanks * 16384);
      if (offset + _programMemory.length <= bytes.length) {
        _programMemory.setAll(
          0,
          bytes.sublist(offset, offset + _programMemory.length),
        );
      }
      offset += _programMemory.length;

      charBanks = ((programRamSize & 0x38) << 8) | charRomChunks;
      _charMemory = Uint8List(charBanks * 8192);
      if (offset + _charMemory.length <= bytes.length) {
        _charMemory.setAll(
          0,
          bytes.sublist(offset, offset + _charMemory.length),
        );
      }
      offset += _charMemory.length;
    }

    _mapper = MapperFactory.createMapper(_mapperId, programBanks, charBanks);

    _imageValid = true;
  }

  bool imageValid() => _imageValid;

  bool cpuRead(int address, void Function(int) setData) {
    int? mappedAddress;
    int? dataFromMapper;

    final result = _mapper.cpuMapRead(address, (data) => dataFromMapper = data);

    if (result != null) mappedAddress = result;

    if (mappedAddress != null) {
      if (mappedAddress == 0xFFFFFFFF) {
        if (dataFromMapper != null) setData(dataFromMapper!);

        return true;
      } else {
        setData(_programMemory[mappedAddress]);

        return true;
      }
    }

    return false;
  }

  bool cpuWrite(int address, int data) {
    final mappedAddress = _mapper.cpuMapWrite(address, data);

    if (mappedAddress != null) {
      if (mappedAddress == 0xFFFFFFFF) {
        return true;
      } else {
        _programMemory[mappedAddress] = data;
        return true;
      }
    }

    return false;
  }

  bool ppuRead(int address, void Function(int) setData) {
    final mappedAddress = _mapper.ppuMapRead(address);
    if (mappedAddress != null) {
      if (mappedAddress >= 0 && mappedAddress < _charMemory.length) {
        setData(_charMemory[mappedAddress]);

        return true;
      } else {
        setData(0x00);

        return true;
      }
    }

    return false;
  }

  bool ppuWrite(int address, int data) {
    final mappedAddress = _mapper.ppuMapWrite(address);

    if (mappedAddress != null) {
      if (mappedAddress >= 0 && mappedAddress < _charMemory.length) {
        _charMemory[mappedAddress] = data;
        return true;
      }

      return true;
    }

    return false;
  }

  void reset() => _mapper.reset();

  MapperMirror mirror() {
    final mappedMirror = _mapper.mirror();

    if (mappedMirror == MapperMirror.hardware) {
      return _hwMirror;
    } else {
      return mappedMirror;
    }
  }

  Mapper getMapper() => _mapper;

  Map<String, String>? getMapperInfoMap() =>
      MapperFactory.getMapperInfoMap(_mapperId);
}
