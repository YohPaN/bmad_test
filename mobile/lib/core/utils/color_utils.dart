import 'package:flutter/material.dart';

/// Parses a 6-digit hex color string (with or without leading `#`) into a
/// [Color] with full opacity.
///
/// Examples: `'#4FC3F7'` → `Color(0xFF4FC3F7)`, `'4FC3F7'` → same.
Color colorFromHex(String hex) {
  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  final buffer = StringBuffer();
  if (normalized.length == 6) buffer.write('ff');
  buffer.write(normalized);
  return Color(int.parse(buffer.toString(), radix: 16));
}
