#!/bin/bash
# Build complet du site Pages en local (HTML + PDF + index + assets).
#
# Miroir local du workflow .github/workflows/marp-pages.yml : permet de
# vérifier le rendu complet (PDF et page d'index compris) avant de pousser.
#
# Usage : ./scripts/build-all.sh       (ou  npm run build:all)
#
# Dépendances :
# - npm / npx (marp-cli installé par `npm ci`)
# - un navigateur Chromium pour les PDF : Marp utilise Chrome ou Chromium
#   s'il est installé ; sinon, installer celui de Playwright avec
#   `npx playwright install chromium` (la CI le fait avec --with-deps).
#
# --no-stdin : sans cette option, Marp attend du Markdown sur l'entrée
# standard dès qu'elle n'est pas un terminal (tâche lancée par un outil,
# un agent ou un pipe) et la conversion reste bloquée.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== 1. Diapositives HTML ==="
mkdir -p _site
for f in s[0-9]*-*.md; do
  [ -f "$f" ] || continue
  name="${f%.md}"
  echo "  $f -> _site/${name}.html"
  npx marp --no-stdin --config marp.config.js --html "$f" --output "_site/${name}.html"
done

echo ""
echo "=== 2. Diapositives PDF ==="
for f in s[0-9]*-*.md; do
  [ -f "$f" ] || continue
  name="${f%.md}"
  echo "  $f -> _site/${name}.pdf"
  npx marp --no-stdin --config marp.config.js --html "$f" --pdf --output "_site/${name}.pdf" --allow-local-files
done

echo ""
echo "=== 3. Page d'index ==="
bash scripts/generate-index.sh
echo "  _site/index.html"

echo ""
echo "=== 4. Assets ==="
if [ -d assets ]; then
  rm -rf _site/assets
  cp -r assets _site/assets
  echo "  assets/ -> _site/assets/"
fi

echo ""
echo "=== Terminé ==="
echo "Ouvrir _site/index.html dans un navigateur pour vérifier le rendu."
