# <img src="assets/logo.png" alt="Logo d'Aix-Marseille Université" class="logo" width="120"/> R5.Real.10 - Nouveaux paradigmes de base de données

### IUT d'Aix-Marseille, département Informatique, Aix-en-Provence

* **Ressource :** [R5.Real.10](https://www.enseignementsup-recherche.gouv.fr/sites/default/files/2023-12/informatique-30855.pdf#page=160) (programme national du BUT Informatique, fiche p. 160)
* **Équipe pédagogique :**
  * [Sébastien Nedjar](mailto:sebastien.nedjar@univ-amu.fr), responsable de la ressource, groupe GA1
  * [Leïla Sakli Miled](mailto:leila.SAKLI@univ-amu.fr), groupe GA2
* **Syllabus :** [IUTInfoAix-R510/syllabus](https://github.com/IUTInfoAix-R510/syllabus) : calendrier, évaluation, environnement de travail
* **Besoin d'aide ?**
  * Consultez ou créez une [issue](https://github.com/IUTInfoAix-R510/syllabus/issues) sur le dépôt du syllabus.
  * Pour une question d'ordre privé, écrivez à l'enseignant de votre groupe.

## Points cours

Il n'y a pas de cours magistral séparé. Chacune des 8 séances de 4 h commence par un **point cours** : il présente les notions à connaître avant d'attaquer le TP. Ce n'est pas un corrigé. Les exemples portent sur d'autres données que les exercices (films, recettes, capteurs...) et l'énoncé du TP reste la référence.

Les supports sont publiés sur https://iutinfoaix-r510.github.io/cours/.

| Séance | Semaine du | Point cours | TP | Support |
|---|---|---|---|---|
| S1 | 23/11 | MongoDB, documents et CRUD | TP1 | [diapositives](https://iutinfoaix-r510.github.io/cours/s1-ressource-et-mongodb.html) · [PDF](https://iutinfoaix-r510.github.io/cours/s1-ressource-et-mongodb.pdf) |
| S2 | 23/11 | Documents imbriqués, tableaux, initiation à l'agrégation | TP1 (suite) | [diapositives](https://iutinfoaix-r510.github.io/cours/s2-imbrication-tableaux-agregation.html) · [PDF](https://iutinfoaix-r510.github.io/cours/s2-imbrication-tableaux-agregation.pdf) |
| S3 | 30/11 | Requêtes avancées, pipeline d'agrégation, index | TP2 | [diapositives](https://iutinfoaix-r510.github.io/cours/s3-requetes-avancees-agregation-index.html) · [PDF](https://iutinfoaix-r510.github.io/cours/s3-requetes-avancees-agregation-index.pdf) |
| S4 | 30/11 | Modéliser à partir des requêtes, patterns de conception | TP3 | [diapositives](https://iutinfoaix-r510.github.io/cours/s4-modelisation-patterns.html) · [PDF](https://iutinfoaix-r510.github.io/cours/s4-modelisation-patterns.pdf) |
| S5 | 7/12 | Du relationnel au graphe : Neo4j et Cypher | TP4 (Neo4j) | À venir |
| S6 | 7/12 | Lancement du projet, modèle de données, chargement | Projet | À venir |
| S7 | 14/12 | Agrégations, API REST, index ; module graphe en bonus | Projet | À venir |
| S8 | 14/12 | Finalisation et questions individuelles | Projet | À venir |

Les jours et horaires de chaque groupe sont dans ADE.

### Énoncés des TP

- [TP1 : MongoDB, documents, CRUD, documents imbriqués, initiation à l'agrégation](https://iutinfoaix-r510.github.io/tp1/) (S1-S2)
- [TP2 : MongoDB, requêtes avancées, agrégation, index, géospatial, pilote Java](https://iutinfoaix-r510.github.io/tp2/) (S3)
- [TP3 : MongoDB, modéliser à partir des requêtes, patterns de conception, séries temporelles, pilote Java](https://iutinfoaix-r510.github.io/tp3/) (S4)
- TP4 et projet : à venir. Les liens seront ajoutés ici et dans le [syllabus](https://github.com/IUTInfoAix-R510/syllabus).

### Environnement

Les supports suivent l'environnement des TP : GitHub Codespaces uniquement, avec MongoDB 9.0 lancé dans le codespace, `mongosh` et l'extension MongoDB pour VS Code (playgrounds `*.mongodb.js`). Pas de compte Atlas, pas de Compass. Chaque exemple de code d'un support est exécuté sur MongoDB 9.0.4, et le résultat affiché est celui obtenu.

## Format des supports

Les supports sont écrits en Markdown avec un en-tête [Marp](https://marp.app/), un fichier par séance : `s<N>-<sujet>.md`. Ils se lisent directement sur GitHub et se modifient dans VS Code avec l'extension Marp (aperçu en direct).

Commandes disponibles après `npm ci` :

| Commande | Effet |
|---|---|
| `npm run dev` | Serveur Marp avec rechargement automatique |
| `npm run preview` | Aperçu des supports dans une fenêtre |
| `npm run build:html` | Diapositives HTML dans `_site/` (rapide) |
| `npm run build:all` | Chaîne complète : HTML, PDF, page d'index et assets, comme le [workflow de publication](.github/workflows/marp-pages.yml) |

Le PDF demande un navigateur Chrome ou Chromium. À défaut, `npx playwright install chromium` en installe un.

La publication sur GitHub Pages se fait à chaque push sur `main`.

## Organisation du dépôt

```
cours/
├── s1-ressource-et-mongodb.md             # S1 : point cours du TP1
├── s2-imbrication-tableaux-agregation.md  # S2 : point cours du TP1 (suite)
├── s3-requetes-avancees-agregation-index.md  # S3 : point cours du TP2
├── s4-modelisation-patterns.md               # S4 : point cours du TP3
├── themes/
│   └── r510.css                           # thème Marp commun (« theme: r510 »)
├── assets/
│   ├── logo.png, logo-amu.png             # logo d'Aix-Marseille Université
│   └── schemas/                           # schémas SVG faits pour le cours (préfixe sN- par séance)
├── .vscode/settings.json                  # déclare le thème pour l'aperçu Marp de VS Code
├── scripts/
│   ├── build-all.sh                       # build local complet (miroir du workflow)
│   └── generate-index.sh                  # page d'accueil _site/index.html
└── ATTRIBUTION.md                         # licences du dépôt, sources et éléments repris
```

Un élément repris de MongoDB for Academia irait dans `assets/mongodb-academia/`, selon la règle de citation d'[ATTRIBUTION.md](ATTRIBUTION.md). Il n'y en a aucun pour l'instant.

### Structure d'un support

Les supports suivent le même plan :

- une diapo d'intercalaire `_class: lead` « Partie N - … » pour chaque partie de l'énoncé, avec un émoji repère et une phrase d'accroche ;
- le principe d'abord (le quoi et le pourquoi), l'exemple ensuite (le comment) ;
- pour un processus (un pipeline, par exemple) : une diapo pour les données, puis une diapo par étape ;
- une idée par diapo, sans diapo vide ni surchargée, avec des cartes de même hauteur ;
- « À vous » en deux diapos : la séance (lien de l'énoncé, minutage, rendu, date du rendu final), puis « essayer et réviser » (quiz) ;
- « Des questions ? » (enseignants, liens, bandeau « Dès maintenant » et appel à l'action en remarque), puis les crédits ;
- la durée de chaque diapo dans ses notes, le total de la séance dans les notes de « À vous » ;
- le résultat d'une requête en commentaire `// …` sous la requête, dans le même bloc de code ; le détail document par document, s'il en faut un, dans un tableau ; une erreur dans un bloc `err` (fond rouge), jamais dans un bloc vert ;
- les données d'exemple présentées sur une diapo, et le script qui les recharge dans les notes.

Les émojis servent de repères sur les étiquettes et les remarques (🎯, 📅, 🧪, 🧠, ❓, 🤖), pas sur chaque titre.

### Thème commun

Tous les supports utilisent `theme: r510` (fichier `themes/r510.css`, déclaré dans `marp.config.js`). Le thème reprend le vocabulaire visuel des cours de R2.03 et R2.02, avec le vert MongoDB pour les titres. Pas de bloc `<style>` global dans un support : un réglage propre à une diapo va dans un `<style scoped>`.

| Classe | Usage |
|---|---|
| `cols`, `g2`, `g3`, `cols-62`, `cols-38` | grilles à 2 ou 3 colonnes |
| `carte` (+ `vert`, `orange`, `violet`, `rouge`) | carte à en-tête coloré : `<div class="carte vert"><b class="t">Titre</b> texte</div>` |
| `box`, `warn`, `alerte` | remarque à bordure gauche : verte, orange, rouge |
| `bandeau` | bandeau bleu nuit : lien, appel à l'action, message à retenir |
| `err` | bloc de code d'erreur (fond rouge) |
| `res`, `res-titre` | ancien bloc de résultat : ne plus l'utiliser, le résultat va en commentaire `// …` sous la requête |
| `etiquette`, `legende`, `note`, `petit`, `centre` | petits textes |

Les marges négatives s'écrivent en `em` : Marp réécrit `-1rem` en `-calc(…)`, que le navigateur ignore.

Le signe `$` des opérateurs MongoDB peut déclencher le moteur de formules de Marp. Dans le texte Markdown, Marp met en formule ce qui se trouve entre deux `$` : `$match puis $group$` devient une formule. Ce texte-là compte aussi comme du Markdown :

- une balise HTML écrite dans un paragraphe ou une liste Markdown : `- <b>$sum</b> et <b>$avg</b>` ;
- du Markdown placé dans un `<div>` entre deux lignes vides.

D'où la règle :

- dans le Markdown, les opérateurs vont entre backticks (`` `$match` ``) ; les blocs de code, les notes et les attributs `alt` gardent le `$` tel quel ;
- dans tout HTML brut (cartes, `p.petit`, `p.etiquette`, `<code>` écrit en HTML), le `$` s'écrit `&#36;` ;
- jamais `\$`, qui s'afficherait tel quel dans du HTML.

Pour vérifier un support, compter les `<mjx-container` dans le HTML construit (hors `<style>`) : il doit y en avoir zéro.

## Pour aller plus loin

Les présentations officielles du programme **MongoDB for Academia** servaient de support de cours jusqu'en 2025. Nos supports n'en reprennent aucun schéma ; le support S2 en reformule deux passages (voir [ATTRIBUTION.md](ATTRIBUTION.md)). Les présentations complètes restent utiles pour approfondir, avec trois précautions :

- elles sont **en anglais** ;
- elles ont été écrites pour MongoDB Atlas et l'ancien shell `mongo` : les résultats s'affichent autrement dans votre codespace ;
- certaines utilisent des méthodes obsolètes. Dans les TP, on écrit `countDocuments()` et non `count()`, `updateOne()` / `updateMany()` et non `update()`, `deleteOne()` / `deleteMany()` et non `remove()`, `insertOne()` / `insertMany()` et non `insert()`.

| Présentation | Thèmes | Séances |
|---|---|---|
| [MongoDB 101: Non-Relational for Beginners](https://docs.google.com/presentation/d/1b_4GoeSsdtL-B4Qvm6Bo1Ml9G4IIEkRxbZq4Wa6f7O4/edit?usp=sharing) | du relationnel au NoSQL, familles NoSQL, modèle document, embarquer ou référencer | S1, S2 |
| [Querying in Relational and Non-Relational Databases](https://docs.google.com/presentation/d/1G9WdYIkQzSCszzrHqhlHbSjYxjY7qwrIfJVhaz9GTNA/edit?usp=sharing) | modèle tabulaire et modèle document | S1 |
| [The MongoDB Query Language (MQL)](https://docs.google.com/presentation/d/1Clw2TMYSVAXLKJO35y_n4OTkHyZ34f91hXzhrLYHSpM/edit?usp=sharing) | `find`, opérateurs de comparaison et logiques, CRUD | S1 |
| [Querying Data with Operators and Compound Conditions](https://docs.google.com/presentation/d/1sW52E0YZ4DhGhEQQa29yEBuWNqZBHzzaaRuix7jZFmY/edit?usp=sharing) | conditions composées, `$expr` | S1, S3 |
| [Inserting and Updating Data in MongoDB](https://docs.google.com/presentation/d/19BrnUsVLjZmk-rR3n0EtKHGKszFkaGmA9xY2aCrUlnU/edit?usp=sharing) | insertion, mise à jour, idempotence | S1 |
| [Deleting Data in MongoDB](https://docs.google.com/presentation/d/1SUuvsPBjzcxPnPJlzaUjdXNTHA0CkBobN0shralGBN4/edit?usp=sharing) | `deleteOne`, `deleteMany`, `drop`, index TTL | S1, S4 |
| [Querying Complex Data in MongoDB with MQL](https://docs.google.com/presentation/d/16rfnVscMzr8PLD9nRDvm-1zDQaYeBRKk1NrJeVj2Wrs/edit?usp=sharing) | documents imbriqués, notation pointée, tableaux, `$elemMatch`, projection | S2 |
| [The MongoDB Aggregation Framework](https://docs.google.com/presentation/d/1skcbXmW62Mk_fkq99h1K2RPErmYT1flZ2b36DChFGy0/edit?usp=sharing) | pipeline, étapes, `$group`, `$addFields`, `$out`, `$merge` | S2, S3 |
| [Querying Data with the MongoDB Aggregation Framework](https://docs.google.com/presentation/d/13RojmrfLRe6WLVxQjB9eC1g_kDPeCKpS18DCUawE07g/edit?usp=sharing) | `$match`, `$project`, `$unwind`, `$facet`, `$bucket` | S2, S3 |
| [Data Modeling and Schema Design Patterns](https://docs.google.com/presentation/d/1gmU38CZRgmVOYs66E16wvDO_ystf8jKJN2QEoBM2oX4/edit?usp=sharing) | embarquer ou référencer, patterns Polymorphic, Schema Versioning, Attribute, Bucket, Subset | S4 |

Autres références :

- [Manuel MongoDB](https://www.mongodb.com/docs/manual/), la référence complète ;
- [MongoDB University](https://learn.mongodb.com/), cours gratuits en anglais ;
- les autres ressources du [syllabus](https://github.com/IUTInfoAix-R510/syllabus).

## Licences

Les supports sont sous [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr), les éléments repris de MongoDB for Academia restent sous CC BY-NC-SA 3.0, et les scripts sous [GPL-3.0](LICENSE). Le détail, les sources et la liste des éléments repris sont dans [ATTRIBUTION.md](ATTRIBUTION.md).
