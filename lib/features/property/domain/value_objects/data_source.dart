import '../enums/data_provenance.dart';

/// Metadata about where a field or section came from.
class DataSourceMeta {
  const DataSourceMeta({
    required this.provenance,
    this.sourceName,
    this.updatedAt,
    this.notes,
  });

  final DataProvenance provenance;
  final String? sourceName;
  final DateTime? updatedAt;
  final String? notes;

  static const publisher = DataSourceMeta(
    provenance: DataProvenance.publisherProvided,
  );

  static const estimated = DataSourceMeta(
    provenance: DataProvenance.estimated,
  );

  static const mock = DataSourceMeta(
    provenance: DataProvenance.mockDemo,
    sourceName: 'Mock / Demo',
  );
}
