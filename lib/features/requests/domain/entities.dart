// Pure-Dart domain entities. No Flutter, no Drift imports —
// data layer maps rows/JSON to these.
class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role; // customer|technician|supervisor|admin
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
  });
}

class ServiceInfo {
  final String id;
  final String code;
  final String nameAr;
  final String nameEn;
  final int defaultSlaHours;
  const ServiceInfo({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.defaultSlaHours,
  });
}

class ServiceRequest {
  final String id;
  final String customerId;
  final String serviceId;
  final String description;
  final String address;
  final String governorate;
  final String phone;
  final String? photoLocalPath;
  final String priority;
  final String status;
  final DateTime slaDueAt;
  final int? estimateEgp;
  final String idempotencyKey;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ServiceRequest({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.description,
    required this.address,
    required this.governorate,
    required this.phone,
    this.photoLocalPath,
    required this.priority,
    required this.status,
    required this.slaDueAt,
    this.estimateEgp,
    required this.idempotencyKey,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
}

class StatusEvent {
  final String requestId;
  final String from;
  final String to;
  final String byUserId;
  final String? reason;
  final DateTime createdAt;
  const StatusEvent({
    required this.requestId,
    required this.from,
    required this.to,
    required this.byUserId,
    this.reason,
    required this.createdAt,
  });
}

class JobNote {
  final String requestId;
  final String authorId;
  final String kind; // diagnosis|labor
  final String body;
  final DateTime createdAt;
  const JobNote({
    required this.requestId,
    required this.authorId,
    required this.kind,
    required this.body,
    required this.createdAt,
  });
}

class JobPhoto {
  final String requestId;
  final String kind; // before|after|other|signature
  final String localPath;
  const JobPhoto({
    required this.requestId,
    required this.kind,
    required this.localPath,
  });
}

class PartUsage {
  final String partId;
  final String partName;
  final int priceEgp;
  final int qty;
  const PartUsage({
    required this.partId,
    required this.partName,
    required this.priceEgp,
    required this.qty,
  });
}

/// Catalog entry (cached locally for offline parts entry).
class PartInfo {
  final String id;
  final String nameAr;
  final String nameEn;
  final int priceEgp;
  const PartInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.priceEgp,
  });
}

class AssignmentInfo {
  final String id;
  final String requestId;
  final String technicianId;
  final String technicianName;
  final String assignedBy;
  const AssignmentInfo({
    required this.id,
    required this.requestId,
    required this.technicianId,
    required this.technicianName,
    required this.assignedBy,
  });
}

class RatingInfo {
  final String requestId;
  final int stars;
  final String? comment;
  const RatingInfo({
    required this.requestId,
    required this.stars,
    this.comment,
  });
}

/// Full detail bundle for the request/job details screens.
class RequestDetails {
  final ServiceRequest request;
  final List<StatusEvent> timeline;
  final List<JobNote> notes;
  final List<JobPhoto> photos;
  final List<PartUsage> parts;
  final AssignmentInfo? assignment;
  final RatingInfo? rating;
  final bool confirmed;
  const RequestDetails({
    required this.request,
    required this.timeline,
    required this.notes,
    required this.photos,
    required this.parts,
    this.assignment,
    this.rating,
    this.confirmed = false,
  });
}

/// Inbox entry (notifications table). Stored in Arabic (default locale).
class InboxItem {
  final int id;
  final String kind; // new_request|assignment|status|confirm|rating
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  const InboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });
}

/// Payment record (mock gateway; states mirror the payment machine).
class PaymentRecord {
  final String id;
  final int amountEgp;
  final String state; // pending|succeeded|failed|cancelled|timed_out
  final String? gatewayRef;
  final DateTime createdAt;
  const PaymentRecord({
    required this.id,
    required this.amountEgp,
    required this.state,
    this.gatewayRef,
    required this.createdAt,
  });
}

/// Customer-side create form. Validated in domain, not in widgets.
class RequestDraft {
  final String serviceId;
  final String description;
  final String address;
  final String governorate;
  final String phone;
  final String? photoLocalPath;
  final String? preferredSlot;
  const RequestDraft({
    required this.serviceId,
    required this.description,
    required this.address,
    required this.governorate,
    required this.phone,
    this.photoLocalPath,
    this.preferredSlot,
  });
}
