import 'package:flutter/material.dart';

/// Color tokens for Gas Finder. Used by both end-user and retailer apps.
///
/// Status colors are always paired with an icon in the UI — never rely on
/// color alone to convey meaning (color-blind users, cultural variance).
abstract final class GasColors {
  static const primary = Color(0xFF1E4DA1);
  static const primaryDark = Color(0xFF143672);
  static const accent = Color(0xFFF9A825);

  static const available = Color(0xFF2E7D32);
  static const low = Color(0xFFF9A825);
  static const out = Color(0xFFC62828);

  static const surface = Color(0xFFFAFAFA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF616161);
  static const divider = Color(0xFFE0E0E0);
}
