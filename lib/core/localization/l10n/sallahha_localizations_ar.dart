// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'sallahha_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class SallahhaLocalizationsAr extends SallahhaLocalizations {
  SallahhaLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'صلّحها — إدارة الصيانة الميدانية';

  @override
  String get homeSubtitle => 'الطلبات، الفنيون، والمتابعة — نسخة التأسيس';

  @override
  String get greetingPrefix => 'أهلًا';

  @override
  String get foundationOk =>
      'التأسيس يعمل. المرحلة التالية: المصادقة والطلبات.';

  @override
  String get navRequests => 'الطلبات';

  @override
  String get navJobs => 'مهامي';

  @override
  String get navDispatch => 'التوزيع';

  @override
  String get navReports => 'التقارير';

  @override
  String get navProfile => 'حسابي';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'دخول آمن بمعلوماتك';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get signInAction => 'دخول';

  @override
  String get signOutAction => 'خروج';

  @override
  String get createAccountAction => 'إنشاء حساب جديد';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get registerSubtitle => 'سجّل بياناتك وابدأ — يستغرق أقل من دقيقة';

  @override
  String get registerNameLabel => 'الاسم';

  @override
  String get registerPhoneLabel => 'رقم الموبايل';

  @override
  String get registerRoleLabel => 'الدور';

  @override
  String get registerAction => 'تسجيل';

  @override
  String get loginInstead => 'لديك حساب؟ سجّل الدخول';

  @override
  String get registerCheckEmail =>
      'تم إنشاء الحساب — تحقق من بريدك لتأكيده ثم سجّل الدخول';

  @override
  String get registerEmailTaken => 'هذا البريد مستخدم بالفعل';

  @override
  String get registerPasswordShort => 'كلمة المرور ٨ أحرف على الأقل';

  @override
  String get roleCustomer => 'عميل';

  @override
  String get roleTechnician => 'فني';

  @override
  String get roleSupervisor => 'مشرف';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get statusNew => 'جديد';

  @override
  String get statusAssigned => 'مُسند';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusOnTheWay => 'في الطريق';

  @override
  String get statusArrived => 'وصل';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusWaitingForParts => 'بانتظار قطع';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get priorityNormal => 'عادية';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionAssign => 'إسناد';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get stateLoading => 'جاري التحميل…';

  @override
  String get stateEmpty => 'لا توجد عناصر بعد';

  @override
  String get stateError => 'حدث خطأ';

  @override
  String get stateOffline => 'لا يوجد اتصال — التغييرات محفوظة وستُزامَن';

  @override
  String get stateOnline => 'متصل';

  @override
  String get syncPending => 'بانتظار المزامنة';

  @override
  String get syncSynced => 'تمت المزامنة';

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String get unauthorizedTitle => 'غير مصرح';

  @override
  String get unauthorizedBody => 'سجّل الدخول بالدور المناسب للمتابعة';

  @override
  String get errorIllegalTransition => 'انتقال غير مسموح من هذه الحالة';

  @override
  String get errorPermissionDenied => 'ليس لديك صلاحية لهذا الإجراء';

  @override
  String get errorNotFound => 'العنصر غير موجود';

  @override
  String get errorValidation => 'تحقق من الحقول المطلوبة';

  @override
  String get errorSyncFailed => 'تعذرت المزامنة — سيُعاد المحاولة';

  @override
  String get errorUnauthorized => 'انتهت الجلسة — سجّل الدخول مجددًا';

  @override
  String get pagePlaceholder => 'شاشة مبدئية — تُبنى في المرحلة ٣';

  @override
  String get newRequestTitle => 'طلب صيانة جديد';

  @override
  String get formServiceType => 'نوع الخدمة';

  @override
  String get formDescription => 'وصف المشكلة';

  @override
  String get formDescriptionHint => 'مثال: التكييف ما بيبردش وطالع هواء دافئ';

  @override
  String get formAddress => 'العنوان';

  @override
  String get formGovernorate => 'المحافظة';

  @override
  String get formPhone => 'رقم الموبايل';

  @override
  String get formSlot => 'الموعد المفضل';

  @override
  String get formSlotHint => 'مثال: بكرة بعد العصر';

  @override
  String get formSubmit => 'إرسال الطلب';

  @override
  String get validationHint =>
      'الوصف ١٠ أحرف على الأقل، والعنوان ٨، ورقم الموبايل 01xxxxxxxxx';

  @override
  String get signInFailed => 'بيانات الدخول غير صحيحة';

  @override
  String get queueTitle => 'الطلبات';

  @override
  String get queueNew => 'جديدة';

  @override
  String get queueActive => 'نشطة';

  @override
  String get queueOverdue => 'متأخرة';

  @override
  String get queueDone => 'منتهية';

  @override
  String get searchHint => 'بحث برقم الطلب أو الموبايل';

  @override
  String get workloadTitle => 'عبء الفنيين';

  @override
  String get activeJobsSuffix => 'مهام نشطة';

  @override
  String get assignTitle => 'إسناد إلى فني';

  @override
  String get priorityTitle => 'الأولوية';

  @override
  String get slaDueLabel => 'الاستحقاق';

  @override
  String get overdueLabel => 'متأخر';

  @override
  String get detailsTimeline => 'التتبع';

  @override
  String get detailsNotes => 'الملاحظات';

  @override
  String get detailsPhotos => 'الصور';

  @override
  String get detailsParts => 'قطع الغيار';

  @override
  String get detailsAssignment => 'الإسناد';

  @override
  String get noteDiagnosisHint => 'التشخيص…';

  @override
  String get noteLaborHint => 'ما تم تنفيذه…';

  @override
  String get addNoteAction => 'إضافة ملاحظة';

  @override
  String get partsCatalogTitle => 'كتالوج القطع';

  @override
  String get qtyLabel => 'الكمية';

  @override
  String get estimateLabel => 'التكلفة التقديرية';

  @override
  String get setEstimateAction => 'حفظ التقدير';

  @override
  String get confirmCompletion => 'تأكيد استلام العمل';

  @override
  String get ratingTitle => 'قيّم الخدمة';

  @override
  String get ratingSubmit => 'إرسال التقييم';

  @override
  String get confirmedMessage => 'تم التأكيد — شكرًا لك';

  @override
  String get cancelReasonHint => 'سبب الإلغاء…';

  @override
  String get myJobsTitle => 'مهامي';

  @override
  String get triageSuggestion => 'اقتراح الفرز';

  @override
  String get triageConfirmHint => 'راجعه المشرف ووافق عليه';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get reportsCompleted => 'طلبات مكتملة';

  @override
  String get reportsAvgRating => 'متوسط التقييم';

  @override
  String get reportsOverdue => 'متأخرة الآن';

  @override
  String get navInbox => 'التنبيهات';

  @override
  String get inboxTitle => 'التنبيهات';

  @override
  String get collectCashAction => 'تحصيل نقدي';

  @override
  String get collectCardAction => 'بطاقة تجريبية';

  @override
  String get paymentStateLabel => 'الدفع';

  @override
  String get photoBeforeAction => 'صورة قبل';

  @override
  String get photoAfterAction => 'صورة بعد';

  @override
  String get photoInvalid => 'الصورة يجب أن تكون jpg أو png وبحد أقصى ٥ م.ب';

  @override
  String get actionSkip => 'تخطي';

  @override
  String get actionNext => 'التالي';

  @override
  String get actionStart => 'ابدأ الآن';

  @override
  String get onbWelcomeTitle => 'أهلًا بك في صلّحها';

  @override
  String get onbWelcomeBody =>
      'إدارة الصيانة الميدانية لأجهزة التكييف — من استقبال الطلب حتى إتمامه، كل شيء في مكان واحد.';

  @override
  String get onbWelcomeTagline => 'صيانة تكييف احترافية تبدأ هنا';

  @override
  String get onbRequestsTitle => 'طلبات منظمة من البداية';

  @override
  String get onbRequestsBody =>
      'العميل يصنع الطلب ويحدد الموعد، يفصلّه النظام حسب الأولوية، ويصل للفني مباشرة.';

  @override
  String get onbOfflineTitle => 'يعمل بدون إنترنت';

  @override
  String get onbOfflineBody =>
      'كل التغييرات تُحفظ أولًا على الجهاز وتُزامَن تلقائيًا عند عودة الاتصال — حتي في المناطق النائية.';

  @override
  String get onbTeamTitle => 'فريقك متصل في كل لحظة';

  @override
  String get onbTeamBody =>
      'عملاء، فنيون، مشرفون، ومديرون — لكل دور واجهته ومتابعته اللحظية من التوزيع حتى التقارير.';
}
