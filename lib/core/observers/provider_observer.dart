import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:neat/core/utils/app_logger.dart';

final class RiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    AppLogger.d('''
{
  "event": "didAddProvider",
  "provider": "${context.provider.name ?? context.provider.runtimeType}",
  "value": "$value"
}''');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    AppLogger.d('''
{
  "event": "didUpdateProvider",
  "provider": "${context.provider.name ?? context.provider.runtimeType}",
  "previousValue": "$previousValue",
  "newValue": "$newValue",
  "mutation": "${context.mutation}"
}''');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    AppLogger.d('''
{
  "event": "didDisposeProvider",
  "provider": "${context.provider.name ?? context.provider.runtimeType}"
}''');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.e(
      '{ "event": "providerDidFail", "provider": "${context.provider.name ?? context.provider.runtimeType}" }',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
