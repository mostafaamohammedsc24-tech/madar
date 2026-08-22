import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/photo_strings.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart';
import '../../domain/enums/photo_enums.dart';

LegalTone tonePri(PhotoPriority p) => switch (p) {
      PhotoPriority.urgent || PhotoPriority.blocked => LegalTone.danger,
      PhotoPriority.priority => LegalTone.warning,
      PhotoPriority.normal => LegalTone.active,
    };

LegalTone toneSt(PhotoJobStatus s) => switch (s) {
      PhotoJobStatus.approved => LegalTone.success,
      PhotoJobStatus.correctionRequired => LegalTone.danger,
      PhotoJobStatus.submitted || PhotoJobStatus.inProgress || PhotoJobStatus.review => LegalTone.warning,
      _ => LegalTone.active,
    };

String _t(PhotoStrings s, String ar, String en, String ku) {
  switch (s.lang) {
    case AppLanguage.kurdish:
      return ku;
    case AppLanguage.english:
      return en;
    case AppLanguage.arabic:
      return ar;
  }
}

String labelPri(PhotoStrings s, PhotoPriority p) => switch (p) {
      PhotoPriority.normal => _t(s, 'عادي', 'Normal', 'ئاسایی'),
      PhotoPriority.priority => _t(s, 'أولوية', 'Priority', 'گرنگ'),
      PhotoPriority.urgent => _t(s, 'عاجل', 'Urgent', 'فوری'),
      PhotoPriority.blocked => _t(s, 'متوقف', 'Blocked', 'وەستاو'),
    };

String labelAct(PhotoStrings s, PhotoWorkAction a) => switch (a) {
      PhotoWorkAction.newAssignment => _t(s, 'تكليف جديد', 'New assignment', 'ئەرکی نوێ'),
      PhotoWorkAction.scheduledVisit => _t(s, 'زيارة مجدولة', 'Scheduled visit', 'سەردان'),
      PhotoWorkAction.capturing => _t(s, 'جارٍ التصوير', 'Capturing', 'وێنەگرتن'),
      PhotoWorkAction.needsReview => _t(s, 'يحتاج مراجعة', 'Needs review', 'پێداچوونەوە'),
      PhotoWorkAction.correctionRequested => _t(s, 'تصحيح مطلوب', 'Correction requested', 'چاکسازی'),
      PhotoWorkAction.submitted => _t(s, 'مُسلَّم', 'Submitted', 'نێردراو'),
      PhotoWorkAction.approved => _t(s, 'معتمد', 'Approved', 'پەسەند'),
      PhotoWorkAction.completed => _t(s, 'مكتمل', 'Completed', 'تەواو'),
    };

String labelSt(PhotoStrings s, PhotoJobStatus st) => switch (st) {
      PhotoJobStatus.assigned => _t(s, 'معيَّن', 'Assigned', 'دیاریکراو'),
      PhotoJobStatus.visitScheduled => _t(s, 'زيارة مجدولة', 'Visit scheduled', 'سەردان'),
      PhotoJobStatus.inProgress => _t(s, 'جارٍ', 'In progress', 'بەردەوام'),
      PhotoJobStatus.review => _t(s, 'مراجعة', 'Review', 'پێداچوونەوە'),
      PhotoJobStatus.correctionRequired => _t(s, 'تصحيح', 'Correction', 'چاکسازی'),
      PhotoJobStatus.submitted => _t(s, 'مُسلَّم', 'Submitted', 'نێردراو'),
      PhotoJobStatus.approved => _t(s, 'معتمد', 'Approved', 'پەسەند'),
      PhotoJobStatus.archived => _t(s, 'أرشيف', 'Archived', 'ئەرشیف'),
    };

String labelShot(PhotoStrings s, ShotType t) => switch (t) {
      ShotType.wide => _t(s, 'لقطة واسعة', 'Wide', 'فراوان'),
      ShotType.corner => _t(s, 'زاوية', 'Corner', 'گۆشە'),
      ShotType.feature => _t(s, 'ميزة', 'Feature', 'تایبەتمەندی'),
      ShotType.detail => _t(s, 'تفصيل', 'Detail', 'وردەکاری'),
      ShotType.windowView => _t(s, 'إطلالة النافذة', 'Window view', 'پەنجەرە'),
      ShotType.entranceView => _t(s, 'المدخل', 'Entrance', 'دەروازە'),
      ShotType.special => _t(s, 'ميزة خاصة', 'Special', 'تایبەت'),
    };

String labelCat(PhotoStrings s, PhotoCategory c) => switch (c) {
      PhotoCategory.exterior => _t(s, 'خارجي', 'Exterior', 'دەرەوە'),
      PhotoCategory.interior => _t(s, 'داخلي', 'Interior', 'ناوخۆ'),
      PhotoCategory.room => _t(s, 'غرف', 'Rooms', 'ژوور'),
      PhotoCategory.amenity => _t(s, 'مرافق', 'Amenities', 'خزمەتگوزاری'),
      PhotoCategory.technical => _t(s, 'تقني', 'Technical', 'تەکنیکی'),
      PhotoCategory.document => _t(s, 'مستندات', 'Documents', 'بەڵگە'),
      PhotoCategory.tour3d => _t(s, 'ثلاثي الأبعاد', '3D', '٣د'),
      PhotoCategory.pano360 => _t(s, '٣٦٠°', '360°', '٣٦٠°'),
      PhotoCategory.other => _t(s, 'أخرى', 'Other', 'تر'),
    };

String labelVis(PhotoStrings s, MediaVisibility v) => switch (v) {
      MediaVisibility.public_ => _t(s, 'عام', 'Public', 'گشتی'),
      MediaVisibility.internal => _t(s, 'داخلي', 'Internal', 'ناوخۆیی'),
      MediaVisibility.technical => _t(s, 'تقني', 'Technical', 'تەکنیکی'),
      MediaVisibility.restricted => _t(s, 'مقيّد', 'Restricted', 'سنووردار'),
    };

String labelStream(PhotoStrings s, StreamStatus st) => switch (st) {
      StreamStatus.pending => _t(s, 'معلّق', 'Pending', 'چاوەڕوان'),
      StreamStatus.inProgress => _t(s, 'جارٍ', 'In progress', 'بەردەوام'),
      StreamStatus.completed => _t(s, 'مكتمل', 'Completed', 'تەواو'),
      StreamStatus.waiting => _t(s, 'بانتظار البيانات', 'Waiting', 'چاوەڕوان'),
    };

String labelSync(PhotoStrings s, SyncState st) => switch (st) {
      SyncState.saved => s.save,
      SyncState.saving => s.saving,
      SyncState.offline => s.offline,
      SyncState.synced => s.synced,
    };

String fmtWhen(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
