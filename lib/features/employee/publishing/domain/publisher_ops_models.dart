import 'publishing_models.dart';

/// Compact attention counters for the Publisher Work page.
class PublisherWorkOverview {
  const PublisherWorkOverview({
    required this.pendingRequests,
    required this.inProgress,
    required this.waitingInformation,
    required this.readyToReview,
    required this.readyToPublish,
    required this.published,
    required this.needsUpdate,
  });

  final int pendingRequests;
  final int inProgress;
  final int waitingInformation;
  final int readyToReview;
  final int readyToPublish;
  final int published;
  final int needsUpdate;

  factory PublisherWorkOverview.fromAssets(List<PropertyAsset> all) {
    int c(bool Function(PropertyAsset) test) => all.where(test).length;
    return PublisherWorkOverview(
      pendingRequests: c((a) => a.pipelineStatus == 'request_created'),
      inProgress: c(
        (a) => const {
          'information_collection',
          'photography',
          'three_d',
          'floor_plan',
          'location_intelligence',
        }.contains(a.pipelineStatus),
      ),
      waitingInformation: c(
        (a) =>
            a.pipelineStatus == 'information_collection' ||
            a.informationPct < 100,
      ),
      readyToReview: c((a) => a.pipelineStatus == 'quality_review'),
      readyToPublish: c((a) => a.pipelineStatus == 'ready_for_publication'),
      published: c((a) => a.isPublished || a.pipelineStatus == 'published'),
      needsUpdate: c(
        (a) => const {
          'needs_correction',
          'paused',
          'owner_unavailable',
        }.contains(a.pipelineStatus),
      ),
    );
  }
}

enum PublisherQueueBucket {
  needsAction,
  waitingInformation,
  waitingPhotography,
  waiting3d,
  waitingFloorPlan,
  readyForReview,
  readyToPublish,
  recentlyPublished,
  requiresUpdate,
}

extension PublisherQueueBucketX on PublisherQueueBucket {
  String get labelEn {
    switch (this) {
      case PublisherQueueBucket.needsAction:
        return 'Needs Action';
      case PublisherQueueBucket.waitingInformation:
        return 'Waiting for Field Information';
      case PublisherQueueBucket.waitingPhotography:
        return 'Waiting for Photography';
      case PublisherQueueBucket.waiting3d:
        return 'Waiting for 3D';
      case PublisherQueueBucket.waitingFloorPlan:
        return 'Waiting for Floor Plan';
      case PublisherQueueBucket.readyForReview:
        return 'Ready for Review';
      case PublisherQueueBucket.readyToPublish:
        return 'Ready to Publish';
      case PublisherQueueBucket.recentlyPublished:
        return 'Recently Published';
      case PublisherQueueBucket.requiresUpdate:
        return 'Requires Update';
    }
  }
}

class PublisherQueueItem {
  const PublisherQueueItem({
    required this.asset,
    required this.bucket,
    required this.missing,
    required this.priorityLabel,
  });

  final PropertyAsset asset;
  final PublisherQueueBucket bucket;
  final List<String> missing;
  final String priorityLabel;
}

class QualityGate {
  const QualityGate({
    required this.key,
    required this.label,
    required this.status, // complete | incomplete | warning | error | na
    this.detail,
  });

  final String key;
  final String label;
  final String status;
  final String? detail;
}

class PipelineStageView {
  const PipelineStageView({
    required this.key,
    required this.label,
    required this.state, // complete | in_progress | waiting | missing | failed
  });

  final String key;
  final String label;
  final String state;
}

class OfficeLookupResult {
  const OfficeLookupResult({
    required this.code,
    required this.name,
    required this.id,
    required this.ownerName,
    required this.region,
    required this.status,
  });

  final String code;
  final String name;
  final String id;
  final String ownerName;
  final String region;
  final String status;
}

class UserLookupResult {
  const UserLookupResult({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
  });

  final String id;
  final String name;
  final String phone;
  final String location;
}

/// Derive pipeline stage states from asset completion fields.
List<PipelineStageView> pipelineFor(PropertyAsset a) {
  String stage(String key, int pct, {bool waiting = false}) {
    if (pct >= 100) return 'complete';
    if (pct > 0) return 'in_progress';
    if (waiting) return 'waiting';
    return 'missing';
  }

  final published = a.isPublished || a.pipelineStatus == 'published';
  return [
    PipelineStageView(
      key: 'request',
      label: 'Request',
      state: a.pipelineStatus == 'request_created' ? 'in_progress' : 'complete',
    ),
    PipelineStageView(
      key: 'information',
      label: 'Information',
      state: stage('information', a.informationPct),
    ),
    PipelineStageView(
      key: 'photography',
      label: 'Photography',
      state: stage('photography', a.photographyPct),
    ),
    PipelineStageView(
      key: 'three_d',
      label: '3D Tour',
      state: stage('three_d', a.threeDPct),
    ),
    PipelineStageView(
      key: 'floor_plan',
      label: 'Floor Plan',
      state: stage('floor_plan', a.floorPlanPct),
    ),
    const PipelineStageView(
      key: 'location',
      label: 'Location Intelligence',
      state: 'waiting',
    ),
    const PipelineStageView(
      key: 'financial',
      label: 'Financial Data',
      state: 'waiting',
    ),
    const PipelineStageView(
      key: 'translation',
      label: 'Translation',
      state: 'waiting',
    ),
    PipelineStageView(
      key: 'review',
      label: 'Quality Review',
      state: a.pipelineStatus == 'quality_review'
          ? 'in_progress'
          : (a.pipelineStatus == 'ready_for_publication' || published
              ? 'complete'
              : 'waiting'),
    ),
    PipelineStageView(
      key: 'published',
      label: 'Published',
      state: published ? 'complete' : 'missing',
    ),
  ];
}

List<QualityGate> qualityGatesFor(PropertyAsset a) {
  QualityGate g(String key, String label, bool ok, {String? detail, bool warn = false}) {
    return QualityGate(
      key: key,
      label: label,
      status: ok ? 'complete' : (warn ? 'warning' : 'incomplete'),
      detail: detail,
    );
  }

  return [
    g('basic', 'Basic information', a.title != null || a.addressText != null),
    g('location', 'Location', a.city != null || a.addressText != null),
    g('dimensions', 'Dimensions', a.informationPct >= 80,
        detail: a.informationPct < 80 ? 'Information report incomplete' : null),
    g('pricing', 'Pricing', a.askingPrice != null,
        detail: a.askingPrice == null ? 'Not available' : null, warn: true),
    g('description', 'Description', a.notes != null && a.notes!.isNotEmpty,
        warn: true, detail: 'Not available'),
    g('media', 'Media', a.photographyPct >= 100 || a.coverImageUrl != null),
    g('three_d', '3D', a.threeDPct >= 100, warn: true),
    g('floor_plan', 'Floor Plan', a.floorPlanPct >= 100, warn: true),
    g('nearby', 'Nearby places', false, warn: true, detail: 'Not available'),
    g('financial', 'Financial data', a.askingPrice != null, warn: true),
    g('translations', 'Translations', false, warn: true, detail: 'Not available'),
    g('keywords', 'Search keywords', false, warn: true, detail: 'Not available'),
    g('legal', 'Legal information', false, warn: true, detail: 'Not available'),
  ];
}

List<String> missingFor(PropertyAsset a) {
  final m = <String>[];
  if (a.informationPct < 100) m.add('Information ${a.informationPct}%');
  if (a.photographyPct < 100) m.add('Photography ${a.photographyPct}%');
  if (a.threeDPct < 100) m.add('3D ${a.threeDPct}%');
  if (a.floorPlanPct < 100) m.add('Floor plan ${a.floorPlanPct}%');
  if (a.askingPrice == null) m.add('Price');
  return m;
}

PublisherQueueBucket bucketFor(PropertyAsset a) {
  if (const {'needs_correction', 'paused', 'owner_unavailable'}
      .contains(a.pipelineStatus)) {
    return PublisherQueueBucket.requiresUpdate;
  }
  if (a.isPublished || a.pipelineStatus == 'published') {
    return PublisherQueueBucket.recentlyPublished;
  }
  if (a.pipelineStatus == 'ready_for_publication') {
    return PublisherQueueBucket.readyToPublish;
  }
  if (a.pipelineStatus == 'quality_review') {
    return PublisherQueueBucket.readyForReview;
  }
  if (a.floorPlanPct < 100 && a.photographyPct >= 100) {
    return PublisherQueueBucket.waitingFloorPlan;
  }
  if (a.threeDPct < 100 && a.photographyPct >= 60) {
    return PublisherQueueBucket.waiting3d;
  }
  if (a.photographyPct < 100 && a.informationPct >= 80) {
    return PublisherQueueBucket.waitingPhotography;
  }
  if (a.informationPct < 100) {
    return PublisherQueueBucket.waitingInformation;
  }
  if (a.pipelineStatus == 'request_created') {
    return PublisherQueueBucket.needsAction;
  }
  return PublisherQueueBucket.needsAction;
}
