enum FieldPriority { normal, priority, urgent, blocked }

enum FieldWorkAction {
  newAssignment,
  scheduledVisit,
  inProgress,
  draftReport,
  correctionRequested,
  submitted,
  approved,
  completed,
}

enum FieldReportStatus {
  assigned,
  visitScheduled,
  inProgress,
  draft,
  correctionRequired,
  submitted,
  approved,
  archived,
}

enum DataOrigin { observed, ownerProvided, estimated, unverified, transcription, unknown }

enum FieldAvailability { known, unknown, notAvailable, notApplicable, ownerDeclined, requiresVerification }

enum RoomCondition { excellent, veryGood, good, fair, needsRenovation, majorRenovation, unsafe }

enum SyncState { saved, saving, offline, synced }

enum FieldChannel { publisher, photography, mapping, management }

enum StreamStatus { pending, inProgress, completed, waiting }
