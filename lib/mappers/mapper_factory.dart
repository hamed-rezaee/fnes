import 'package:fnes/mappers/mapper.dart';
import 'package:fnes/mappers/mapper_000.dart';
import 'package:fnes/mappers/mapper_001.dart';
import 'package:fnes/mappers/mapper_002.dart';
import 'package:fnes/mappers/mapper_003.dart';
import 'package:fnes/mappers/mapper_004.dart';
import 'package:fnes/mappers/mapper_005.dart';
import 'package:fnes/mappers/mapper_007.dart';
import 'package:fnes/mappers/mapper_009.dart';
import 'package:fnes/mappers/mapper_023.dart';
import 'package:fnes/mappers/mapper_033.dart';
import 'package:fnes/mappers/mapper_066.dart';

enum MapperFeature { irq, programRam, charRam, nameTableControl }

enum MapperCategory { simple, mmc, vrc, sunSoft, namco, other }

enum MirroringType { horizontal, vertical, fourScreen, mapperControlled }

enum CartridgeSpecialChip {
  none,
  extraAudio,
  scanlineCounter,
  extendedGraphics,
}

class MapperInfo {
  const MapperInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.manufacturer,
    this.features = const {},
    this.minProgramSizeKB,
    this.maxProgramSizeKB,
    this.minCharSizeKB,
    this.maxCharSizeKB,
    this.batteryBacked = false,
    this.supportedMirroring = const [],
    this.specialChip = CartridgeSpecialChip.none,
  });

  final int id;
  final String name;
  final MapperCategory category;
  final Set<MapperFeature> features;
  final String manufacturer;

  final int? minProgramSizeKB;
  final int? maxProgramSizeKB;
  final int? minCharSizeKB;
  final int? maxCharSizeKB;
  final bool batteryBacked;
  final List<MirroringType> supportedMirroring;
  final CartridgeSpecialChip specialChip;

  bool get hasIRQ => features.contains(MapperFeature.irq);

  bool get hasProgramRam => features.contains(MapperFeature.programRam);

  bool get hasCharRam => features.contains(MapperFeature.charRam);

  bool get hasNametableControl =>
      features.contains(MapperFeature.nameTableControl);
}

class MapperFactory {
  static Mapper createMapper(int mapperId, int programBanks, int charBanks) =>
      switch (mapperId) {
        0 => Mapper000(programBanks, charBanks),
        1 => Mapper001(programBanks, charBanks),
        2 => Mapper002(programBanks, charBanks),
        3 => Mapper003(programBanks, charBanks),
        4 => Mapper004(programBanks, charBanks),
        5 => Mapper005(programBanks, charBanks),
        7 => Mapper007(programBanks, charBanks),
        9 => Mapper009(programBanks, charBanks),
        23 => Mapper023(programBanks, charBanks),
        33 => Mapper033(programBanks, charBanks),
        66 => Mapper066(programBanks, charBanks),
        _ => throw Exception('Unsupported mapper ID: $mapperId'),
      };

  static const List<MapperInfo> mappers = [
    MapperInfo(
      id: 0,
      name: 'NROM',
      category: MapperCategory.simple,
      manufacturer: 'Nintendo',
      minProgramSizeKB: 16,
      maxProgramSizeKB: 32,
      minCharSizeKB: 8,
      maxCharSizeKB: 8,
      supportedMirroring: [MirroringType.horizontal, MirroringType.vertical],
    ),
    MapperInfo(
      id: 1,
      name: 'MMC1',
      category: MapperCategory.mmc,
      manufacturer: 'Nintendo',
      features: {MapperFeature.irq, MapperFeature.programRam},
      minProgramSizeKB: 64,
      maxProgramSizeKB: 512,
      minCharSizeKB: 8,
      maxCharSizeKB: 256,
      batteryBacked: true,
      supportedMirroring: [MirroringType.mapperControlled],
    ),
    MapperInfo(
      id: 2,
      name: 'UxROM',
      category: MapperCategory.simple,
      manufacturer: 'Nintendo / Capcom',
      features: {MapperFeature.programRam},
      minProgramSizeKB: 64,
      maxProgramSizeKB: 256,
      minCharSizeKB: 0,
      maxCharSizeKB: 0,
      supportedMirroring: [MirroringType.horizontal, MirroringType.vertical],
    ),
    MapperInfo(
      id: 3,
      name: 'CNROM',
      category: MapperCategory.simple,
      manufacturer: 'Nintendo',
      minProgramSizeKB: 32,
      maxProgramSizeKB: 32,
      minCharSizeKB: 32,
      maxCharSizeKB: 128,
      supportedMirroring: [MirroringType.horizontal, MirroringType.vertical],
    ),
    MapperInfo(
      id: 4,
      name: 'MMC3',
      category: MapperCategory.mmc,
      manufacturer: 'Nintendo',
      features: {MapperFeature.irq, MapperFeature.programRam},
      minProgramSizeKB: 128,
      maxProgramSizeKB: 512,
      minCharSizeKB: 8,
      maxCharSizeKB: 256,
      batteryBacked: true,
      supportedMirroring: [MirroringType.mapperControlled],
      specialChip: CartridgeSpecialChip.scanlineCounter,
    ),
    MapperInfo(
      id: 5,
      name: 'MMC5',
      category: MapperCategory.mmc,
      manufacturer: 'Nintendo',
      features: {
        MapperFeature.irq,
        MapperFeature.programRam,
        MapperFeature.nameTableControl,
      },
      minProgramSizeKB: 128,
      maxProgramSizeKB: 1024,
      minCharSizeKB: 0,
      maxCharSizeKB: 1024,
      batteryBacked: true,
      supportedMirroring: [MirroringType.mapperControlled],
      specialChip: CartridgeSpecialChip.extraAudio,
    ),
    MapperInfo(
      id: 7,
      name: 'AxROM',
      category: MapperCategory.simple,
      manufacturer: 'Nintendo / Rare',
      features: {MapperFeature.nameTableControl},
      minProgramSizeKB: 32,
      maxProgramSizeKB: 512,
      supportedMirroring: [MirroringType.mapperControlled],
    ),
    MapperInfo(
      id: 9,
      name: 'MMC2',
      category: MapperCategory.mmc,
      manufacturer: 'Nintendo',
      features: {MapperFeature.programRam},
      minProgramSizeKB: 128,
      maxProgramSizeKB: 128,
      minCharSizeKB: 128,
      maxCharSizeKB: 128,
      supportedMirroring: [MirroringType.mapperControlled],
    ),
    MapperInfo(
      id: 23,
      name: 'VRC2b/VRC4e',
      category: MapperCategory.vrc,
      manufacturer: 'Konami',
      features: {MapperFeature.irq, MapperFeature.programRam},
      minProgramSizeKB: 128,
      maxProgramSizeKB: 256,
      minCharSizeKB: 128,
      maxCharSizeKB: 256,
      supportedMirroring: [MirroringType.mapperControlled],
    ),
    MapperInfo(
      id: 33,
      name: 'Taito TC0190/TC0350',
      category: MapperCategory.other,
      manufacturer: 'Taito',
      minProgramSizeKB: 128,
      maxProgramSizeKB: 256,
      minCharSizeKB: 128,
      maxCharSizeKB: 256,
      supportedMirroring: [MirroringType.mapperControlled],
    ),
    MapperInfo(
      id: 66,
      name: 'GxROM',
      category: MapperCategory.simple,
      manufacturer: 'Bandai / HAL',
      minProgramSizeKB: 32,
      maxProgramSizeKB: 256,
      minCharSizeKB: 8,
      maxCharSizeKB: 128,
      supportedMirroring: [MirroringType.horizontal, MirroringType.vertical],
    ),
  ];

  static Map<String, String> getMapperInfoMap(int mapperId) {
    final map = <String, String>{};

    final mapper = getMapperInfo(mapperId);

    if (mapper == null) return map;

    map['ID'] = '${mapper.id}';
    map['Name'] = mapper.name;
    map['Manufacturer'] = mapper.manufacturer;
    map['Category'] = mapper.category.name;
    map['PRG Size (KB)'] = mapper.minProgramSizeKB == mapper.maxProgramSizeKB
        ? '${mapper.minProgramSizeKB}'
        : '${mapper.minProgramSizeKB} to ${mapper.maxProgramSizeKB}';
    map['CHR Size (KB)'] = mapper.minCharSizeKB == mapper.maxCharSizeKB
        ? '${mapper.minCharSizeKB}'
        : '${mapper.minCharSizeKB} to ${mapper.maxCharSizeKB}';
    map['Battery Backed'] = '${mapper.batteryBacked}';
    map['Supported Mirroring'] = mapper.supportedMirroring
        .map((e) => e.name)
        .join(', ');

    return map;
  }

  static MapperInfo? getMapperInfo(int mapperId) => mappers.firstWhere(
    (m) => m.id == mapperId,
    orElse: () => throw ArgumentError('Invalid mapper ID'),
  );

  static List<MapperInfo> getByCategory(MapperCategory category) =>
      mappers.where((m) => m.category == category).toList();

  static List<MapperInfo> getWithFeature(MapperFeature feature) =>
      mappers.where((m) => m.features.contains(feature)).toList();
}
