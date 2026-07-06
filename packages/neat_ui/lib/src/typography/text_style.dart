part of 'typography.dart';

class StyleTheme {
  StyleTheme._();

  static final TextStyle _baseMainTextStyle = TextStyle(
    fontFamily: FontFamilyTheme.mainFont,
    color: Palette.mainFont,
    fontWeight: FontWeightTheme.regular,
  );

  static TextStyle get displayLarge => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.displayLarge,
    fontWeight: FontWeightTheme.extraBold,
  );

  static TextStyle get displayMedium => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.displayMedium,
    fontWeight: FontWeightTheme.bold,
  );

  static TextStyle get displaySmall => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.displaySmall,
    fontWeight: FontWeightTheme.semiBold,
  );

  static TextStyle get headlineLarge => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.headlineLarge,
    fontWeight: FontWeightTheme.bold,
  );

  static TextStyle get headlineMedium => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.headlineMedium,
    fontWeight: FontWeightTheme.bold,
  );

  static TextStyle get headlineSmall => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.headlineSmall,
    fontWeight: FontWeightTheme.regular,
  );

  static TextStyle get titleLarge => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.titleLarge,
    fontWeight: FontWeightTheme.medium,
  );

  static TextStyle get titleMedium => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.titleMedium,
    fontWeight: FontWeightTheme.regular,
  );

  static TextStyle get titleSmall => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.titleSmall,
    fontWeight: FontWeightTheme.light,
  );

  static TextStyle get bodyLarge => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.bodyLarge,
    fontWeight: FontWeightTheme.regular,
  );

  static TextStyle get bodyMedium => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.bodyMedium,
    fontWeight: FontWeightTheme.medium,
  );

  static TextStyle get bodySmall => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.bodySmall,
    fontWeight: FontWeightTheme.regular,
  );

  static TextStyle get labelMedium => _baseMainTextStyle.copyWith(
    fontSize: FontSizeTheme.labelMedium,
    fontWeight: FontWeightTheme.thin,
  );
}
