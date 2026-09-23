import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'sallahha_localizations_ar.dart';
import 'sallahha_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SallahhaLocalizations
/// returned by `SallahhaLocalizations.of(context)`.
///
/// Applications need to include `SallahhaLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/sallahha_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SallahhaLocalizations.localizationsDelegates,
///   supportedLocales: SallahhaLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SallahhaLocalizations.supportedLocales
/// property.
abstract class SallahhaLocalizations {
  SallahhaLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SallahhaLocalizations of(BuildContext context) {
    return Localizations.of<SallahhaLocalizations>(
      context,
      SallahhaLocalizations,
    )!;
  }

  static const LocalizationsDelegate<SallahhaLocalizations> delegate =
      _SallahhaLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'صلّحها — إدارة الصيانة الميدانية'**
  String get appTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات، الفنيون، والمتابعة — نسخة التأسيس'**
  String get homeSubtitle;

  /// No description provided for @greetingPrefix.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا'**
  String get greetingPrefix;

  /// No description provided for @foundationOk.
  ///
  /// In ar, this message translates to:
  /// **'التأسيس يعمل. المرحلة التالية: المصادقة والطلبات.'**
  String get foundationOk;

  /// No description provided for @navRequests.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get navRequests;

  /// No description provided for @navJobs.
  ///
  /// In ar, this message translates to:
  /// **'مهامي'**
  String get navJobs;

  /// No description provided for @navDispatch.
  ///
  /// In ar, this message translates to:
  /// **'التوزيع'**
  String get navDispatch;

  /// No description provided for @navReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get navReports;

  /// No description provided for @navProfile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navProfile;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'دخول آمن بمعلوماتك — أو جرّب بوضع العرض التجريبي'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @signInAction.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signInAction;

  /// No description provided for @signOutAction.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get signOutAction;

  /// No description provided for @createAccountAction.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createAccountAction;

  /// No description provided for @demoModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع العرض التجريبي (مقابلات)'**
  String get demoModeTitle;

  /// No description provided for @demoModeBody.
  ///
  /// In ar, this message translates to:
  /// **'بدون بيانات حقيقية — واجهات مملوءة لعرض المنتج، كلمة المرور demo1234'**
  String get demoModeBody;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل بياناتك وابدأ — يستغرق أقل من دقيقة'**
  String get registerSubtitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get registerNameLabel;

  /// No description provided for @registerPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get registerPhoneLabel;

  /// No description provided for @registerRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get registerRoleLabel;

  /// No description provided for @registerAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل'**
  String get registerAction;

  /// No description provided for @loginInstead.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب؟ سجّل الدخول'**
  String get loginInstead;

  /// No description provided for @registerCheckEmail.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب — تحقق من بريدك لتأكيده ثم سجّل الدخول'**
  String get registerCheckEmail;

  /// No description provided for @registerEmailTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد مستخدم بالفعل'**
  String get registerEmailTaken;

  /// No description provided for @registerPasswordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ٨ أحرف على الأقل'**
  String get registerPasswordShort;

  /// No description provided for @demoHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمات المرور تجريبية فقط ولا تستخدم بيانات حقيقية'**
  String get demoHint;

  /// No description provided for @roleCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get roleCustomer;

  /// No description provided for @roleTechnician.
  ///
  /// In ar, this message translates to:
  /// **'فني'**
  String get roleTechnician;

  /// No description provided for @roleSupervisor.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get roleSupervisor;

  /// No description provided for @roleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get roleAdmin;

  /// No description provided for @statusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get statusNew;

  /// No description provided for @statusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسند'**
  String get statusAssigned;

  /// No description provided for @statusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get statusAccepted;

  /// No description provided for @statusOnTheWay.
  ///
  /// In ar, this message translates to:
  /// **'في الطريق'**
  String get statusOnTheWay;

  /// No description provided for @statusArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصل'**
  String get statusArrived;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get statusInProgress;

  /// No description provided for @statusWaitingForParts.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار قطع'**
  String get statusWaitingForParts;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @priorityNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادية'**
  String get priorityNormal;

  /// No description provided for @priorityHigh.
  ///
  /// In ar, this message translates to:
  /// **'عالية'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة'**
  String get priorityUrgent;

  /// No description provided for @actionRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get actionConfirm;

  /// No description provided for @actionSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get actionSave;

  /// No description provided for @actionAssign.
  ///
  /// In ar, this message translates to:
  /// **'إسناد'**
  String get actionAssign;

  /// No description provided for @actionRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get actionRefresh;

  /// No description provided for @stateLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل…'**
  String get stateLoading;

  /// No description provided for @stateEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناصر بعد'**
  String get stateEmpty;

  /// No description provided for @stateError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get stateError;

  /// No description provided for @stateOffline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال — التغييرات محفوظة وستُزامَن'**
  String get stateOffline;

  /// No description provided for @stateOnline.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get stateOnline;

  /// No description provided for @syncPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المزامنة'**
  String get syncPending;

  /// No description provided for @syncSynced.
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة'**
  String get syncSynced;

  /// No description provided for @syncFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت المزامنة'**
  String get syncFailed;

  /// No description provided for @unauthorizedTitle.
  ///
  /// In ar, this message translates to:
  /// **'غير مصرح'**
  String get unauthorizedTitle;

  /// No description provided for @unauthorizedBody.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول بالدور المناسب للمتابعة'**
  String get unauthorizedBody;

  /// No description provided for @errorIllegalTransition.
  ///
  /// In ar, this message translates to:
  /// **'انتقال غير مسموح من هذه الحالة'**
  String get errorIllegalTransition;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية لهذا الإجراء'**
  String get errorPermissionDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العنصر غير موجود'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الحقول المطلوبة'**
  String get errorValidation;

  /// No description provided for @errorSyncFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت المزامنة — سيُعاد المحاولة'**
  String get errorSyncFailed;

  /// No description provided for @errorUnauthorized.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة — سجّل الدخول مجددًا'**
  String get errorUnauthorized;

  /// No description provided for @pagePlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'شاشة مبدئية — تُبنى في المرحلة ٣'**
  String get pagePlaceholder;

  /// No description provided for @newRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب صيانة جديد'**
  String get newRequestTitle;

  /// No description provided for @formServiceType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الخدمة'**
  String get formServiceType;

  /// No description provided for @formDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف المشكلة'**
  String get formDescription;

  /// No description provided for @formDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: التكييف ما بيبردش وطالع هواء دافئ'**
  String get formDescriptionHint;

  /// No description provided for @formAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get formAddress;

  /// No description provided for @formGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get formGovernorate;

  /// No description provided for @formPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get formPhone;

  /// No description provided for @formSlot.
  ///
  /// In ar, this message translates to:
  /// **'الموعد المفضل'**
  String get formSlot;

  /// No description provided for @formSlotHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: بكرة بعد العصر'**
  String get formSlotHint;

  /// No description provided for @formSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get formSubmit;

  /// No description provided for @validationHint.
  ///
  /// In ar, this message translates to:
  /// **'الوصف ١٠ أحرف على الأقل، والعنوان ٨، ورقم الموبايل 01xxxxxxxxx'**
  String get validationHint;

  /// No description provided for @signInFailed.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدخول غير صحيحة'**
  String get signInFailed;

  /// No description provided for @queueTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get queueTitle;

  /// No description provided for @queueNew.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get queueNew;

  /// No description provided for @queueActive.
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get queueActive;

  /// No description provided for @queueOverdue.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get queueOverdue;

  /// No description provided for @queueDone.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get queueDone;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث برقم الطلب أو الموبايل'**
  String get searchHint;

  /// No description provided for @workloadTitle.
  ///
  /// In ar, this message translates to:
  /// **'عبء الفنيين'**
  String get workloadTitle;

  /// No description provided for @activeJobsSuffix.
  ///
  /// In ar, this message translates to:
  /// **'مهام نشطة'**
  String get activeJobsSuffix;

  /// No description provided for @assignTitle.
  ///
  /// In ar, this message translates to:
  /// **'إسناد إلى فني'**
  String get assignTitle;

  /// No description provided for @priorityTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأولوية'**
  String get priorityTitle;

  /// No description provided for @slaDueLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاستحقاق'**
  String get slaDueLabel;

  /// No description provided for @overdueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get overdueLabel;

  /// No description provided for @detailsTimeline.
  ///
  /// In ar, this message translates to:
  /// **'التتبع'**
  String get detailsTimeline;

  /// No description provided for @detailsNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get detailsNotes;

  /// No description provided for @detailsPhotos.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get detailsPhotos;

  /// No description provided for @detailsParts.
  ///
  /// In ar, this message translates to:
  /// **'قطع الغيار'**
  String get detailsParts;

  /// No description provided for @detailsAssignment.
  ///
  /// In ar, this message translates to:
  /// **'الإسناد'**
  String get detailsAssignment;

  /// No description provided for @noteDiagnosisHint.
  ///
  /// In ar, this message translates to:
  /// **'التشخيص…'**
  String get noteDiagnosisHint;

  /// No description provided for @noteLaborHint.
  ///
  /// In ar, this message translates to:
  /// **'ما تم تنفيذه…'**
  String get noteLaborHint;

  /// No description provided for @addNoteAction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ملاحظة'**
  String get addNoteAction;

  /// No description provided for @partsCatalogTitle.
  ///
  /// In ar, this message translates to:
  /// **'كتالوج القطع'**
  String get partsCatalogTitle;

  /// No description provided for @qtyLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get qtyLabel;

  /// No description provided for @estimateLabel.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة التقديرية'**
  String get estimateLabel;

  /// No description provided for @setEstimateAction.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التقدير'**
  String get setEstimateAction;

  /// No description provided for @confirmCompletion.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد استلام العمل'**
  String get confirmCompletion;

  /// No description provided for @ratingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيّم الخدمة'**
  String get ratingTitle;

  /// No description provided for @ratingSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التقييم'**
  String get ratingSubmit;

  /// No description provided for @confirmedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم التأكيد — شكرًا لك'**
  String get confirmedMessage;

  /// No description provided for @cancelReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء…'**
  String get cancelReasonHint;

  /// No description provided for @myJobsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهامي'**
  String get myJobsTitle;

  /// No description provided for @triageSuggestion.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح الفرز'**
  String get triageSuggestion;

  /// No description provided for @triageConfirmHint.
  ///
  /// In ar, this message translates to:
  /// **'راجعه المشرف ووافق عليه'**
  String get triageConfirmHint;

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTitle;

  /// No description provided for @reportsCompleted.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مكتملة'**
  String get reportsCompleted;

  /// No description provided for @reportsAvgRating.
  ///
  /// In ar, this message translates to:
  /// **'متوسط التقييم'**
  String get reportsAvgRating;

  /// No description provided for @reportsOverdue.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة الآن'**
  String get reportsOverdue;

  /// No description provided for @navInbox.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get navInbox;

  /// No description provided for @inboxTitle.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get inboxTitle;

  /// No description provided for @collectCashAction.
  ///
  /// In ar, this message translates to:
  /// **'تحصيل نقدي'**
  String get collectCashAction;

  /// No description provided for @collectCardAction.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة تجريبية'**
  String get collectCardAction;

  /// No description provided for @paymentStateLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get paymentStateLabel;

  /// No description provided for @photoBeforeAction.
  ///
  /// In ar, this message translates to:
  /// **'صورة قبل'**
  String get photoBeforeAction;

  /// No description provided for @photoAfterAction.
  ///
  /// In ar, this message translates to:
  /// **'صورة بعد'**
  String get photoAfterAction;

  /// No description provided for @photoInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الصورة يجب أن تكون jpg أو png وبحد أقصى ٥ م.ب'**
  String get photoInvalid;

  /// No description provided for @actionSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get actionSkip;

  /// No description provided for @actionNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get actionNext;

  /// No description provided for @actionStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get actionStart;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك في صلّحها'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الصيانة الميدانية لأجهزة التكييف — من استقبال الطلب حتى إتمامه، كل شيء في مكان واحد.'**
  String get onbWelcomeBody;

  /// No description provided for @onbWelcomeTagline.
  ///
  /// In ar, this message translates to:
  /// **'صيانة تكييف احترافية تبدأ هنا'**
  String get onbWelcomeTagline;

  /// No description provided for @onbRequestsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات منظمة من البداية'**
  String get onbRequestsTitle;

  /// No description provided for @onbRequestsBody.
  ///
  /// In ar, this message translates to:
  /// **'العميل يصنع الطلب ويحدد الموعد، يفصلّه النظام حسب الأولوية، ويصل للفني مباشرة.'**
  String get onbRequestsBody;

  /// No description provided for @onbOfflineTitle.
  ///
  /// In ar, this message translates to:
  /// **'يعمل بدون إنترنت'**
  String get onbOfflineTitle;

  /// No description provided for @onbOfflineBody.
  ///
  /// In ar, this message translates to:
  /// **'كل التغييرات تُحفظ أولًا على الجهاز وتُزامَن تلقائيًا عند عودة الاتصال — حتي في المناطق النائية.'**
  String get onbOfflineBody;

  /// No description provided for @onbTeamTitle.
  ///
  /// In ar, this message translates to:
  /// **'فريقك متصل في كل لحظة'**
  String get onbTeamTitle;

  /// No description provided for @onbTeamBody.
  ///
  /// In ar, this message translates to:
  /// **'عملاء، فنيون، مشرفون، ومديرون — لكل دور واجهته ومتابعته اللحظية من التوزيع حتى التقارير.'**
  String get onbTeamBody;
}

class _SallahhaLocalizationsDelegate
    extends LocalizationsDelegate<SallahhaLocalizations> {
  const _SallahhaLocalizationsDelegate();

  @override
  Future<SallahhaLocalizations> load(Locale locale) {
    return SynchronousFuture<SallahhaLocalizations>(
      lookupSallahhaLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SallahhaLocalizationsDelegate old) => false;
}

SallahhaLocalizations lookupSallahhaLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return SallahhaLocalizationsAr();
    case 'en':
      return SallahhaLocalizationsEn();
  }

  throw FlutterError(
    'SallahhaLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
