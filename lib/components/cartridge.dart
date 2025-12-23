import 'dart:io';
import 'dart:typed_data';

import 'package:fnes/mappers/mapper.dart';
import 'package:fnes/mappers/mapper_factory.dart';

class NESHeader {
  NESHeader.fromBytes(Uint8List bytes) {
    if (bytes.length < 16) throw Exception('Invalid iNES header: too short');

    programRomChunks = bytes[4];
    charRomChunks = bytes[5];
    mapper1 = bytes[6];
    mapper2 = bytes[7];
    programRamSize = bytes[8];

    fileType = 1;

    if ((mapper2 & 0x0C) == 0x08) fileType = 2;
  }

  late int programRomChunks;
  late int charRomChunks;
  late int mapper1;
  late int mapper2;
  late int programRamSize;
  late int fileType;
}

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
  int _submapper = 0;
  int programBanks = 0;
  int charBanks = 0;

  late Uint8List _programMemory;
  late Uint8List _charMemory;
  late Mapper _mapper;
  late NESHeader? _header;

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

    try {
      _header = NESHeader.fromBytes(bytes);
    } on Exception {
      _imageValid = false;
      return;
    }

    final header = _header!;
    var offset = 16;

    if ((header.mapper1 & 0x04) != 0) offset += 512;

    _mapperId = ((header.mapper2 >> 4) << 4) | (header.mapper1 >> 4);
    _submapper = (header.mapper2 >> 4) & 0x0F;

    _hwMirror = (header.mapper1 & 0x01) != 0
        ? MapperMirror.vertical
        : MapperMirror.horizontal;

    final fileType = header.fileType;

    if (fileType == 1) {
      programBanks = header.programRomChunks;
      _programMemory = Uint8List(programBanks * 16384);
      if (offset + _programMemory.length <= bytes.length) {
        _programMemory.setAll(
          0,
          bytes.sublist(offset, offset + _programMemory.length),
        );
      }
      offset += _programMemory.length;

      charBanks = header.charRomChunks;
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
      programBanks =
          ((header.programRamSize & 0x07) << 8) | header.programRomChunks;
      _programMemory = Uint8List(programBanks * 16384);
      if (offset + _programMemory.length <= bytes.length) {
        _programMemory.setAll(
          0,
          bytes.sublist(offset, offset + _programMemory.length),
        );
      }
      offset += _programMemory.length;

      charBanks = ((header.programRamSize & 0x38) << 8) | header.charRomChunks;
      _charMemory = Uint8List(charBanks * 8192);
      if (offset + _charMemory.length <= bytes.length) {
        _charMemory.setAll(
          0,
          bytes.sublist(offset, offset + _charMemory.length),
        );
      }
      offset += _charMemory.length;
    }

    _mapper = MapperFactory.createMapper(_mapperId, programBanks, charBanks)
      ..submapper = _submapper
      ..setPrgRomData(_programMemory)
      ..setChrRomData(_charMemory);

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

  Map<String, dynamic> saveMapperState() => {
    ..._mapper.saveState(),
    'charMemory': _charMemory.toList(),
  };

  void restoreMapperState(Map<String, dynamic> state) {
    _mapper.restoreState(state);

    if (state.containsKey('charMemory')) {
      final charMem = (state['charMemory'] as List).cast<int>();

      _charMemory.setAll(0, charMem);
    }
  }
}
