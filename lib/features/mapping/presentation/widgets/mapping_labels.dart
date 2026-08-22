import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/mapping_strings.dart';
import '../../../legal/presentation/widgets/legal_status_chip.dart';
import '../../domain/enums/mapping_enums.dart';

LegalTone toneForPriority(MappingPriority p) {
  switch (p) {
    case MappingPriority.urgent:
      return LegalTone.danger;
    case MappingPriority.priority:
      return LegalTone.warning;
    case MappingPriority.blocked:
      return LegalTone.danger;
    case MappingPriority.normal:
      return LegalTone.active;
  }
}

LegalTone toneForStatus(MappingPlanStatus s) {
  switch (s) {
    case MappingPlanStatus.approved:
    case MappingPlanStatus.published:
      return LegalTone.success;
    case MappingPlanStatus.correctionRequired:
      return LegalTone.danger;
    case MappingPlanStatus.readyForReview:
    case MappingPlanStatus.inProgress:
      return LegalTone.warning;
    case MappingPlanStatus.draft:
      return LegalTone.active;
    case MappingPlanStatus.archived:
      return LegalTone.neutral;
  }
}

String labelPriority(MappingStrings s, MappingPriority p) {
  switch (p) {
    case MappingPriority.normal:
      return s.lang.name == 'english' ? 'Normal' : s.lang.name == 'kurdish' ? 'ئاسایی' : 'عادي';
    case MappingPriority.priority:
      return s.priority;
    case MappingPriority.urgent:
      return s.lang.name == 'english' ? 'Urgent' : s.lang.name == 'kurdish' ? 'فوری' : 'عاجل';
    case MappingPriority.blocked:
      return s.lang.name == 'english' ? 'Blocked' : s.lang.name == 'kurdish' ? 'وەستاو' : 'متوقف';
  }
}

String labelAction(MappingStrings s, MappingWorkAction a) {
  switch (a) {
    case MappingWorkAction.newRequest:
      return _t(s, 'طلب مخطط جديد', 'New floor plan request', 'داوای نەخشەی نوێ');
    case MappingWorkAction.inProgress:
      return _t(s, 'قيد التنفيذ', 'In progress', 'لە جێبەجێکردن');
    case MappingWorkAction.measurementReview:
      return _t(s, 'مراجعة القياسات', 'Measurement review', 'پێداچوونەوەی پێوانە');
    case MappingWorkAction.connectionRequired:
      return _t(s, 'يلزم ربط ثلاثي الأبعاد', '3D connection required', 'پەیوەندی ٣د پێویستە');
    case MappingWorkAction.correctionRequested:
      return _t(s, 'مطلوب تصحيح', 'Correction requested', 'چاکسازی داواکراوە');
    case MappingWorkAction.readyToSubmit:
      return _t(s, 'جاهز للتسليم', 'Ready for publishing handoff', 'ئامادەیە بۆ ناردن');
    case MappingWorkAction.completed:
      return _t(s, 'مكتمل', 'Completed', 'تەواو');
    case MappingWorkAction.blocked:
      return _t(s, 'متوقف', 'Blocked', 'وەستاو');
  }
}

String labelStatus(MappingStrings s, MappingPlanStatus st) {
  switch (st) {
    case MappingPlanStatus.draft:
      return _t(s, 'مسودة', 'Draft', 'ڕەشنووس');
    case MappingPlanStatus.inProgress:
      return _t(s, 'قيد التنفيذ', 'In progress', 'لە جێبەجێکردن');
    case MappingPlanStatus.readyForReview:
      return _t(s, 'جاهز للمراجعة', 'Ready for review', 'ئامادەی پێداچوونەوە');
    case MappingPlanStatus.correctionRequired:
      return _t(s, 'تصحيح مطلوب', 'Correction required', 'چاکسازی پێویست');
    case MappingPlanStatus.approved:
      return _t(s, 'معتمد', 'Approved', 'پەسەند');
    case MappingPlanStatus.published:
      return _t(s, 'منشور ضمن البطاقة', 'Published with listing', 'بڵاوکراوە');
    case MappingPlanStatus.archived:
      return _t(s, 'مؤرشف', 'Archived', 'ئەرشیف');
  }
}

String labelRoom(MappingStrings s, RoomKind k) {
  switch (k) {
    case RoomKind.bedroom:
      return _t(s, 'غرفة نوم', 'Bedroom', 'ژووری نووستن');
    case RoomKind.masterBedroom:
      return _t(s, 'غرفة نوم رئيسية', 'Master bedroom', 'ژووری سەرەکی');
    case RoomKind.living:
      return _t(s, 'معيشة', 'Living room', 'ژووری نیشتەجێ');
    case RoomKind.family:
      return _t(s, 'عائلي', 'Family room', 'خێزانی');
    case RoomKind.kitchen:
      return _t(s, 'مطبخ', 'Kitchen', 'چێشتخانە');
    case RoomKind.dining:
      return _t(s, 'طعام', 'Dining', 'نانخواردن');
    case RoomKind.bathroom:
      return _t(s, 'حمام', 'Bathroom', 'حەمام');
    case RoomKind.guestBathroom:
      return _t(s, 'حمام ضيوف', 'Guest bathroom', 'حەمامی میوان');
    case RoomKind.laundry:
      return _t(s, 'غسيل', 'Laundry', 'جلشۆر');
    case RoomKind.office:
      return _t(s, 'مكتب', 'Office', 'ئۆفیس');
    case RoomKind.storage:
      return _t(s, 'تخزين', 'Storage', 'کۆگا');
    case RoomKind.garage:
      return _t(s, 'كراج', 'Garage', 'گەراج');
    case RoomKind.hallway:
      return _t(s, 'ممر', 'Hallway', 'ڕێڕەو');
    case RoomKind.entrance:
      return _t(s, 'مدخل', 'Entrance', 'دەروازە');
    case RoomKind.balcony:
      return _t(s, 'شرفة', 'Balcony', 'باڵەکۆن');
    case RoomKind.terrace:
      return _t(s, 'تراس', 'Terrace', 'تەراس');
    case RoomKind.garden:
      return _t(s, 'حديقة', 'Garden', 'باخچە');
    case RoomKind.courtyard:
      return _t(s, 'فناء', 'Courtyard', 'حەوشە');
    case RoomKind.basement:
      return _t(s, 'قبو', 'Basement', 'ژێرزەمین');
    case RoomKind.retail:
      return _t(s, 'بيع تجزئة', 'Retail', 'فرۆشتن');
    case RoomKind.meeting:
      return _t(s, 'اجتماع', 'Meeting', 'کۆبوونەوە');
    case RoomKind.reception:
      return _t(s, 'استقبال', 'Reception', 'پێشوازی');
    case RoomKind.warehouse:
      return _t(s, 'مستودع', 'Warehouse', 'کۆگا');
    case RoomKind.parking:
      return _t(s, 'موقف', 'Parking', 'وەستان');
    case RoomKind.restroom:
      return _t(s, 'دورة مياه', 'Restroom', 'دەستشۆر');
    case RoomKind.custom:
      return _t(s, 'مخصص', 'Custom', 'تایبەت');
  }
}

String _t(MappingStrings s, String ar, String en, String ku) {
  switch (s.lang) {
    case AppLanguage.kurdish:
      return ku;
    case AppLanguage.english:
      return en;
    case AppLanguage.arabic:
      return ar;
  }
}

String fmtWhen(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
