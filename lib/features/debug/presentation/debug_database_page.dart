import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/storage/app_database.dart' as drift;
import 'package:sallahha/shared/animations/app_animations.dart';
import 'package:sallahha/shared/widgets/app_states.dart';

/// Debug database viewer (only available when kEnableDebugDbViewer = true).
/// Shows table contents, allows export to file, and raw SQL queries.
class DebugDatabasePage extends ConsumerStatefulWidget {
  const DebugDatabasePage({super.key});

  @override
  ConsumerState<DebugDatabasePage> createState() => _DebugDatabasePageState();
}

class _DebugDatabasePageState extends ConsumerState<DebugDatabasePage> {
  String _selectedTable = 'service_requests';
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  static const _tables = [
    'users',
    'customer_profiles',
    'technician_profiles',
    'services',
    'service_requests',
    'job_assignments',
    'status_history',
    'job_notes',
    'job_photos',
    'parts',
    'job_part_usage',
    'ratings',
    'payments',
    'notifications',
    'audit_events',
    'sync_operations',
  ];

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Debug: Database Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportDatabase,
            tooltip: 'Export DB file',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTable,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Table selector
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedTable,
              decoration: const InputDecoration(labelText: 'Table'),
              items: _tables
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedTable = v!;
                  _query = '';
                  _results = [];
                });
                _loadTable();
              },
            ),
          ),
          // Query input
          if (_query.isNotEmpty || _selectedTable == 'custom')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Raw SQL (optional)',
                  hintText:
                      'SELECT * FROM service_requests WHERE status = "new"',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: _runQuery,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
                maxLines: 3,
              ),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.table_view),
                    label: const Text('Load Table'),
                    onPressed: _loadTable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Query'),
                    onPressed: _runQuery,
                  ),
                ),
              ],
            ),
          ),
          // Results
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading)
            const Expanded(child: AppLoading())
          else if (_results.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: _results.first.keys
                      .map((k) => DataColumn(label: Text(k)))
                      .toList(),
                  rows: _results.map((row) {
                    return DataRow(
                      cells: row.values
                          .map((v) => DataCell(Text(v?.toString() ?? 'NULL')))
                          .toList(),
                    );
                  }).toList(),
                ),
              ),
            )
          else if (!_loading && _error == null && _query.isNotEmpty)
            const Center(child: Text('No results')),
        ],
      ),
    );
  }

  Future<void> _loadTable() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final results = await db.customSelect(
        'SELECT * FROM $_selectedTable ORDER BY rowid DESC LIMIT 100',
      ).get();
      setState(() {
        _results = results.map((row) => row.data).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _runQuery() async {
    if (_query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final results = await db.customSelect(_query).get();
      setState(() {
        _results = results.map((row) => row.data).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = drift.AppDatabase.databasePath;
    if (dbPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database path not available')),
        );
      }
      return;
    }
    final srcFile = File(dbPath);
    final destFile = File(
      '${dir.path}/sallahha_export_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    await srcFile.copy(destFile.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${destFile.path}')),
      );
    }
  }
}

/// Route registration (only when kEnableDebugDbViewer = true)
List<RouteBase> debugRoutes() => [
  GoRoute(
    path: '/debug/db',
    builder: (context, state) => const DebugDatabasePage(),
  ),
];