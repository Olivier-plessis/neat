# NEAT — Wizard Steps Documentation

NEAT est un outil desktop Flutter (macOS/Windows/Linux) qui génère des projets Flutter avec une architecture Clean, des dépendances préconfigurées, et des pipelines CI/CD prêts à l'emploi.

Le wizard se déroule en **5 étapes séquentielles**. Chaque étape alimente un état Riverpod persistant (`keepAlive: true`) qui sera consolidé à l'étape Launch pour générer les fichiers.

---

## Étape 1 — Identity

> **Provider :** `IdentityNotifier` (`IdentityState`)  
> **Fichier :** `lib/features/generator/presentation/providers/identity_provider.dart`

### Ce que l'utilisateur configure

| Champ | Type | Défaut | Description |
|-------|------|--------|-------------|
| `name` | `String` | `''` | Nom du projet Flutter (ex : `my_app`) |
| `organization` | `String` | `com.example` | Bundle ID / package name (ex : `com.acme`) |
| `projectPath` | `String` | `''` | Répertoire de destination, sélectionné via `FilePicker` |
| `targetPlatforms` | `List<String>` | `['android', 'ios']` | Plateformes cibles parmi : android, ios, web, macos, windows, linux |
| `flutterVersion` | `String` | dernière stable | Version Flutter à utiliser, récupérée dynamiquement depuis `storage.googleapis.com` |

### Ce que NEAT génère (à l'étape Launch)

```
flutter create \
  --project-name <name> \
  --org <organization> \
  --platforms <platforms> \
  <projectPath>/<name>
```

### Détails techniques

- Les versions Flutter stables sont chargées depuis l'API Google Storage au démarrage (`FlutterSdkRepository`, Chopper).
- En cas d'échec réseau, un fallback statique de 4 versions est utilisé.
- `projectPath` est en lecture seule dans l'UI (setter via `FilePicker.getDirectoryPath()`).

---

## Étape 2 — Dependencies

> **Providers :** `SearchQueryNotifier`, `PackageForDetailNotifier`, `SelectedPackagesNotifier`  
> **Fichier :** `lib/features/dependencies/presentation/providers/dependencies_provider.dart`

### Ce que l'utilisateur configure

- Recherche en temps réel sur **pub.dev** (debounce 400 ms géré dans le provider, pas dans le widget)
- Ajout/suppression de packages dans une liste persistante
- Classification automatique `dependencies` vs `dev_dependencies` via une **whitelist** (build_runner, freezed, json_serializable, riverpod_generator…)
- Toggle manuel pour changer la classification d'un package ajouté

### Structure d'un package sélectionné (`PubPackage`)

```dart
PubPackage({
  required String name,
  required String version,
  required String description,
  int likes,         // depuis /api/packages/{name}/score
  int pubPoints,
  int popularity,    // 0–100
  bool isDev,        // true = dev_dependencies
})
```

### Ce que NEAT génère (à l'étape Launch)

Section `pubspec.yaml` :

```yaml
dependencies:
  flutter_sdk: flutter
  dio: ^5.x.x
  hooks_riverpod: ^2.x.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.x.x
  freezed: ^2.x.x
  json_serializable: ^6.x.x
```

### Détails techniques

- Chaque résultat de recherche déclenche 2 appels parallèles (`Future.wait`) : `GET /api/packages/{name}` + `GET /api/packages/{name}/score`
- Le debounce est implémenté dans `SearchQueryNotifier` via un `Timer` interne (pas de `useEffect`)
- Vider la barre de recherche reset aussi `packageForDetailProvider`

---

## Étape 3 — Architecture

> **Provider :** `ArchitectureNotifier` (`ArchitectureState`)  
> **Fichier :** `lib/features/architecture/presentation/providers/architecture_provider.dart`

### Ce que l'utilisateur configure

#### Pattern structurel

| Option | Description |
|--------|-------------|
| **Feature-First** *(recommandé)* | Code organisé par fonctionnalité métier. Chaque feature contient ses propres couches `data/`, `domain/`, `presentation/`. |
| **Layer-First** | Code organisé par couche technique globale (`data/`, `domain/`, `presentation/`), sous-dossiers par feature. |

#### Options Clean Architecture

| Toggle | Condition d'affichage | Effet |
|--------|-----------------------|-------|
| **Include Data Mappers** | Toujours | Ajoute un dossier `mappers/` dans `data/` pour les conversions Entity → Model |
| **Use @riverpod annotation syntax** | Si un package `*riverpod*` est sélectionné en étape 2 | Génère la nouvelle syntaxe `@riverpod class MyNotifier extends _$MyNotifier` |
| **Use Cubit instead of full BLoC** | Si `flutter_bloc` est sélectionné en étape 2 | Génère des `Cubit<State>` au lieu de `Bloc<Event, State>` |

#### Options testing

| Toggle | Effet |
|--------|-------|
| **Mirror Structure in /test** | Crée un dossier `test/` qui reflète exactement la structure `lib/` |

### Aperçu généré en temps réel (Feature-First, tous toggles actifs)

```
lib/
└── features/
    └── auth/
        ├── data/
        │   ├── datasources/
        │   ├── entities/
        │   ├── mappers/
        │   └── repositories/
        ├── domain/
        │   ├── models/
        │   ├── repositories/
        │   └── usecases/
        └── presentation/
            ├── providers/      ← si Riverpod sélectionné
            ├── bloc/           ← si flutter_bloc sélectionné
            └── screens/

test/
└── features/
    └── auth/
        ├── data/
        ├── domain/
        └── presentation/
```

---

## Étape 4 — CI/CD

> **Provider :** `CicdNotifier` (`CicdState`)  
> **Fichier :** `lib/features/cicd/presentation/providers/cicd_provider.dart`

### Ce que l'utilisateur configure

Les outils sont **multi-sélectionnables et indépendants**. NEAT génère un fichier de configuration par outil activé.

#### CI Runners

| Outil | Fichier généré | Badge |
|-------|---------------|-------|
| **GitHub Actions** | `.github/workflows/flutter.yml` | CI |
| **GitLab CI** | `.gitlab-ci.yml` | CI |
| **Codemagic** | `codemagic.yaml` | CI/CD |

#### CD & Delivery

| Outil | Fichier généré | Badge |
|-------|---------------|-------|
| **Fastlane** | `fastlane/Fastfile` | CD |
| **Shorebird** | `shorebird.yaml` | OTA |

#### Pipeline Stages *(visibles uniquement si un CI runner est sélectionné)*

| Stage | Commande générée |
|-------|-----------------|
| **Static Analysis & Linting** | `flutter analyze` + `dart format --set-exit-if-changed .` |
| **Unit & Widget Testing** | `flutter test --coverage` |
| **Auto-deploy to stores** | Déclenché sur les tags `v*.*.*` — injecte Fastlane ou Shorebird si sélectionné |

### Combinaisons possibles

- GitHub Actions + Shorebird → pipeline CI + patch OTA sur tags
- GitHub Actions + Fastlane → pipeline CI + release App Store / Play Store
- Codemagic seul → CI/CD tout-en-un mobile-first
- GitLab CI + Fastlane → pipeline GitLab + déploiement store

### Prévisualisation en temps réel

Un onglet par fichier généré. Le contenu YAML se met à jour instantanément à chaque toggle.

---

## Étape 5 — Launch *(à implémenter)*

> Consolidation de tous les états et exécution de la génération.

### Ce que NEAT va exécuter

1. **`flutter create`** avec les paramètres de l'étape Identity
2. **Écriture de `pubspec.yaml`** avec les dépendances de l'étape Dependencies (séparées `dependencies` / `dev_dependencies`)
3. **Création de l'arborescence** selon le pattern Architecture choisi (étape 3)
4. **Écriture des fichiers CI/CD** (`.github/workflows/`, `codemagic.yaml`, `fastlane/Fastfile`…)
5. **`flutter pub get`** dans le projet généré

### État consolidé au moment du lancement

```dart
// Tous les providers sont keepAlive: true
final identity   = ref.read(identityProvider);          // IdentityState
final packages   = ref.read(selectedPackagesProvider);  // List<PubPackage>
final arch       = ref.read(architectureProvider);      // ArchitectureState
final cicd       = ref.read(cicdProvider);              // CicdState
```

---

## Feature Gen *(outil séparé, pas dans le wizard)*

> Génération de features Clean Architecture sur un **projet existant**.

Contrairement aux 5 étapes du wizard (qui créent un projet from scratch), Feature Gen agit sur un projet Flutter déjà existant. L'utilisateur entre le nom d'une feature (ex : `cart`) et NEAT génère l'arborescence complète (`data/`, `domain/`, `presentation/`) avec les fichiers boilerplate selon les préférences d'architecture configurées.

---

## Architecture technique de NEAT

```
lib/
├── core/
│   ├── error/          # Failure, Result<T>
│   ├── network/        # Chopper interceptors, Riverpod observer
│   ├── theme/          # AppTheme (dark, cyan #00F5FF)
│   └── usecase/        # UseCase<Params, T>, NoParamsUseCase<T>
└── features/
    ├── generator/      # Identity + Stepper + Flutter SDK versions
    ├── dependencies/   # Recherche pub.dev + sélection packages
    ├── architecture/   # Choix pattern + options Clean Arch
    ├── cicd/           # Sélection outils + génération YAML
    └── (launch)        # À implémenter
```

### Stack

| Couche | Technologie |
|--------|-------------|
| UI | Flutter Desktop (macOS/Windows/Linux) |
| State | Riverpod 3.x (`riverpod_annotation`, `riverpod_generator`) |
| HTTP | Chopper 8.x |
| Sérialisation | `json_serializable` + `freezed` |
| Code gen | `build_runner` |
| Window | `window_manager` (1200×800, min 1000×700) |
