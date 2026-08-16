class PropertyLocation {
  const PropertyLocation({
    this.latitude,
    this.longitude,
    this.addressText,
    this.countryCode,
    this.countryName,
    this.city,
    this.district,
    this.neighborhood,
    this.street,
    this.postalCode,
  });

  final double? latitude;
  final double? longitude;
  final String? addressText;
  final String? countryCode;
  final String? countryName;
  final String? city;
  final String? district;
  final String? neighborhood;
  final String? street;
  final String? postalCode;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude != 0 &&
      longitude != 0;

  /// Hierarchy for display: Country → City → District → Neighborhood → Street
  List<String> get hierarchy {
    return [
      if (countryName != null && countryName!.isNotEmpty) countryName!,
      if (city != null && city!.isNotEmpty) city!,
      if (district != null && district!.isNotEmpty) district!,
      if (neighborhood != null && neighborhood!.isNotEmpty) neighborhood!,
      if (street != null && street!.isNotEmpty) street!,
    ];
  }

  String get displayLine {
    if (addressText != null && addressText!.isNotEmpty) return addressText!;
    return [
      if (neighborhood != null) neighborhood,
      if (district != null) district,
      if (city != null) city,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }
}
