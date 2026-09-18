# Localization & Arabic-first UX (default: ar)

## Strategy
- All strings in ARB (`lib/core/localization/intl_ar.arb`, `intl_en.arb`); zero hardcoded Arabic/English in widgets (lint + review). `AppLocalizations` via `flutter_localizations`; `locale` state in Riverpod; persist choice; fallback ar.
- Numbers: Arabic-Indic digits optional toggle for customer-facing surfaces; phone numbers always Latin digits. Currency: `EGP 450` / `٤٥٠ ج.م` formatter with locale-aware decimals (no decimals for EGP cash). Dates: `ar_EG` (with Arabic month names) via `intl`.
- Governorates: seeded list (Cairo, Giza, Alexandria, …) bilingual; address fields: street/landmark/district/governorate + optional pin — Egyptian address reality (landmarks > postal codes).

## Arabic UX guidelines
- Short verb-first buttons ("إنشاء طلب"، "تأكيد الوصول"); avoid formal MSA heaviness; Egyptian-dialect hints in placeholders where safe.
- Long-text resilience: buttons wrap/maxLines, cards expand, no fixed-height text boxes; test with 2× length strings.
- Mixed input: Bidi-safe (directionality per field); phone LTR-isolated.
- A11y: semantic labels AR/EN, 44dp targets, contrast ≥4.5:1, 200% text-scale smoke test.

## RTL checklist (widget-test + manual)
- [ ] Default ar → RTL shell, drawer/timeline mirrored; toggle en → LTR without restart.
- [ ] Icons with direction (back/progress) flip; non-directional (camera) don't.
- [ ] Timeline, stepper, badges aligned correctly both directions.
- [ ] Long Arabic error/empty states don't clip at 200% scale.
- [ ] EGP/date formats verified in both locales; phone LTR in RTL layout.
