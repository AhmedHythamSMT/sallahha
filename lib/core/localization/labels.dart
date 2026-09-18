import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';

/// Localized labels for domain enums. Keeps widgets free of hardcoded
/// Arabic/English and free of switch-statements scattered across features.
extension StatusLabels on SallahhaLocalizations {
  String statusLabel(String status) => switch (status) {
    'new' => statusNew,
    'assigned' => statusAssigned,
    'accepted' => statusAccepted,
    'on_the_way' => statusOnTheWay,
    'arrived' => statusArrived,
    'in_progress' => statusInProgress,
    'waiting_for_parts' => statusWaitingForParts,
    'completed' => statusCompleted,
    'cancelled' => statusCancelled,
    _ => status,
  };

  String priorityLabel(String priority) => switch (priority) {
    'normal' => priorityNormal,
    'high' => priorityHigh,
    'urgent' => priorityUrgent,
    _ => priority,
  };

  String roleLabel(String role) => switch (role) {
    'customer' => roleCustomer,
    'technician' => roleTechnician,
    'supervisor' => roleSupervisor,
    'admin' => roleAdmin,
    _ => role,
  };
}
