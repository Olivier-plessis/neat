import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:neat/core/error/failure.dart';
import 'package:neat/core/usecase/use_case.dart';

class _Run extends UseCase<int, int> {
  const _Run(this.run);

  final int Function(int) run;

  @override
  Future<int> execute(int params) async => run(params);
}

/// Runs [body] and gives back what was printed meanwhile (the logger prints).
Future<List<String>> _printed(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  test('a use case that works gives its value, and says nothing', () async {
    late final int? value;
    final printed = await _printed(() async {
      value = (await _Run((n) => n * 2)(21)).getOrNull();
    });

    expect(value, 42);
    expect(printed, isEmpty);
  });

  test('one that throws gives a failure that keeps the cause', () async {
    final error = StateError('no such column: payment_method');
    late final Object failure;
    await _printed(() async {
      final result = await _Run((_) => throw error)(1);
      failure = result.fold((_) => 'success', (f) => f);
    });

    expect(failure, isA<Failure>());
    expect((failure as Failure).originalError, error);
  });

  test('and writes the cause to the log, which the failure alone would '
      'hide from a screen', () async {
    final printed = await _printed(() async {
      await _Run((_) => throw StateError('no such column: payment_method'))(1);
    });

    final log = printed.join('\n');
    expect(log, contains('_Run failed'));
    expect(log, contains('no such column: payment_method'));
  });

  test('a failure thrown on purpose is not an unexpected error: not logged, '
      'and kept as the cause', () async {
    final refusal = Failure(message: 'Locked', code: 'locked');
    late final Object failure;
    final printed = await _printed(() async {
      final result = await _Run((_) => throw refusal)(1);
      failure = result.fold((_) => 'success', (f) => f);
    });

    expect((failure as Failure).originalError, same(refusal));
    // NEAT's NetworkErrorHandler prints one line of its own in debug mode, so
    // "not logged" means: no `<UseCase> failed` entry from the logger.
    expect(printed.join('\n'), isNot(contains('_Run failed')));
  });
}
