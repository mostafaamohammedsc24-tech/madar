import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/field_strings.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart';
import '../../domain/enums/field_enums.dart';

LegalTone tonePri(FieldPriority p) => switch (p) {
      FieldPriority.urgent || FieldPriority.blocked => LegalTone.danger,
      FieldPriority.priority => LegalTone.warning,
      FieldPriority.normal => LegalTone.active,
    };

LegalTone toneSt(FieldReportStatus s) => switch (s) {
      FieldReportStatus.approved => LegalTone.success,
      FieldReportStatus.correctionRequired => LegalTone.danger,
      FieldReportStatus.submitted || FieldReportStatus.inProgress || FieldReportStatus.draft => LegalTone.warning,
      _ => LegalTone.active,
    };

String _t(FieldStrings s, String ar, String en, String ku) {
  switch (s.lang) {
    case AppLanguage.kurdish:
      return ku;
    case AppLanguage.english:
      return en;
    case AppLanguage.arabic:
      return ar;
  }
}

String labelPri(FieldStrings s, FieldPriority p) => switch (p) {
      FieldPriority.normal => _t(s, 'عادي', 'Normal', 'ئاسایی'),
      FieldPriority.priority => s.lang.name == 'english' ? 'Priority' : s.lang.name == 'kurdish' ? 'گرنگ' : 'أولوية',
      FieldPriority.urgent => _t(s, 'عاجل', 'Urgent', 'فوری'),
      FieldPriority.blocked => _t(s, 'متوقف', 'Blocked', 'وەستاو'),
    };

String labelAct(FieldStrings s, FieldWorkAction a) => switch (a) {
      FieldWorkAction.newAssignment => _t(s, 'تكليف جديد', 'New assignment', 'ئەرکی نوێ'),
      FieldWorkAction.scheduledVisit => _t(s, 'زيارة مجدولة', 'Scheduled visit', 'سەردانی خشتەکراو'),
      FieldWorkAction.inProgress => _t(s, 'قيد المعاينة', 'In progress', 'لە پشکنین'),
      FieldWorkAction.draftReport => _t(s, 'مسودة تقرير', 'Draft report', 'ڕەشنووسی ڕاپۆرت'),
      FieldWorkAction.correctionRequested => _t(s, 'تصحيح مطلوب', 'Correction requested', 'چاکسازی'),
      FieldWorkAction.submitted => _t(s, 'مُسلَّم', 'Submitted', 'نێردراو'),
      FieldWorkAction.approved => _t(s, 'معتمد', 'Approved', 'پەسەند'),
      FieldWorkAction.completed => _t(s, 'مكتمل', 'Completed', 'تەواو'),
    };

String labelSt(FieldStrings s, FieldReportStatus st) => switch (st) {
      FieldReportStatus.assigned => _t(s, 'معيَّن', 'Assigned', 'دیاریکراو'),
      FieldReportStatus.visitScheduled => _t(s, 'زيارة مجدولة', 'Visit scheduled', 'سەردان'),
      FieldReportStatus.inProgress => _t(s, 'جارٍ', 'In progress', 'بەردەوام'),
      FieldReportStatus.draft => _t(s, 'مسودة', 'Draft', 'ڕەشنووس'),
      FieldReportStatus.correctionRequired => _t(s, 'تصحيح', 'Correction', 'چاکسازی'),
      FieldReportStatus.submitted => _t(s, 'مُسلَّم', 'Submitted', 'نێردراو'),
      FieldReportStatus.approved => _t(s, 'معتمد', 'Approved', 'پەسەند'),
      FieldReportStatus.archived => _t(s, 'أرشيف', 'Archived', 'ئەرشیف'),
    };

String labelStream(FieldStrings s, StreamStatus st) => switch (st) {
      StreamStatus.pending => _t(s, 'معلّق', 'Pending', 'چاوەڕوان'),
      StreamStatus.inProgress => _t(s, 'جارٍ', 'In progress', 'بەردەوام'),
      StreamStatus.completed => _t(s, 'مكتمل', 'Completed', 'تەواو'),
      StreamStatus.waiting => _t(s, 'بانتظار البيانات', 'Waiting for data', 'چاوەڕوانی داتا'),
    };

String sectionName(FieldStrings s, String id) => switch (id) {
      'identity' => _t(s, 'الهوية', 'Identity', 'ناسنامە'),
      'location' => _t(s, 'الموقع', 'Location', 'شوێن'),
      'land' => s.land,
      'building' => s.building,
      'rooms' => s.rooms,
      'utilities' => _t(s, 'المرافق', 'Utilities', 'خزمەتگوزاری'),
      'neighborhood' => _t(s, 'الحي', 'Neighborhood', 'گەڕەک'),
      'development' => s.development,
      'inspection' => s.inspection,
      _ => id,
    };

String fmtWhen(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String labelCond(FieldStrings s, RoomCondition c) => switch (c) {
      RoomCondition.excellent => _t(s, 'ممتاز', 'Excellent', 'نایاب'),
      RoomCondition.veryGood => _t(s, 'جيد جداً', 'Very good', 'زۆر باش'),
      RoomCondition.good => _t(s, 'جيد', 'Good', 'باش'),
      RoomCondition.fair => _t(s, 'مقبول', 'Fair', 'مامناوەند'),
      RoomCondition.needsRenovation => _t(s, 'يحتاج ترميم', 'Needs renovation', 'پێویستی بە چاککردن'),
      RoomCondition.majorRenovation => _t(s, 'ترميم شامل', 'Major renovation', 'چاککردنی گەورە'),
      RoomCondition.unsafe => _t(s, 'غير آمن / يحتاج فحص', 'Unsafe / inspect', 'ناپارێزراو'),
    };

String labelSync(FieldStrings s, SyncState st) => switch (st) {
      SyncState.saved => s.save,
      SyncState.saving => s.saving,
      SyncState.offline => s.offline,
      SyncState.synced => s.synced,
    };
