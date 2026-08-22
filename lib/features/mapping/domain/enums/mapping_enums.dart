enum MappingPriority { normal, priority, urgent, blocked }

enum MappingWorkAction {
  newRequest,
  inProgress,
  measurementReview,
  connectionRequired,
  correctionRequested,
  readyToSubmit,
  completed,
  blocked,
}

enum MappingPlanStatus {
  draft,
  inProgress,
  readyForReview,
  correctionRequired,
  approved,
  published,
  archived,
}

enum RoomKind {
  bedroom,
  masterBedroom,
  living,
  family,
  kitchen,
  dining,
  bathroom,
  guestBathroom,
  laundry,
  office,
  storage,
  garage,
  hallway,
  entrance,
  balcony,
  terrace,
  garden,
  courtyard,
  basement,
  retail,
  meeting,
  reception,
  warehouse,
  parking,
  restroom,
  custom,
}

enum WallKind { exterior, interior, structural, partition }

enum DoorKind { entrance, interior, sliding, doubleDoor, garage, balcony, other }

enum WindowKind { standard, large, floorToCeiling, bay, other }

enum FloorKind { basement, ground, first, second, roof, additional }

enum StructureKind { mainHouse, guestHouse, garage, annex, warehouse, commercial, other }

enum SyncState { saved, saving, offline, syncing, synced }

enum MessageKind { text, image, document, voice }

enum MappingChannel { publisher, information, photography, mappingTeam, management }
