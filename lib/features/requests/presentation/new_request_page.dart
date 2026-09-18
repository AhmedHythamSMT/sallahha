import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sallahha/core/config/governorates.dart';
import 'package:sallahha/core/di/providers.dart';
import 'package:sallahha/core/errors/error_messages.dart';
import 'package:sallahha/core/localization/l10n/sallahha_localizations.dart';
import 'package:sallahha/core/result/result.dart';
import 'package:sallahha/features/requests/domain/entities.dart';
import 'package:sallahha/features/requests/domain/rules.dart';
import 'package:sallahha/shared/widgets/connectivity_widgets.dart';

/// Customer request form. Domain validates; triage hint shown read-only
/// (Phase 5 surfaces supervisor-side suggestion card).
class NewRequestPage extends ConsumerStatefulWidget {
  const NewRequestPage({super.key});

  @override
  ConsumerState<NewRequestPage> createState() => _NewRequestPageState();
}

class _NewRequestPageState extends ConsumerState<NewRequestPage> {
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _slot = TextEditingController();
  String? _serviceId;
  String? _governorate;
  String? _fieldError;
  bool _busy = false;

  @override
  void dispose() {
    _desc.dispose();
    _address.dispose();
    _phone.dispose();
    _slot.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(sessionUserProvider);
    if (user == null) {
      context.go('/login');
      return;
    }
    final field = validateDraft(
      description: _desc.text,
      address: _address.text,
      governorate: _governorate ?? '',
      phone: _phone.text,
    );
    if (field != null || _serviceId == null) {
      setState(() => _fieldError = field ?? 'serviceId');
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
    });
    final res = await ref
        .read(requestRepositoryProvider)
        .create(
          user,
          RequestDraft(
            serviceId: _serviceId!,
            description: _desc.text.trim(),
            address: _address.text.trim(),
            governorate: _governorate!,
            phone: _phone.text.trim(),
            preferredSlot: _slot.text.trim().isEmpty ? null : _slot.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (res) {
      case Ok(value: final req):
        ref.invalidate(myRequestsProvider);
        // Replace the form with details: back returns to the section,
        // not to a stale filled form.
        context.pushReplacement('/requests/${req.id}');
      case Err(error: final e):
        setState(() => _fieldError = errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = SallahhaLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final services = ref.watch(servicesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.newRequestTitle),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/requests');
            }
          },
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.formServiceType,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                switch (services) {
                  AsyncData(value: final list) =>
                    DropdownButtonFormField<String>(
                      initialValue: _serviceId,
                      decoration: const InputDecoration(),
                      items: [
                        for (final s in list)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(locale == 'ar' ? s.nameAr : s.nameEn),
                          ),
                      ],
                      onChanged: (v) => setState(() => _serviceId = v),
                    ),
                  AsyncError() => Text(l.stateError),
                  _ => const LinearProgressIndicator(),
                },
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l.formDescription,
                    hintText: l.formDescriptionHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  decoration: InputDecoration(labelText: l.formAddress),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _governorate,
                  decoration: InputDecoration(labelText: l.formGovernorate),
                  items: [
                    for (final g in governorates)
                      DropdownMenuItem(
                        value: locale == 'ar' ? g.$1 : g.$2,
                        child: Text(locale == 'ar' ? g.$1 : g.$2),
                      ),
                  ],
                  onChanged: (v) => setState(() => _governorate = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l.formPhone),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _slot,
                  decoration: InputDecoration(
                    labelText: l.formSlot,
                    hintText: l.formSlotHint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.validationHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_fieldError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _fieldError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(l.formSubmit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
