import 'package:neat/features/dependencies/domain/models/pub_package.dart';

abstract interface class PubDevRepository {
  /// Recherche des packages sur pub.dev.
  /// Chaque résultat inclut détails + scores (2 appels parallèles par package).
  Future<List<PubPackage>> searchPackages(String query);
}
