import 'package:json_annotation/json_annotation.dart';

part 'cheat_code.g.dart';

@JsonSerializable()
class CheatCode {
  CheatCode({
    required this.id,
    required this.name,
    required this.address,
    required this.value,
    this.compareValue,
    this.enabled = true,
  });

  factory CheatCode.fromJson(Map<String, dynamic> json) =>
      _$CheatCodeFromJson(json);

  final String id;
  final String name;
  final int address;
  final int value;
  final int? compareValue;

  bool enabled;

  Map<String, dynamic> toJson() => _$CheatCodeToJson(this);

  CheatCode copyWith({
    String? id,
    String? name,
    int? address,
    int? value,
    int? compareValue,
    bool? enabled,
    String? description,
  }) => CheatCode(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    value: value ?? this.value,
    compareValue: compareValue ?? this.compareValue,
    enabled: enabled ?? this.enabled,
  );

  static CheatCode? fromGameGenieCode(String code, {String? name}) {
    final formattedCode = code.toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );

    if (formattedCode.length != 6 && formattedCode.length != 8) return null;

    const gameGenieChars = 'APZLGITYEOXUKSVN';

    try {
      final decoded = formattedCode.split('').map((c) {
        final index = gameGenieChars.indexOf(c);

        if (index == -1) {
          throw FormatException('Invalid Game Genie character: $c');
        }

        return index;
      }).toList();

      final is6Char = formattedCode.length == 6;

      final address =
          0x8000 |
          ((decoded[3] & 7) << 12) |
          ((decoded[5] & 7) << 8) |
          ((decoded[4] & 8) << 8) |
          ((decoded[2] & 7) << 4) |
          ((decoded[1] & 8) << 4) |
          (decoded[4] & 7) |
          (decoded[3] & 8);

      final value =
          ((decoded[1] & 7) << 4) |
          ((decoded[0] & 8) << 4) |
          (decoded[0] & 7) |
          (decoded[is6Char ? 5 : 7] & 8);

      final compareValue = is6Char
          ? null
          : ((decoded[7] & 7) << 4) |
                ((decoded[6] & 8) << 4) |
                (decoded[6] & 7) |
                (decoded[5] & 8);

      return CheatCode(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'Game Genie: $formattedCode',
        address: address,
        value: value,
        compareValue: compareValue,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  static CheatCode? fromRawCode(String code2, {String? name}) {
    final normalizedCode = code2.trim().toUpperCase();

    final parts = normalizedCode.split(':');

    if (parts.length != 2) return null;

    try {
      final address = int.parse(
        parts[0].startsWith('0X') ? parts[0].substring(2) : parts[0],
        radix: 16,
      );

      final value = int.parse(
        parts[1].startsWith('0X') ? parts[1].substring(2) : parts[1],
        radix: 16,
      );

      if (address < 0 || address > 0xFFFF || value < 0 || value > 0xFF) {
        return null;
      }

      return CheatCode(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'Cheat at ${address.toRadixString(16).toUpperCase()}',
        address: address,
        value: value,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'CheatCode(name: $name, address: 0x${address.toRadixString(16).padLeft(4, '0')}, '
      'value: 0x${value.toRadixString(16).padLeft(2, '0')}, enabled: $enabled)';
}
