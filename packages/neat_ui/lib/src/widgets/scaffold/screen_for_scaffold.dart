part of '../widgets.dart';

class ScreenForScaffold extends StatelessWidget {
  const ScreenForScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(title, style: context.textTheme.headlineLarge),
        8.gapH,
        Text(subtitle, style: context.textTheme.bodyLarge),
        24.gapH,

        Expanded(child: child),
      ],
    );
  }
}
