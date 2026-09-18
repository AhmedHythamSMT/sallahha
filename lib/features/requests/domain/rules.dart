import 'package:sallahha/core/errors/app_error.dart';
import 'package:sallahha/features/jobs/domain/job_status.dart';

/// SLA + validation rules. Pure functions, unit-tested.
bool isOverdue(DateTime slaDueAt, String status, DateTime now) {
  if (status == 'completed' || status == 'cancelled') return false;
  return now.isAfter(slaDueAt);
}

DateTime defaultSlaDue(DateTime createdAt, int slaHours) =>
    createdAt.add(Duration(hours: slaHours));

/// Egyptian mobile: 01xxxxxxxxx (11 digits). Landlines out of MVP scope.
bool isValidEgyptPhone(String phone) =>
    RegExp(r'^01[0-9]{9}$').hasMatch(phone.trim());

String? validateDraft({
  required String description,
  required String address,
  required String governorate,
  required String phone,
}) {
  if (description.trim().length < 10) return 'description';
  if (address.trim().length < 8) return 'address';
  if (governorate.trim().isEmpty) return 'governorate';
  if (!isValidEgyptPhone(phone)) return 'phone';
  return null;
}

/// Throws nothing: returns the error for illegal transitions so the
/// repository can wrap it in Result.
AppError? checkTransition(String from, String to) =>
    canTransition(from, to) ? null : IllegalTransition(from, nextStates(from));
