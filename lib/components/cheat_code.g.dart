// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cheat_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheatCode _$CheatCodeFromJson(Map<String, dynamic> json) => CheatCode(
  id: json['id'] as String,
  name: json['name'] as String,
  address: (json['address'] as num).toInt(),
  value: (json['value'] as num).toInt(),
  compareValue: (json['compareValue'] as num?)?.toInt(),
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$CheatCodeToJson(CheatCode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'value': instance.value,
  'compareValue': instance.compareValue,
  'enabled': instance.enabled,
};
