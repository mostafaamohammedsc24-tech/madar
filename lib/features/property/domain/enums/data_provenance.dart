/// Trust / origin of a data point shown in the Property Report.
enum DataProvenance {
  verified,
  publisherProvided,
  estimated,
  external,
  mockDemo;

  bool get isTrusted =>
      this == DataProvenance.verified ||
      this == DataProvenance.publisherProvided ||
      this == DataProvenance.external;

  bool get isEstimatedOrDemo =>
      this == DataProvenance.estimated || this == DataProvenance.mockDemo;
}
