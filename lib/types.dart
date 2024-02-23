import 'package:json_annotation/json_annotation.dart';

part 'types.g.dart';

@JsonSerializable()
class Certificate {
  final String slot;
  final List<String> supportedSchemes;
  final bool isQualified;
  final int certIndex;
  final String certData;

  const Certificate({
    required this.slot,
    required this.supportedSchemes,
    required this.isQualified,
    required this.certIndex,
    required this.certData,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) =>
      _$CertificateFromJson(json);

  Map<String, dynamic> toJson() => _$CertificateToJson(this);
}


@JsonSerializable()
class CertificatesInfo {
  @JsonKey(name: "QSCD", required: true)
  final bool qscd;

  final String cardType;
  final List<Certificate> certificates;

  const CertificatesInfo({
    required this.qscd,
    required this.cardType,
    required this.certificates,
  });

  factory CertificatesInfo.fromJson(Map<String, dynamic> json) =>
      _$CertificatesInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CertificatesInfoToJson(this);
}
