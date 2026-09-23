// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'sallahha_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SallahhaLocalizationsEn extends SallahhaLocalizations {
  SallahhaLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sallahha FieldOps';

  @override
  String get homeSubtitle =>
      'Requests, technicians, tracking — foundation build';

  @override
  String get greetingPrefix => 'Hello';

  @override
  String get foundationOk => 'Foundation running. Next: auth and requests.';

  @override
  String get navRequests => 'Requests';

  @override
  String get navJobs => 'My jobs';

  @override
  String get navDispatch => 'Dispatch';

  @override
  String get navReports => 'Reports';

  @override
  String get navProfile => 'Profile';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Secure sign-in to your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signOutAction => 'Sign out';

  @override
  String get createAccountAction => 'Create account';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle =>
      'Enter your details and get started — under a minute';

  @override
  String get registerNameLabel => 'Full name';

  @override
  String get registerPhoneLabel => 'Mobile number';

  @override
  String get registerRoleLabel => 'Role';

  @override
  String get registerAction => 'Sign up';

  @override
  String get loginInstead => 'Already have an account? Sign in';

  @override
  String get registerCheckEmail =>
      'Account created — check your inbox to confirm, then sign in';

  @override
  String get registerEmailTaken => 'This email is already registered';

  @override
  String get registerPasswordShort => 'Password must be at least 8 characters';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleTechnician => 'Technician';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get statusNew => 'New';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusArrived => 'Arrived';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusWaitingForParts => 'Waiting for parts';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionSave => 'Save';

  @override
  String get actionAssign => 'Assign';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateEmpty => 'Nothing here yet';

  @override
  String get stateError => 'Something went wrong';

  @override
  String get stateOffline => 'Offline — changes are saved and will sync';

  @override
  String get stateOnline => 'Online';

  @override
  String get syncPending => 'Pending sync';

  @override
  String get syncSynced => 'Synced';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get unauthorizedTitle => 'Unauthorized';

  @override
  String get unauthorizedBody => 'Sign in with the right role to continue';

  @override
  String get errorIllegalTransition => 'Transition not allowed from this state';

  @override
  String get errorPermissionDenied => 'You lack permission for this action';

  @override
  String get errorNotFound => 'Item not found';

  @override
  String get errorValidation => 'Check the required fields';

  @override
  String get errorSyncFailed => 'Sync failed — will retry';

  @override
  String get errorUnauthorized => 'Session expired — sign in again';

  @override
  String get pagePlaceholder => 'Placeholder screen — built in Phase 3';

  @override
  String get newRequestTitle => 'New maintenance request';

  @override
  String get formServiceType => 'Service type';

  @override
  String get formDescription => 'Problem description';

  @override
  String get formDescriptionHint => 'e.g. AC blows warm air, no cooling';

  @override
  String get formAddress => 'Address';

  @override
  String get formGovernorate => 'Governorate';

  @override
  String get formPhone => 'Mobile number';

  @override
  String get formSlot => 'Preferred time';

  @override
  String get formSlotHint => 'e.g. tomorrow afternoon';

  @override
  String get formSubmit => 'Submit request';

  @override
  String get validationHint =>
      'Description ≥10 chars, address ≥8, mobile 01xxxxxxxxx';

  @override
  String get signInFailed => 'Invalid credentials';

  @override
  String get queueTitle => 'Requests';

  @override
  String get queueNew => 'New';

  @override
  String get queueActive => 'Active';

  @override
  String get queueOverdue => 'Overdue';

  @override
  String get queueDone => 'Done';

  @override
  String get searchHint => 'Search by ID or phone';

  @override
  String get workloadTitle => 'Technician workload';

  @override
  String get activeJobsSuffix => 'active jobs';

  @override
  String get assignTitle => 'Assign technician';

  @override
  String get priorityTitle => 'Priority';

  @override
  String get slaDueLabel => 'Due';

  @override
  String get overdueLabel => 'Overdue';

  @override
  String get detailsTimeline => 'Timeline';

  @override
  String get detailsNotes => 'Notes';

  @override
  String get detailsPhotos => 'Photos';

  @override
  String get detailsParts => 'Parts';

  @override
  String get detailsAssignment => 'Assignment';

  @override
  String get noteDiagnosisHint => 'Diagnosis…';

  @override
  String get noteLaborHint => 'Work done…';

  @override
  String get addNoteAction => 'Add note';

  @override
  String get partsCatalogTitle => 'Parts catalog';

  @override
  String get qtyLabel => 'Qty';

  @override
  String get estimateLabel => 'Estimated cost';

  @override
  String get setEstimateAction => 'Save estimate';

  @override
  String get confirmCompletion => 'Confirm work received';

  @override
  String get ratingTitle => 'Rate the service';

  @override
  String get ratingSubmit => 'Submit rating';

  @override
  String get confirmedMessage => 'Confirmed — thank you';

  @override
  String get cancelReasonHint => 'Cancel reason…';

  @override
  String get myJobsTitle => 'My jobs';

  @override
  String get triageSuggestion => 'Triage suggestion';

  @override
  String get triageConfirmHint => 'Reviewed and confirmed by supervisor';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsCompleted => 'Completed requests';

  @override
  String get reportsAvgRating => 'Average rating';

  @override
  String get reportsOverdue => 'Overdue now';

  @override
  String get navInbox => 'Notifications';

  @override
  String get inboxTitle => 'Notifications';

  @override
  String get collectCashAction => 'Collect cash';

  @override
  String get collectCardAction => 'Test card';

  @override
  String get paymentStateLabel => 'Payment';

  @override
  String get photoBeforeAction => 'Before photo';

  @override
  String get photoAfterAction => 'After photo';

  @override
  String get photoInvalid => 'Photo must be jpg/png and at most 5 MB';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionNext => 'Next';

  @override
  String get actionStart => 'Get started';

  @override
  String get onbWelcomeTitle => 'Welcome to Sallahha';

  @override
  String get onbWelcomeBody =>
      'AC field-service management — from request to completion, all in one place.';

  @override
  String get onbWelcomeTagline => 'Professional AC maintenance starts here';

  @override
  String get onbRequestsTitle => 'Organized requests';

  @override
  String get onbRequestsBody =>
      'Customers create requests with a preferred slot, the system triages, and technicians pick them up.';

  @override
  String get onbOfflineTitle => 'Works offline';

  @override
  String get onbOfflineBody =>
      'Changes save to the device first and sync automatically when back online — even in remote areas.';

  @override
  String get onbTeamTitle => 'Your team, always connected';

  @override
  String get onbTeamBody =>
      'Customers, technicians, supervisors, and admins — each role gets its own live view, from dispatch to reports.';
}
