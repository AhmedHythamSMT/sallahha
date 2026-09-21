import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// Schema v1 mirrors docs/backend/erd.md. All writes carry idempotency keys;
// offline mutations queue in SyncOperations (Phase 4 engine consumes).

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().unique()();
  TextColumn get email => text().nullable().unique()();
  // customer | technician | supervisor | admin
  TextColumn get role => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CustomerProfiles extends Table {
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get defaultAddress => text().nullable()();
  TextColumn get governorate => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}

class TechnicianProfiles extends Table {
  TextColumn get userId => text().references(Users, #id)();
  // comma-separated service codes, e.g. "ac-repair,ac-install"
  TextColumn get skillsCsv => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {userId};
}

class Services extends Table {
  TextColumn get id => text()();
  TextColumn get vertical => text().withDefault(const Constant('ac'))();
  TextColumn get code => text().unique()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  IntColumn get defaultSlaHours => integer().withDefault(const Constant(24))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class ServiceRequests extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Users, #id)();
  TextColumn get serviceId => text().references(Services, #id)();
  TextColumn get description => text()();
  TextColumn get address => text()();
  TextColumn get governorate => text()();
  TextColumn get phone => text()();
  TextColumn get photoLocalPath => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get preferredSlot => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get status => text().withDefault(const Constant('new'))();
  DateTimeColumn get slaDueAt => dateTime()();
  IntColumn get estimateEgp => integer().nullable()();
  TextColumn get idempotencyKey => text().unique()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class JobAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  TextColumn get technicianId => text().references(Users, #id)();
  TextColumn get assignedBy => text().references(Users, #id)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class StatusHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  TextColumn get from => text()();
  TextColumn get to => text()();
  TextColumn get byUserId => text().references(Users, #id)();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class JobNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  TextColumn get authorId => text().references(Users, #id)();
  // diagnosis | labor
  TextColumn get kind => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class JobPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  // before | after | other | signature
  TextColumn get kind => text()();
  TextColumn get localPath => text()();
  TextColumn get remoteUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Parts extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text().unique()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  IntColumn get priceEgp => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class JobPartUsage extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  TextColumn get partId => text().references(Parts, #id)();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Ratings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId =>
      text().unique().references(ServiceRequests, #id)();
  IntColumn get stars => integer()();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  IntColumn get amountEgp => integer()();
  // pending | succeeded | failed | cancelled | timed_out (mock only in MVP)
  TextColumn get state => text().withDefault(const Constant('pending'))();
  TextColumn get gatewayRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AuditEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actorId => text().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get metaJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SyncOperations extends Table {
  // Client UUID = idempotency key. Retries reuse it; server dedupes.
  TextColumn get opId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get opType => text()();
  TextColumn get payloadJson => text()();
  // pending | sending | backing_off | acked | failed
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {opId};
}

String? _databasePath;

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sallahha.db'));
    _databasePath = file.path;
    return NativeDatabase.createInBackground(file);
  });
}

String? get databasePath => _databasePath;

@DriftDatabase(
  tables: [
    Users,
    CustomerProfiles,
    TechnicianProfiles,
    Services,
    ServiceRequests,
    JobAssignments,
    StatusHistory,
    JobNotes,
    JobPhotos,
    Parts,
    JobPartUsage,
    Ratings,
    Payments,
    Notifications,
    AuditEvents,
    SyncOperations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory instance for tests / CI Linux (needs sqlite native lib).
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  /// Table inventory check that needs no I/O (runs on any host).
  List<String> get tableInventory =>
      allTables.map((t) => t.actualTableName).toList()..sort();

  /// Returns the file path of the SQLite database (null for in-memory).
  static String? get databasePath => _databasePath;
}
