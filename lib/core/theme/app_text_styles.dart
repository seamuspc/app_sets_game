import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text styles built on GoogleFonts so you get a real typeface out of the
/// box without manually bundling font files. Swap `poppins` for any font
/// at fonts.google.com and every screen updates.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headline => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get title => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.grey,
      );
}
