# ERD (MVP, SQLite-first; Supabase mirrors this in Postgres)

```
User( id PK, name, phone UNIQUE, email UNIQUE, role[customer|technician|supervisor|admin], active, createdAt )
CustomerProfile( userId PK/FK, defaultAddress, governorate, notes )
TechnicianProfile( userId PK/FK, skills TEXT[], active, hireDate )
Service( id PK, vertical='ac', code, nameAr, nameEn, defaultSlaHours, active )
ServiceRequest( id PK, customerId FK, serviceId FK, description, photoLocalPath?, address, governorate, lat?, lng?, phone, preferredSlot, priority[normal|high|urgent], status, slaDueAt, estimateEgp?, idempotencyKey UNIQUE, version, createdAt, updatedAt )
JobAssignment( id PK, requestId FK, technicianId FK, assignedBy FK, active BOOL, createdAt )  -- one active per request
StatusHistory( id PK, requestId FK, from, to, byUserId FK, reason?, createdAt )
JobNote( id PK, requestId FK, authorId FK, kind[diagnosis|labor], body, createdAt )
JobPhoto( id PK, requestId FK, kind[before|after|other|signature], localPath, remoteUrl?, createdAt )
Part( id PK, sku UNIQUE, nameAr, nameEn, priceEgp, active )
JobPartUsage( id PK, requestId FK, partId FK, qty, createdAt )
Rating( id PK, requestId FK UNIQUE, stars 1..5, comment?, createdAt )
Payment( id PK, requestId FK, amountEgp, state[pending|succeeded|failed|cancelled|timed_out], gatewayRef?, createdAt ) -- mock only in MVP
Notification( id PK, userId FK, kind, title, body, readAt?, createdAt )
AuditEvent( id PK, actorId FK, action, entityType, entityId, meta JSON, createdAt )
SyncOperation( opId PK, entityType, entityId, opType, payload JSON, status, retryCount, lastAttemptAt?, lastError?, createdAt )
```

Rules: statuses = new,assigned,accepted,on_the_way,arrived,in_progress,waiting_for_parts,completed,cancelled. `slaDueAt = createdAt + service.defaultSlaHours` unless overridden. Seed: 4 services, 6 parts, 5 demo users, 8 requests across statuses.
