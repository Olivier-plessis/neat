import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/hub/domain/models/recent_project.dart';

void main() {
  test('RecentProject survives a JSON round-trip', () {
    final original = RecentProject(
      path: '/Users/x/Flutter/nexus',
      name: 'nexus',
      lastOpened: DateTime.parse('2026-06-19T10:30:00.000'),
    );

    final restored = RecentProject.fromJson(original.toJson());

    expect(restored.path, original.path);
    expect(restored.name, original.name);
    expect(restored.lastOpened, original.lastOpened);
  });
}
