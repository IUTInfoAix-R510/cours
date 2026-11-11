#!/bin/bash
# Génère _site/index.html, la page d'accueil du site Pages.
#
# Une ligne de tableau par séance (S1 à S8). Le support d'une séance est
# le premier fichier s<N>-*.md trouvé à la racine du dépôt : s'il existe,
# la ligne donne les liens HTML et PDF ; sinon, elle indique « À venir ».
#
# Appelé par :
# - .github/workflows/marp-pages.yml (étape Generate index page)
# - scripts/build-all.sh (build local complet)

set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p _site

# Nom (sans .md) du support de la séance $1, ou chaîne vide.
support_de() {
  local f
  for f in s"$1"-*.md; do
    if [ -f "$f" ]; then
      echo "${f%.md}"
      return 0
    fi
  done
  echo ""
}

seance_row() {
  local num="$1" semaine="$2" titre="$3" tp="$4" slug
  slug=$(support_de "$num")
  if [ -n "$slug" ]; then
    cat <<ROW
      <tr>
        <td>S${num}</td>
        <td>${semaine}</td>
        <td>${titre}</td>
        <td>${tp}</td>
        <td><a href="${slug}.html">HTML</a></td>
        <td><a href="${slug}.pdf">PDF</a></td>
      </tr>
ROW
  else
    cat <<ROW
      <tr>
        <td>S${num}</td>
        <td>${semaine}</td>
        <td>${titre}</td>
        <td>${tp}</td>
        <td colspan="2" class="a-venir">À venir</td>
      </tr>
ROW
  fi
}

ROWS=$(
  seance_row 1 "23/11" "MongoDB, documents et CRUD"                                  "TP1"
  seance_row 2 "23/11" "Documents imbriqués, tableaux, initiation à l'agrégation"    "TP1 (suite)"
  seance_row 3 "30/11" "Requêtes avancées, pipeline d'agrégation, index"             "TP2"
  seance_row 4 "30/11" "Modéliser à partir des requêtes, patterns de conception"      "TP3"
  seance_row 5 "7/12"  "Du relationnel au graphe : Neo4j et Cypher"                  "TP4 (Neo4j)"
  seance_row 6 "7/12"  "Lancement du projet, modèle de données, chargement"          "Projet"
  seance_row 7 "14/12" "Agrégations, API REST, index ; module graphe en bonus"       "Projet"
  seance_row 8 "14/12" "Finalisation et questions individuelles"            "Projet"
)

cat > _site/index.html <<HTMLEOF
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>R5.Real.10 - Points cours</title>
  <style>
    :root { --fond: #ffffff; --texte: #333333; --titre: #2c3e50; --accent: #1f6f50; --ligne: #e6e6e6; --survol: #f3f8f5; --discret: #777777; --lien: #1a5f8a; }
    @media (prefers-color-scheme: dark) {
      :root { --fond: #16191d; --texte: #e2e2e2; --titre: #f0f0f0; --accent: #2e8b66; --ligne: #2c3137; --survol: #1f2429; --discret: #9a9a9a; --lien: #7cc0ea; }
    }
    body { font-family: system-ui, sans-serif; max-width: 960px; margin: 2rem auto; padding: 0 16px; line-height: 1.6; color: var(--texte); background: var(--fond); }
    header { display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; }
    header img { width: 180px; max-width: 100%; height: auto; background: #ffffff; border-radius: 4px; padding: 4px; }
    h1 { color: var(--titre); border-bottom: 2px solid var(--accent); padding-bottom: 0.5rem; font-size: 1.6rem; }
    .tableau { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
    th { background: var(--accent); color: #ffffff; padding: 0.6rem; text-align: left; }
    td { padding: 0.6rem; border-bottom: 1px solid var(--ligne); vertical-align: top; }
    tr:hover td { background: var(--survol); }
    a { color: var(--lien); text-decoration: none; }
    a:hover { text-decoration: underline; }
    .a-venir { color: var(--discret); font-style: italic; }
    footer { margin-top: 2rem; padding-top: 1rem; border-top: 1px solid var(--ligne); font-size: 0.85rem; color: var(--discret); }
  </style>
</head>
<body>
  <header>
    <img src="assets/logo.png" alt="Aix-Marseille Université">
  </header>
  <h1>R5.Real.10 - Nouveaux paradigmes de base de données</h1>
  <p>IUT d'Aix-Marseille, BUT Informatique 3<sup>e</sup> année, 2026-2027.
     Chaque séance de 4 h commence par un point cours : les notions à connaître avant d'attaquer le TP.
     L'énoncé du TP reste la référence.</p>

  <div class="tableau">
  <table>
    <thead>
      <tr><th>Séance</th><th>Semaine du</th><th>Point cours</th><th>TP</th><th>Diapositives</th><th>PDF</th></tr>
    </thead>
    <tbody>
${ROWS}
    </tbody>
  </table>
  </div>

  <p>Énoncés en ligne : <a href="https://iutinfoaix-r510.github.io/tp1/">TP1</a>, <a href="https://iutinfoaix-r510.github.io/tp2/">TP2</a>, <a href="https://iutinfoaix-r510.github.io/tp3/">TP3</a>.
     Calendrier, évaluation et environnement de travail : <a href="https://github.com/IUTInfoAix-R510/syllabus">syllabus</a>.</p>

  <footer>
    <p>Supports générés depuis les sources Markdown avec <a href="https://marp.app/">Marp</a>.
       Ils sont diffusés sous licence <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr">CC BY-NC-SA 4.0</a>
       et reprennent des éléments de MongoDB for Academia (CC BY-NC-SA 3.0) :
       voir <a href="https://github.com/IUTInfoAix-R510/cours/blob/main/ATTRIBUTION.md">ATTRIBUTION.md</a>.</p>
    <p><a href="https://github.com/IUTInfoAix-R510/cours">Dépôt source</a></p>
  </footer>
</body>
</html>
HTMLEOF
