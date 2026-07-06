part of 'constant.dart';

/// Constant sizes to be used in the app (paddings, gaps, etc.)
class Sizes {
  static const double p4 = 4;
  static const double p6 = 6;
  static const double p8 = 8;
  static const double p10 = 10;
  static const double p12 = 12;
  static const double p14 = 14;
  static const double p16 = 16;
  static const double p18 = 18;
  static const double p20 = 20;
  static const double p24 = 24;
  static const double p32 = 32;
  static const double p48 = 48;
  static const double p64 = 64;
}

extension GapPaddingX on num {
  // Gaps
  SizedBox get gapW => SizedBox(width: toDouble());

  SizedBox get gapH => SizedBox(height: toDouble());

  // Paddings (règle de calcul simplifiée)
  EdgeInsets get pAll => EdgeInsets.all(toDouble());

  EdgeInsets get pH => EdgeInsets.symmetric(horizontal: toDouble());

  EdgeInsets get pV => EdgeInsets.symmetric(vertical: toDouble());

  double get p => toDouble();
}
