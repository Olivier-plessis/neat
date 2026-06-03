#!/usr/bin/env bash

# Fonction d'aide pour afficher l'utilisation du script
helpFunction() {
   echo ""
   echo "Usage: $0 -v versionType"
   echo -e "\tversionType: major, minor, patch ou build"
   echo "Exemple: $0 -v minor"
   exit 1 # Quitte le script après avoir affiché l'aide
}

# --- Traitement des arguments ---
versionType=""
while getopts "v:" opt; do
   case "$opt" in
      v ) versionType="$OPTARG" ;;
      ? ) helpFunction ;; # Affiche l'aide si un paramètre inconnu est passé
   esac
done

# Vérifie si le type de version est renseigné
if [ -z "$versionType" ]; then
   echo "Erreur: Le type de version (-v) est manquant."
   helpFunction
fi

# Vérifie que le type de version est valide
if [[ ! "$versionType" =~ ^(major|minor|patch|build)$ ]]; then
   echo "Erreur: Le type de version '$versionType' est invalide."
   echo "Les types valides sont: major, minor, patch, build."
   helpFunction
fi

# --- Extraction de la version actuelle ---
PUBSPEC_PATH="pubspec.yaml"

# Vérifie si le fichier pubspec.yaml existe
if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "Erreur: Le fichier pubspec.yaml n'a pas été trouvé à l'emplacement spécifié: $PUBSPEC_PATH"
    exit 1
fi

current_version_line=$(grep 'version:' "$PUBSPEC_PATH")

if [ -z "$current_version_line" ]; then
    echo "Erreur: La ligne 'version:' n'a pas été trouvée dans $PUBSPEC_PATH."
    exit 1
fi

# Extrait la version complète (ex: 1.3.10+20260218)
current_version=$(echo "$current_version_line" | sed 's/version: //g' | tr -d '[:space:]')

# Sépare le numéro de version (1.3.10) et le numéro de build (20260218)
version_number=$(echo "$current_version" | cut -d'+' -f1)
build_number=$(echo "$current_version" | cut -d'+' -f2)

# Sépare les composants de la version (major, minor, patch)
major=$(echo "$version_number" | cut -d'.' -f1)
minor=$(echo "$version_number" | cut -d'.' -f2)
patch=$(echo "$version_number" | cut -d'.' -f3)

# --- Calcul du nouveau numéro de version et de build ---

new_major=$major
new_minor=$minor
new_patch=$patch
new_build=""

if [ "$versionType" == "major" ]; then
   new_major=$((major + 1))
   new_minor=0
   new_patch=0
elif [ "$versionType" == "minor" ]; then
   new_minor=$((minor + 1))
   new_patch=0
elif [ "$versionType" == "patch" ]; then
   new_patch=$((patch + 1))
fi

# Génération du nouveau numéro de build au format AAAAMMJJ (plus lisible et unique)
new_build=$(date +%Y%m%d)

# Assemble la nouvelle version complète
new_full_version="${new_major}.${new_minor}.${new_patch}+${new_build}"

echo "Ancienne version: $current_version"
echo "Nouvelle version: $new_full_version"

# --- Mise à jour du fichier pubspec.yaml ---

# Utilisation de `sed` pour la mise à jour
# On préfère 'gsed' pour Linux/macOS si installé via Homebrew pour être sûr
# Si gsed n'est pas disponible, un sed standard (BSD sed sur macOS) est utilisé
# BSD sed nécessite une extension après -i, même vide ('')
if command -v gsed &> /dev/null; then
    sed_cmd="gsed"
    echo "Utilisation de gsed."
else
    sed_cmd="sed"
    echo "Utilisation de sed (potentiellement BSD sed, nécessitera -i '')."
fi

echo "Mise à jour de $PUBSPEC_PATH avec la nouvelle version..."

# Si sed_cmd est "sed" (BSD sed), ajoutez l'argument d'extension pour -i
if [ "$sed_cmd" == "sed" ]; then
    "$sed_cmd" -i '' "s/^version: .*/version: $new_full_version/" "$PUBSPEC_PATH"
else
    "$sed_cmd" -i "s/^version: .*/version: $new_full_version/" "$PUBSPEC_PATH"
fi


# Vérifie si la modification a réussi
if ! grep -q "version: $new_full_version" "$PUBSPEC_PATH"; then
    echo "Erreur: La mise à jour de la version dans pubspec.yaml a échoué."
    exit 1
fi

echo "La version a été mise à jour dans $PUBSPEC_PATH."

# --- Opérations Git ---

# Récupère la branche actuelle
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Nom de la nouvelle branche de release
release_branch_name="releases/v${new_full_version%%+*}"

echo "Ajout des modifications Git..."
git add "$PUBSPEC_PATH" # N'ajoute que le fichier modifié

# Vérifie s'il y a des modifications à committer avant de créer le commit
if git diff --cached --quiet; then
    echo "Aucune modification à committer pour pubspec.yaml."
    echo "Le script a terminé, mais aucune action Git n'a été effectuée car il n'y avait pas de changement."
    exit 0 # Quitte si rien n'a été modifié
fi

echo "Création de la branche de release: $release_branch_name"
git checkout -b "$release_branch_name" "$current_branch" # Crée et passe à la nouvelle branche basée sur la branche actuelle

echo "Création du commit Git sur la branche $release_branch_name..."
git commit -m "ci: Bump $versionType version to $new_full_version for release"

echo "Pousser la nouvelle branche de release vers l'origine..."
git push -u origin "$release_branch_name" # Pousse la nouvelle branche et la configure pour le suivi

# Création et push du tag
new_tag="v$new_full_version"
echo "Création du tag Git: $new_tag sur la branche $release_branch_name"
git tag "$new_tag"

echo "Pousser le tag vers l'origine..."
git push origin "$new_tag"

echo ""
echo "--------------------------------------------------------"
echo "Succès ! Une nouvelle branche de release '$release_branch_name' a été créée et poussée."
echo "Un tag '$new_tag' a également été créé et poussé."
echo "Vous êtes maintenant sur la branche '$release_branch_name'."
echo "N'oubliez pas de revenir à votre branche de développement après avoir fusionné la release."
echo "Pour revenir à votre branche précédente (ex: dev) : git checkout $current_branch"
echo "--------------------------------------------------------"

echo "Script terminé avec succès."
