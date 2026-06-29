import 'package:flutter_test/flutter_test.dart';
import 'package:neat/features/cicd/domain/models/cicd_state.dart';
import 'package:neat/features/cicd/domain/usecases/generate_yaml_usecase.dart';

void main() {
  const usecase = GenerateYamlUsecase();
  const fastlaneState = CicdState(selectedTools: {CiTool.fastlane});

  Map<String, String> filesFor(CicdState state, {bool hasFlavors = false}) => {
        for (final f in usecase.execute(state, hasFlavors: hasFlavors)) f.filename: f.content,
      };

  group('fastlane lives under android/ and ios/ (not the project root)', () {
    test('writes the platform-scoped fastlane layout', () {
      final files = filesFor(fastlaneState);
      // Correct locations.
      expect(files.keys, contains('android/fastlane/Fastfile'));
      expect(files.keys, contains('android/fastlane/Appfile'));
      expect(files.keys, contains('android/Gemfile'));
      expect(files.keys, contains('android/key.properties.example'));
      expect(files.keys, contains('ios/fastlane/Fastfile'));
      expect(files.keys, contains('ios/fastlane/Appfile'));
      expect(files.keys, contains('ios/fastlane/Matchfile'));
      // The old wrong location is gone.
      expect(files.keys, isNot(contains('fastlane/Fastfile')));
    });

    test('secrets are read from the environment, none hard-coded', () {
      final files = filesFor(fastlaneState);
      expect(files['android/fastlane/Appfile'], contains('ENV["PLAY_STORE_JSON_KEY_PATH"]'));
      expect(files['ios/fastlane/Appfile'], contains('ENV["IOS_BUNDLE_ID"]'));
      expect(files['ios/fastlane/Matchfile'], contains('ENV["MATCH_GIT_URL"]'));
    });
  });

  group('flavor-aware lanes', () {
    test('without flavors: a plain release build', () {
      final files = filesFor(fastlaneState);
      expect(files['android/fastlane/Fastfile'], contains('build", "appbundle", "--release"'));
      expect(files['android/fastlane/Fastfile'], isNot(contains('--flavor')));
    });

    test('with flavors: the lane takes a flavor + the matching entry point', () {
      final files = filesFor(fastlaneState, hasFlavors: true);
      expect(files['android/fastlane/Fastfile'], contains('"--flavor", flavor'));
      expect(files['android/fastlane/Fastfile'], contains('lib/main_#{flavor}.dart'));
      expect(files['ios/fastlane/Fastfile'], contains('"--flavor", flavor'));
    });
  });

  test('non-fastlane states do not emit fastlane files', () {
    final files = filesFor(const CicdState(selectedTools: {CiTool.githubActions}));
    expect(files.keys.any((k) => k.contains('fastlane')), isFalse);
  });
}
