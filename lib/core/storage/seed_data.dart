import 'package:drift/drift.dart';
import 'package:sallahha/core/storage/app_database.dart';

// Synthetic demo data (Cairo names, 0100-000-xxxx phones — never real).
// Pure builders are unit-testable without opening SQLite; seedDemoData
// batch-inserts them on device / CI Linux.

const demoPasswordNote = 'demo1234 (mock auth only)';

List<UsersCompanion> demoUsers() => const [
  UsersCompanion(
    id: Value('u-customer-1'),
    name: Value('Salma Ahmed'),
    phone: Value('01000000001'),
    email: Value('customer@demo.test'),
    role: Value('customer'),
  ),
  UsersCompanion(
    id: Value('u-tech-1'),
    name: Value('Hassan Ali'),
    phone: Value('01000000002'),
    email: Value('tech@demo.test'),
    role: Value('technician'),
  ),
  UsersCompanion(
    id: Value('u-tech-2'),
    name: Value('Omar Khaled'),
    phone: Value('01000000003'),
    email: Value('tech2@demo.test'),
    role: Value('technician'),
  ),
  UsersCompanion(
    id: Value('u-supervisor-1'),
    name: Value('Mona Adel'),
    phone: Value('01000000004'),
    email: Value('supervisor@demo.test'),
    role: Value('supervisor'),
  ),
  UsersCompanion(
    id: Value('u-admin-1'),
    name: Value('Karim Samy'),
    phone: Value('01000000005'),
    email: Value('admin@demo.test'),
    role: Value('admin'),
  ),
];

List<ServicesCompanion> demoServices() => const [
  ServicesCompanion(
    id: Value('svc-ac-repair'),
    code: Value('ac-repair'),
    nameAr: Value('إصلاح تكييف'),
    nameEn: Value('AC repair'),
    defaultSlaHours: Value(24),
  ),
  ServicesCompanion(
    id: Value('svc-ac-install'),
    code: Value('ac-install'),
    nameAr: Value('تركيب تكييف'),
    nameEn: Value('AC install'),
    defaultSlaHours: Value(48),
  ),
  ServicesCompanion(
    id: Value('svc-ac-cleaning'),
    code: Value('ac-cleaning'),
    nameAr: Value('تنظيف وصيانة دورية'),
    nameEn: Value('AC cleaning'),
    defaultSlaHours: Value(72),
  ),
  ServicesCompanion(
    id: Value('svc-ac-gas'),
    code: Value('ac-gas'),
    nameAr: Value('شحن فريون'),
    nameEn: Value('Gas refill'),
    defaultSlaHours: Value(24),
  ),
];

List<PartsCompanion> demoParts() => const [
  PartsCompanion(
    id: Value('part-capacitor'),
    sku: Value('CAP-35UF'),
    nameAr: Value('مكثف 35 ميكروفاراد'),
    nameEn: Value('Capacitor 35uF'),
    priceEgp: Value(180),
  ),
  PartsCompanion(
    id: Value('part-filter'),
    sku: Value('FLT-SPLIT'),
    nameAr: Value('فلتر سبليت'),
    nameEn: Value('Split filter'),
    priceEgp: Value(90),
  ),
  PartsCompanion(
    id: Value('part-freon'),
    sku: Value('FRN-R410A'),
    nameAr: Value('فريون R410A (كجم)'),
    nameEn: Value('Freon R410A (kg)'),
    priceEgp: Value(450),
  ),
  PartsCompanion(
    id: Value('part-thermostat'),
    sku: Value('THM-DGT'),
    nameAr: Value('ثرموستات ديجيتال'),
    nameEn: Value('Digital thermostat'),
    priceEgp: Value(320),
  ),
  PartsCompanion(
    id: Value('part-fan-motor'),
    sku: Value('FAN-MTR'),
    nameAr: Value('موتور مروحة'),
    nameEn: Value('Fan motor'),
    priceEgp: Value(750),
  ),
  PartsCompanion(
    id: Value('part-remote'),
    sku: Value('RMT-UNI'),
    nameAr: Value('ريموت يونيفرسال'),
    nameEn: Value('Universal remote'),
    priceEgp: Value(120),
  ),
];

/// 8 requests across the status machine for the demo script.
List<ServiceRequestsCompanion> demoRequests(DateTime now) {
  ServiceRequestsCompanion req(
    String id,
    String status,
    String priority,
    int slaInHours,
  ) => ServiceRequestsCompanion(
    id: Value(id),
    customerId: const Value('u-customer-1'),
    serviceId: const Value('svc-ac-repair'),
    description: const Value('التكييف ما بيبردش — هواء دافئ'),
    address: const Value('12 شارع مصدق، الدقي'),
    governorate: const Value('الجيزة'),
    phone: const Value('01000000001'),
    priority: Value(priority),
    status: Value(status),
    slaDueAt: Value(now.add(Duration(hours: slaInHours))),
    idempotencyKey: Value('seed-$id'),
  );
  return [
    req('req-new-1', 'new', 'normal', 20),
    req('req-new-2', 'new', 'high', 6),
    req('req-assigned-1', 'assigned', 'normal', 18),
    req('req-progress-1', 'in_progress', 'high', 4),
    req('req-waiting-1', 'waiting_for_parts', 'normal', 30),
    req('req-done-1', 'completed', 'normal', -26),
    req('req-done-2', 'completed', 'high', -30),
    req('req-cancelled-1', 'cancelled', 'normal', -10),
  ];
}

Future<void> seedDemoData(AppDatabase db) async {
  final now = DateTime.now();
  await db.batch((b) {
    b.insertAll(db.users, demoUsers());
    b.insertAll(db.services, demoServices());
    b.insertAll(db.parts, demoParts());
    b.insertAll(db.serviceRequests, demoRequests(now));
    b.insert(
      db.technicianProfiles,
      const TechnicianProfilesCompanion(
        userId: Value('u-tech-1'),
        skillsCsv: Value('ac-repair,ac-cleaning,ac-gas'),
      ),
    );
    b.insert(
      db.technicianProfiles,
      const TechnicianProfilesCompanion(
        userId: Value('u-tech-2'),
        skillsCsv: Value('ac-install,ac-repair'),
      ),
    );
    b.insert(
      db.customerProfiles,
      const CustomerProfilesCompanion(
        userId: Value('u-customer-1'),
        defaultAddress: Value('12 شارع مصدق، الدقي'),
        governorate: Value('الجيزة'),
      ),
    );
  });
}
