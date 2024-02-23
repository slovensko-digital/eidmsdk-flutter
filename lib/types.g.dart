// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Certificate _$CertificateFromJson(Map<String, dynamic> json) => Certificate(
      slot: json['slot'] as String,
      supportedSchemes: (json['supportedSchemes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isQualified: json['isQualified'] as bool,
      certIndex: json['certIndex'] as int,
      certData: json['certData'] as String,
    );

Map<String, dynamic> _$CertificateToJson(Certificate instance) =>
    <String, dynamic>{
      'slot': instance.slot,
      'supportedSchemes': instance.supportedSchemes,
      'isQualified': instance.isQualified,
      'certIndex': instance.certIndex,
      'certData': instance.certData,
    };

CertificatesInfo _$CertificatesInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['QSCD'],
  );
  return CertificatesInfo(
    qscd: json['QSCD'] as bool,
    cardType: json['cardType'] as String,
    certificates: (json['certificates'] as List<dynamic>)
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$CertificatesInfoToJson(CertificatesInfo instance) =>
    <String, dynamic>{
      'QSCD': instance.qscd,
      'cardType': instance.cardType,
      'certificates': instance.certificates.map((e) => e.toJson()).toList(),
    };
