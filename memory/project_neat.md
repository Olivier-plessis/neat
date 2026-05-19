---
name: project-neat
description: App Flutter desktop NEAT — générateur de projets Flutter avec Clean Architecture, recherche pub.dev, CI/CD et déploiement
metadata:
  type: project
---

NEAT est une application Flutter Desktop (macOS/Windows/Linux) qui génère des projets Flutter avec Clean Architecture, packages, CI/CD et déploiement préconfigurés.

**Why:** Automatiser la création de projets Flutter avec une base solide dès le départ.

**Stack:**
- Flutter Desktop, hooks_riverpod, flutter_hooks, window_manager, file_picker, http
- Clean Architecture dans lib/ : core/ + features/
- Thème dark mode : fond #0E0E0E, accent cyan #00F5FF

**Architecture lib/:**
- `core/theme/app_theme.dart` — thème global
- `features/generator/presentation/screens/main_layout.dart` — layout sidebar + contenu
- `features/generator/presentation/screens/identity_screen.dart` — Step 1 (100% fait)
- `features/generator/presentation/providers/stepper_provider.dart` — enum NeatStep + currentStepProvider
- `features/generator/presentation/providers/identity_provider.dart` — IdentityState + IdentityNotifier

**5 étapes (NeatStep enum):**
1. `identity` — ✅ Fait : nom, org, path, plateformes, version Flutter
2. `dependencies` — ❌ À faire : recherche pub.dev + card détails (split-screen)
3. `cicd` — ❌ À faire : toggles GitHub Actions, Shorebird, Fastlane
4. `launch` — ❌ À faire : récapitulatif + Process.run flutter create
5. `featureGen` — ❌ À faire : générateur de feature Clean Arch sur projet existant

**API pub.dev:**
- Recherche: `https://pub.dev/api/search?q=<query>`
- Détails: `https://pub.dev/api/packages/<name>`

**How to apply:** Continuer la construction des étapes dans l'ordre naturel. Step 2 Dependencies est la plus complexe (split-screen search + API).
