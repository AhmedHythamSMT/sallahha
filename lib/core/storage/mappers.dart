import 'package:drift/drift.dart';
import 'package:sallahha/core/storage/app_database.dart' as drift;
import 'package:sallahha/features/requests/domain/entities.dart';

// Drift <-> entity mapping. Single place; repository never touches rows.

AppUser userFromCompanion(drift.UsersCompanion c) => AppUser(
  id: c.id.value,
  name: c.name.value,
  phone: c.phone.value,
  email: c.email.value,
  role: c.role.value,
);

AppUser userFromRow(drift.User r) => AppUser(
  id: r.id,
  name: r.name,
  phone: r.phone,
  email: r.email,
  role: r.role,
);

ServiceInfo serviceFromCompanion(drift.ServicesCompanion c) => ServiceInfo(
  id: c.id.value,
  code: c.code.value,
  nameAr: c.nameAr.value,
  nameEn: c.nameEn.value,
  defaultSlaHours: c.defaultSlaHours.value,
);

ServiceRequest requestFromCompanion(
  drift.ServiceRequestsCompanion c,
  DateTime now,
) {
  return ServiceRequest(
    id: c.id.value,
    customerId: c.customerId.value,
    serviceId: c.serviceId.value,
    description: c.description.value,
    address: c.address.value,
    governorate: c.governorate.value,
    phone: c.phone.value,
    priority: c.priority.present ? c.priority.value : 'normal',
    status: c.status.present ? c.status.value : 'new',
    slaDueAt: c.slaDueAt.value,
    idempotencyKey: c.idempotencyKey.value,
    version: 1,
    createdAt: now,
    updatedAt: now,
  );
}

ServiceRequest requestFromRow(drift.ServiceRequest r) => ServiceRequest(
  id: r.id,
  customerId: r.customerId,
  serviceId: r.serviceId,
  description: r.description,
  address: r.address,
  governorate: r.governorate,
  phone: r.phone,
  photoLocalPath: r.photoLocalPath,
  priority: r.priority,
  status: r.status,
  slaDueAt: r.slaDueAt,
  estimateEgp: r.estimateEgp,
  idempotencyKey: r.idempotencyKey,
  version: r.version,
  createdAt: r.createdAt,
  updatedAt: r.updatedAt,
);

drift.ServiceRequestsCompanion requestToCompanion(ServiceRequest e) =>
    drift.ServiceRequestsCompanion(
      id: Value(e.id),
      customerId: Value(e.customerId),
      serviceId: Value(e.serviceId),
      description: Value(e.description),
      address: Value(e.address),
      governorate: Value(e.governorate),
      phone: Value(e.phone),
      photoLocalPath: Value(e.photoLocalPath),
      preferredSlot: const Value.absent(),
      priority: Value(e.priority),
      status: Value(e.status),
      slaDueAt: Value(e.slaDueAt),
      estimateEgp: Value(e.estimateEgp),
      idempotencyKey: Value(e.idempotencyKey),
      version: Value(e.version),
      createdAt: Value(e.createdAt),
      updatedAt: Value(e.updatedAt),
    );

StatusEvent eventFromRow(drift.StatusHistoryData r) => StatusEvent(
  requestId: r.requestId,
  from: r.from,
  to: r.to,
  byUserId: r.byUserId,
  reason: r.reason,
  createdAt: r.createdAt,
);

JobNote noteFromRow(drift.JobNote r) => JobNote(
  requestId: r.requestId,
  authorId: r.authorId,
  kind: r.kind,
  body: r.body,
  createdAt: r.createdAt,
);

JobPhoto photoFromRow(drift.JobPhoto r) =>
    JobPhoto(requestId: r.requestId, kind: r.kind, localPath: r.localPath);

drift.ServicesCompanion serviceToCompanion(ServiceInfo s) =>
    drift.ServicesCompanion(
      id: Value(s.id),
      code: Value(s.code),
      nameAr: Value(s.nameAr),
      nameEn: Value(s.nameEn),
      defaultSlaHours: Value(s.defaultSlaHours),
    );

ServiceInfo serviceFromRow(drift.Service r) => ServiceInfo(
  id: r.id,
  code: r.code,
  nameAr: r.nameAr,
  nameEn: r.nameEn,
  defaultSlaHours: r.defaultSlaHours,
);

drift.PartsCompanion partToCompanion(PartInfo p) => drift.PartsCompanion(
  id: Value(p.id),
  sku: Value('SKU-${p.id}'),
  nameAr: Value(p.nameAr),
  nameEn: Value(p.nameEn),
  priceEgp: Value(p.priceEgp),
);

PartInfo partFromRow(drift.Part r) => PartInfo(
  id: r.id,
  nameAr: r.nameAr,
  nameEn: r.nameEn,
  priceEgp: r.priceEgp,
);

drift.JobPartUsageCompanion partUsageToCompanion(
  String requestId,
  PartUsage u,
) => drift.JobPartUsageCompanion(
  requestId: Value(requestId),
  partId: Value(u.partId),
  qty: Value(u.qty),
);

drift.RatingsCompanion ratingToCompanion(RatingInfo r) =>
    drift.RatingsCompanion(
      requestId: Value(r.requestId),
      stars: Value(r.stars),
      comment: Value(r.comment),
    );

RatingInfo ratingFromRow(drift.Rating r) =>
    RatingInfo(requestId: r.requestId, stars: r.stars, comment: r.comment);
