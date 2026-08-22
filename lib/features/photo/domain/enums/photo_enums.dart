enum PhotoPriority { normal, priority, urgent, blocked }

enum PhotoWorkAction {
  newAssignment,
  scheduledVisit,
  capturing,
  needsReview,
  correctionRequested,
  submitted,
  approved,
  completed,
}

enum PhotoJobStatus {
  assigned,
  visitScheduled,
  inProgress,
  review,
  correctionRequired,
  submitted,
  approved,
  archived,
}

enum PhotoCategory { exterior, interior, room, amenity, technical, document, tour3d, pano360, other }

enum ShotType { wide, corner, feature, detail, windowView, entranceView, special }

enum MediaStatus { draft, uploaded, processing, needsReview, approved, rejected, internal, public }

enum MediaVisibility { public_, internal, technical, restricted }

enum UploadState { uploading, processing, uploaded, failed, queued, offline, synced }

enum PhotoChannel { publisher, information, mapping, management }

enum StreamStatus { pending, inProgress, completed, waiting }

enum SyncState { saved, saving, offline, synced }
