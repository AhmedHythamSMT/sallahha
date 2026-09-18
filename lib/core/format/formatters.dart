import 'package:intl/intl.dart';

/// Locale-aware money + dates. Phones stay Latin digits (see docs/ux).
String formatEgp(int amount, String locale) {
  final fmt = NumberFormat.currency(
    locale: locale == 'ar' ? 'ar_EG' : 'en_EG',
    symbol: locale == 'ar' ? 'ج.م' : 'EGP',
    decimalDigits: 0,
  );
  return fmt.format(amount);
}

String formatDateTime(DateTime dt, String locale) {
  final fmt = DateFormat.yMd(locale == 'ar' ? 'ar_EG' : 'en').add_Hm();
  return fmt.format(dt);
}
