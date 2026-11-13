---
marp: true
theme: r510
paginate: true
lang: fr
title: "Séance 3 : requêtes avancées, agrégation, index"
description: "R5.Real.10, point cours de la séance 3 (TP2, parties 1 à 6)"
---


<!-- _class: lead -->
<!-- _paginate: false -->

<style scoped>
section {
  background-image: url('assets/logo.png');
  background-repeat: no-repeat;
  background-position: bottom 40px center;
  background-size: 340px;
}
h1 { font-size: 1.9em; }
p.question { font-size: 0.85em; color: #5c6c75; font-style: italic; margin-top: 0.8em; }
</style>

# Requêtes avancées, agrégation, index

**R5.Real.10 - Nouveaux paradigmes de base de données**

Séance 3 · TP2 · semaine du 30 novembre 2026

<p class="question">Le tableau de bord d'une cinémathèque : quelles questions lui poser, comment y répondre vite, comment le servir ?</p>

<!--
(20 s)

Question directrice de la séance, posée ici, reprise en sous-titre de chaque intercalaire et conclue dans les deux « À retenir ». Ses trois morceaux suivent le TP : quelles questions (parties 1 à 3), y répondre vite (partie 4), le servir (partie 6, en Java). La partie 5 (« où ? ») ajoute une question de plus au tableau de bord.

Le point cours se fait en deux temps (somme des durées notées en tête de chaque diapo) :
- premier temps, en début de séance : diapos 1 à 31 (ouverture, parties 1 à 4, « À retenir ») en 23 min 40, puis les deux diapos « À vous » (32 et 33) en 1 min 20 : 25 min ;
- second temps, quand la majorité du groupe attaque la partie 5 : diapos 34 à 44 (géospatial, Java et Javalin, « À retenir », « Des questions ? ») en 7 min 30. Les diapos Java servent aussi de référence pour la partie 6, faite en autonomie.

Une prédiction par partie (diapo question, puis diapo réponse) : diapos 8-9, 14-15, 19-20, 26-27, puis 36-37 et 41-42 au second temps.

L'annexe, après les Crédits, n'est pas projetée : rangs ($denseRank), fenêtre en image, index et lecture d'un plan, règles secondaires de $bucket, lecture d'un $facet, pilote Java, paramètres et statuts d'une route, types BSON. $merge (bonus 4 du TP2) et $jsonSchema (TP3) sont enseignés au point cours S4 : ils ne sont plus dans ce support.

Les exemples portent sur les films de l'énoncé (collections films et realisateurs, base tp2), jamais sur les exercices ; seules la diapo des données et celle d'explain() montrent les restaurants, comme l'énoncé. Tout a été exécuté sur MongoDB 9.0.4 et les résultats affichés sont ceux obtenus. Le script des films est dans les notes de la diapo 4.
-->

---

<!-- header: Séance 3 · objectifs -->

## Un tableau de bord pour une cinémathèque

<div class="bandeau" style="font-size: 0.9em;">

❓ Quelles **questions** lui poser, comment y répondre **vite**, comment le **servir** ?

</div>

<div class="g2" style="margin-top: 0.9rem; font-size: 0.76em; align-items: stretch;">
<div class="carte vert">
<b class="t">🎯 À la fin de la séance, vous saurez</b>

1. **filtrer** en comparant deux valeurs d'un document, sur des données sales (partie 1) ;
2. **calculer** sans perdre les documents : champs ajoutés, rangs, tendances (partie 2) ;
3. **joindre**, répartir en tranches, résumer en une requête (partie 3) ;
4. **mesurer** une requête et choisir son index (partie 4), puis la **servir** en Java (partie 6).

</div>
<div class="carte">
<b class="t">Déjà vu au TP1 (séances 1 et 2)</b>

- le pipeline : `$match`, `$unwind`, `$group`, `$project`, `$sort` ;
- `$avg` et `$size` sur le tableau d'un document ;
- `$elemMatch` : deux conditions sur **un même** élément ;
- embarquer ou référencer ;
- les films : Chihiro, les Glaneurs, La Haine, Amélie.

</div>
</div>

<!--
(1 min)

Lire la question directrice : elle donne l'ordre de la séance. Le tableau de bord n'est pas un exercice : c'est le fil des exemples (les films d'une cinémathèque) ; le TP fait la même chose sur les restaurants de New York.

Les objectifs reprennent les « Objectif » des parties de l'énoncé. « Déjà vu » : tout vient du TP1. En S2, $avg et $size calculaient sur le tableau d'un capteur, dans un $project. $elemMatch revient tel quel à l'exercice 1 : sur les films, { "notes.source": "public", "notes.note": 5 } en trouve 2, $elemMatch 0 (énoncé, partie 1).
-->

---

<!-- header: Séance 3 · les données -->

## Les données du TP : les restaurants de New York

<img src="assets/schemas/s3-donnees.svg" alt="Les trois collections de la base tp2. restaurants, 25 359 documents : _id ; address, document imbriqué avec building, street, zipcode et coord (longitude, latitude) ; borough ; cuisine ; grades, tableau de documents date, grade, score, de la plus récente à la plus ancienne ; name ; restaurant_id, une chaîne. neighborhoods, 195 documents : name et geometry, un Polygon ou un MultiPolygon GeoJSON. boroughs, 5 documents créés pour le TP : code FIPS, nom, comte, population du recensement 2020, superficie. Le champ borough des restaurants correspond au champ nom de boroughs ($lookup, partie 3) ; les coordonnées d'un restaurant tombent dans la geometry d'un quartier ($geoWithin, partie 5). Le score compte des points de pénalité : plus il est bas, mieux c'est." style="display:block; width:100%; margin:0.2rem auto 0 auto;">

<div class="box" style="margin-top: 0.3rem; font-size: 0.7em;"><b>Des données réelles</b>, avec leurs défauts : restaurants jamais inspectés, scores à <code>null</code>, un borough « Missing ». Les repérer fait partie du travail.</div>

<!--
(1 min)

Un vrai jeu de données, publié par MongoDB : les inspections sanitaires des restaurants de New York (NYC Open Data). Provenance et licences dans data/PROVENANCE.md du dépôt.

Faire lire la structure d'un restaurant : address est un document imbriqué, grades un tableau de documents, rangés de la plus récente à la plus ancienne inspection. Les notes A, B, C correspondent normalement aux scores 0-13, 14-27, 28 et plus.

Les défauts, comptés sur MongoDB 9.0.4 : 738 restaurants sans inspection, 13 scores à null, 51 restaurants au borough « Missing », des noms vides. Ne pas les montrer plus : l'exercice 3 les cherche.

boroughs a été construite pour le TP, avec des chiffres du US Census Bureau ; elle sert au $lookup de la partie 3. neighborhoods sert au géospatial (partie 5).
-->

---

## Les films, désormais référencés

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
</style>

<p class="petit">Les films de S1 et S2 (sans Totoro). En S2, la réalisation était <b>imbriquée</b> ; ici, le film ne garde que le nom, et le pays est rangé <b>une fois</b>, dans <code>realisateurs</code>.</p>

| titre | annee | duree | realisateur | notes : source note (date) |
|---|---|---|---|---|
| Le Voyage de Chihiro | 2001 | 125 | `"Miyazaki"` | presse 5 (14/01), public 4 (02/03) |
| Les Glaneurs et la Glaneuse | 2000 | 82 | `"Varda"` | presse 4 (28/01) |
| La Haine | 1995 | 98 | `"Kassovitz"` | presse 5 (09/02), public 2 (20/04) |
| Amélie Poulain | 2001 | 122 | `"Jeunet"` | *aucune* : `[]` |

<div class="cols" style="margin-top: 0.5rem;">
<div class="box"><code>realisateurs</code> : Miyazaki (Japon), Varda et Jeunet (France). <b>Pas de Kassovitz.</b></div>
<div class="box">Les dates des notes sont de 2026. L'énoncé charge les mêmes films, <b>sans</b> ces dates.</div>
</div>

<!--
(40 s)

La même collection films qu'en S1 et S2, troisième état : plate en S1, imbriquée en S2 (realisation: { nom, pays }), référencée en S3 (realisateur: "Miyazaki", et le pays dans realisateurs). Ce sont aussi les films d'entraînement de l'énoncé et des skills du tuteur (approfondir-une-notion, quiz-thematique) ; Totoro n'y est pas. Chaque film a un _id ObjectId généré, que les diapos masquent.

Les notes sont rangées de la plus ancienne à la plus récente (presse, puis public). Les dates ne servent qu'à la diapo 16 (« la tendance du mois ») ; le bloc de l'énoncé, sans dates, suffit pour toutes les autres, et leurs résultats sont identiques.

Script à coller dans essais.mongodb.js pour rejouer toutes les diapos (il vide d'abord les deux collections) :

use('tp2');
db.films.deleteMany({});
db.films.insertMany([
  { titre: "Le Voyage de Chihiro", annee: 2001, duree: 125, realisateur: "Miyazaki", genres: ["animation", "fantastique"],
    notes: [{ source: "presse", note: 5, date: ISODate("2026-01-14") }, { source: "public", note: 4, date: ISODate("2026-03-02") }] },
  { titre: "Les Glaneurs et la Glaneuse", annee: 2000, duree: 82, realisateur: "Varda", genres: ["documentaire"],
    notes: [{ source: "presse", note: 4, date: ISODate("2026-01-28") }] },
  { titre: "La Haine", annee: 1995, duree: 98, realisateur: "Kassovitz", genres: ["drame"],
    notes: [{ source: "presse", note: 5, date: ISODate("2026-02-09") }, { source: "public", note: 2, date: ISODate("2026-04-20") }] },
  { titre: "Amélie Poulain", annee: 2001, duree: 122, realisateur: "Jeunet", genres: ["comédie", "romance"], notes: [] }
]);
db.realisateurs.deleteMany({});
db.realisateurs.insertMany([
  { nom: "Miyazaki", pays: "Japon" }, { nom: "Varda", pays: "France" }, { nom: "Jeunet", pays: "France" }
]);
-->

---

<!-- header: Partie 1 · filtrer -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 1 - 🔎 Requêtes avancées

Quels films la presse a-t-elle préférés au public ? Quelles fiches sont mal saisies ?

<!--
(10 s)

Même titre que la partie 1 de l'énoncé du TP2 (ex. 1 à 3). Deux premières questions au tableau de bord : elles demandent de comparer le document à lui-même, puis de repérer des données sales.
-->

---

## Le réflexe du TP1 ne trouve rien

<p>Les films que la presse a <b>mieux notés</b> que le public. En SQL, deux colonnes d'une même ligne : <code>WHERE note_presse &gt; note_public</code>.</p>

```js
db.films.find(
  { "notes.0.note": { $gt: "$notes.1.note" } },   // la 1re note contre la 2e ?
  { _id: 0, titre: 1 })
// []
```

<div class="cols" style="margin-top: 0.6rem; align-items: stretch;">
<div class="warn">

Ni erreur ni résultat : dans un filtre, `"$notes.1.note"` est une **chaîne**. On compare une note à un texte.

</div>
<div class="box">

**Déjà vu en S2** : `{ $match: { piece: "$piece" } }` ne renvoyait rien, pour la même raison.

</div>
</div>

<!--
(45 s)

Le besoin d'abord. La traduction naïve de WHERE a > b : notes.0.note (la note d'indice 0, notation pointée du TP1) comparée à "$notes.1.note". Résultat obtenu sur MongoDB 9.0.4 : [], sans erreur. La même requête avec une constante, { "notes.0.note": { $gt: 4 } }, renvoie bien Chihiro et La Haine : c'est la comparaison à un autre champ qui ne marche pas.

Le $ n'est interprété comme « valeur du champ » que dans une expression d'agrégation. S2 l'avait annoncé dans « Écrire un pipeline sans se tromper » (dernière ligne du tableau) : « comparer deux champs d'un même document demande $expr, vu au TP2 ».
-->

---

## `$expr` : les expressions du pipeline, dans un filtre

<img src="assets/schemas/s3-expr.svg" alt="Sur le même film, La Haine. À gauche, un filtre classique, { duree: { $gt: 100 } }, compare une valeur du document (duree, 98) à une constante écrite dans la requête (100) : faux, le film est écarté. À droite, { $expr: { $gt: [A, B] } } compare deux valeurs du même document : A, la première note (5), et B, la dernière (2) ; 5 > 2, vrai, le film est retenu." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="dense">

```js
db.films.find(
  { $expr: { $gt: [
      { $arrayElemAt: ["$notes.note", 0] },    // A : la première note
      { $arrayElemAt: ["$notes.note", -1] }    // B : la dernière
  ] } },
  { _id: 0, titre: 1 })
// [ { titre: 'Le Voyage de Chihiro' }, { titre: 'La Haine' } ]
```

</div>

<div class="warn" style="font-size: 0.74em;">

**Piège** : pas d'indice dans un chemin d'**expression**. `"$notes.0.note"` y vaut `[]`, sans erreur : pour un élément, `$arrayElemAt` (`0` le premier, `-1` le dernier).

</div>

<!--
(1 min 15)

Lire le schéma par ses couleurs : en bleu, ce qui vient du document ; en ambre, ce qui est écrit dans la requête. À gauche, une seule valeur vient du document ; à droite, les deux.

$expr accepte les expressions du pipeline, celles de $project et $addFields : { $gt: [A, B] } compare deux valeurs calculées pour chaque document. "$notes.note" est le tableau des notes du film ([5, 4] pour Chihiro). C'est l'exemple de l'énoncé. Résultat obtenu sur MongoDB 9.0.4 ; par un $project avec les mêmes expressions : Chihiro A 5, B 4 ; Glaneurs A 4, B 4 (une seule note, A = B, faux) ; La Haine A 5, B 2 ; Amélie, tableau vide, $arrayElemAt ne renvoie rien et la comparaison est fausse.

Le piège, vérifié sur 9.0.4 : { $project: { a: "$notes.0.note" } } donne a: [] pour chaque film, et { $expr: { $gt: ["$notes.0.note", "$notes.1.note"] } } ne renvoie aucun film. La notation pointée avec indice ne vaut que dans un filtre ou une projection de find.

Le coût : $expr se calcule document par document et profite rarement d'un index ; une égalité classique à côté, dans le même filtre, réduit les documents à examiner. Dans les restaurants, grades est rangé de la plus récente à la plus ancienne inspection : l'indice 0 est la plus récente (exercice 2).
-->

---

## ❓ Deux films mal saisis : que trouve chaque filtre ?

<div class="dense">

```js
db.films.insertMany([
  { titre: "Film sans durée", annee: 2003, duree: null, notes: [] },
  { titre: "Film inconnu", annee: "1999", notes: [] } ])   // pas de duree

db.films.countDocuments({ duree: null })                  // ?
db.films.countDocuments({ duree: { $type: "null" } })     // ?
db.films.countDocuments({ duree: { $exists: false } })    // ?
db.films.find({ annee: { $gte: 1990 } }, { _id: 0, titre: 1 })
                                    // « Film inconnu » en fait-il partie ?
```

</div>

<div class="box" style="font-size: 0.8em; margin-top: 0.8rem;">

❓ **À vous de prédire**, avant la diapo suivante : trois nombres, et un oui ou un non.

</div>

<!--
(20 s)

Prédiction de la partie 1. Laisser la salle répondre. Réponses fréquentes : 1, 1, 1, et « oui, 1999 ≥ 1990 ».

Ce n'est pas une question de l'énoncé : on montre les briques (null, absent, type), pas l'exercice 3.
-->

---

## `null`, absent, ou d'un autre type

<style scoped>
table { display: table; width: 100%; font-size: 0.76em; }
</style>

| Filtre | Trouve | Ici |
|---|---|---|
| `{ duree: null }` | `duree` vaut `null` **ou** n'existe pas | **2** |
| `{ duree: { $type: "null" } }` | `duree` existe et vaut `null` | 1 |
| `{ duree: { $exists: false } }` | `duree` n'existe pas | 1 |
| `{ annee: { $gte: 1990 } }` | un **nombre** ≥ 1990 : `"1999"` est une chaîne | Film inconnu **absent** |
| `{ annee: { $type: "string" } }` | `annee` écrite en texte | Film inconnu |

<div class="warn" style="margin-top: 0.7rem;">

Un schéma libre accepte un champ manquant ici, un `null` là, un nombre en texte ailleurs : **sans erreur**, ils faussent les résultats. Sur un jeu réel, on les cherche **avant** de calculer.

</div>

<!--
(1 min)

Réponses obtenues sur MongoDB 9.0.4 avec les deux films ajoutés : 2, 1, 1 ; le find renvoie les 4 films de l'énoncé et « Film sans durée », pas « Film inconnu » : $gte ne compare que des valeurs de même famille de types (ici les nombres). { annee: { $type: "string" } } ne trouve que « Film inconnu ». La liste des noms de types ($type: "int", "double", "date"...) est en annexe.

Penser à recharger les films (script de la diapo 4) avant la suite.

C'est l'exercice 3 : une consigne qui dit « enregistré à null (le champ existe et vaut null) » appelle une seule de ces écritures.
-->

---

<!-- header: Partie 2 · calculer -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 2 - 🧮 Calculer

Pour chaque film : combien de notes, quel rang dans son année ? Et la tendance des notes, mois après mois ?

<!--
(10 s)

Même titre que la partie 2 de l'énoncé (ex. 4 à 6) : $addFields et fenêtres.
-->

---

## Ajouter un calcul sans perdre les champs : `$addFields`

<div class="err dense">

```text
db.films.aggregate([ { $project: { titre: 1 } },
                     { $addFields: { nb_notes: { $size: "$notes" } } } ])
MongoServerError: … The argument to $size must be an array, but was of type: missing
```

</div>

<p class="petit" style="margin: 0.2rem 0 0.3rem;"><code>&#36;project</code> a retiré <code>notes</code>, et tout ce qu'il ne cite pas. <code>&#36;addFields</code> <b>ajoute</b> et garde le reste :</p>

<img src="assets/schemas/s3-addfields.svg" alt="Le film Chihiro avant et après $addFields: { nb_notes: { $size: &quot;$notes&quot; } }. L'expression &quot;$notes&quot; donne la valeur du champ notes, un tableau de 2 documents ; $size donne sa taille, 2. Après l'étape, les champs du film sont toujours là, et nb_notes: 2 est ajouté à la fin." style="display:block; width:100%; margin:0 auto;">

<div class="dense">

```js
db.films.aggregate([
  { $addFields: { nb_notes: { $size: "$notes" } } },          // ajouté à chaque film
  { $project: { _id: 0, titre: 1, nb_notes: 1 } }, { $sort: { titre: 1 } } ])
// { titre: 'Amélie Poulain', nb_notes: 0 }
// { titre: 'La Haine', nb_notes: 2 }
// { titre: 'Le Voyage de Chihiro', nb_notes: 2 }
// { titre: 'Les Glaneurs et la Glaneuse', nb_notes: 1 }
```

</div>

<!--
(1 min)

Le besoin, à l'écran d'abord : on veut le nombre de notes de chaque film, sans perdre ses autres champs. Le réflexe $project choisit les champs : placé avant, il retire notes, et le calcul échoue. Erreur obtenue sur MongoDB 9.0.4 (message complet : « Executor error during aggregate command on namespace: tp2.films :: caused by :: The argument to $size must be an array, but was of type: missing »).

$addFields ajoute (ou remplace) des champs et garde tous les autres, qui restent disponibles pour les étapes suivantes (un $match, un $sort...). En SQL : SELECT *, … plutôt que SELECT titre, …. Le $project vient après le calcul.

Résultat obtenu sur MongoDB 9.0.4. L'énoncé montre le même exemple, avec annee dans la projection.

$avg et $size calculent sur le tableau d'un document, comme dans le $project des capteurs en S2 (« Par document ou par groupe ? »). L'exercice 4 utilise $addFields, puis un filtre sur un champ calculé : ne pas en dire plus.
-->

---

## Le plus long film de chaque année : `$group` perd les films

<div class="cols" style="grid-template-columns: 1fr 1fr; align-items: center;">
<div>

```js
db.films.aggregate([
  { $group: { _id: "$annee",
      plus_long: { $max: "$duree" } } },
  { $sort: { _id: 1 } }
])
// { _id: 1995, plus_long: 98 }
// { _id: 2000, plus_long: 82 }
// { _id: 2001, plus_long: 125 }
```

</div>
<div class="warn">

3 documents : **un par année**. Quel film dure 125 min ? Le titre a disparu, et Amélie aussi.

</div>
</div>

<div class="box" style="margin-top: 1rem;">

On veut **chaque film**, avec son **rang** dans son année : un calcul **sur le groupe**, sans fusionner les documents. En SQL : `RANK() OVER (PARTITION BY annee …)`.

</div>

<!--
(40 s)

Le besoin : « le film le plus long de chaque année, et le rang de chaque film dans son année ». Le réflexe du TP1, $group, résume chaque groupe en un document : on obtient la durée maximale, mais plus le film. Résultat obtenu sur MongoDB 9.0.4.

$setWindowFields correspond aux fonctions de fenêtre de SQL (R4.03) ; sinon, la présenter comme un $group qui ne fusionne pas les documents.
-->

---

## `$setWindowFields` : partitionner, trier, calculer

<img src="assets/schemas/s3-fenetre-rang.svg" alt="$setWindowFields en trois temps sur les 4 films. 1, partitionBy: &quot;$annee&quot; : trois groupes, 1995 (La Haine), 2000 (Glaneurs), 2001 (Amélie et Chihiro, dans un ordre quelconque). 2, sortBy: { duree: -1 } : en 2001, Chihiro (125 min) passe avant Amélie (122 min). 3, output: { rang: { $rank: {} } } : chaque film reçoit son rang dans son groupe, La Haine 1, Glaneurs 1, Chihiro 1, Amélie 2. En SQL : RANK() OVER (PARTITION BY annee ORDER BY duree DESC)." style="display:block; width:100%; margin:0.1rem auto 0;">

```js
{ $setWindowFields: { partitionBy: "$annee", sortBy: { duree: -1 },
                      output: { rang: { $rank: {} } } } }
```

<p class="petit">Les 4 films ressortent, avec tous leurs champs et <code>rang</code>. Deux ex aequo ont le même rang, puis un rang est sauté (annexe : <code>&#36;denseRank</code>).</p>

<!--
(1 min 5)

Dérouler les trois temps de gauche à droite : partitionBy découpe en groupes (sans lui, un seul groupe), sortBy ordonne chaque groupe (avant le tri, Amélie et Chihiro arrivent dans un ordre quelconque), output nomme le champ ajouté et dit comment le calculer.

Avec { $project: { _id: 0, titre: 1, annee: 1, duree: 1, rang: 1 } } et { $sort: { annee: 1, rang: 1 } } derrière, MongoDB 9.0.4 renvoie : La Haine 1995 98 rang 1, Les Glaneurs et la Glaneuse 2000 82 rang 1, Le Voyage de Chihiro 2001 125 rang 1, Amélie Poulain 2001 122 rang 2 (exemple de l'énoncé). Ajouter un $sort si l'ordre de sortie compte.

L'exercice 5 demande $rank : deux ex aequo ont le même rang.
-->

---

## ❓ Après un `$group`, où est passée la source ?

<p class="petit" style="margin-bottom: 0.2rem;">Pour chaque source (presse, public) : combien d'années de sortie notées, et la meilleure moyenne ? D'abord un <code>&#36;group</code> dont l'<code>_id</code> est un <b>document à deux champs</b> :</p>

<div class="dense">

```js
db.films.aggregate([
  { $unwind: "$notes" },
  { $group: { _id: { source: "$notes.source", annee: "$annee" },
              moyenne: { $avg: "$notes.note" } } },
  { $sort: { "_id.source": 1, "_id.annee": 1 } }
])
// { _id: { source: 'presse', annee: 1995 }, moyenne: 5 }
// { _id: { source: 'presse', annee: 2000 }, moyenne: 4 }
// { _id: { source: 'presse', annee: 2001 }, moyenne: 5 }
// { _id: { source: 'public', annee: 1995 }, moyenne: 2 }
// { _id: { source: 'public', annee: 2001 }, moyenne: 4 }
```

</div>

<div class="box" style="font-size: 0.8em;">

❓ Étape suivante, un second `$group` par source : `_id: "$source"` ou `_id: "$_id.source"` ? Que rend l'**autre** ?

</div>

<!--
(30 s)

Prédiction de la partie 2 : l'erreur de référence, la plus fréquente (lire la forme du document qui sort de l'étape). Après le premier $group, il n'y a plus de champ source : il est dans _id.

Résultat obtenu sur MongoDB 9.0.4. Laisser répondre : beaucoup choisissent "$source", et pensent qu'une erreur sera levée.
-->

---

## `"$_id.source"` : le chemin dans le document qui sort

<div class="cols" style="align-items: start;">
<div class="dense">

```js
  { $group: { _id: "$_id.source",
      nb_annees: { $sum: 1 },
      meilleure: { $max: "$moyenne" } } },
  { $sort: { _id: 1 } }
// [ { _id: 'presse', nb_annees: 3, meilleure: 5 },
//   { _id: 'public', nb_annees: 2, meilleure: 4 } ]
```

</div>
<div class="dense">

```js
  { $group: { _id: "$source", … } }
// [ { _id: null, nb_annees: 5, meilleure: 5 } ]
```

<p class="petit"><code>"&#36;source"</code> n'existe plus après le premier <code>&#36;group</code> : il vaut « absent » pour tous, d'où <b>un seul</b> groupe, et aucune erreur.</p>

</div>
</div>

<img src="assets/schemas/s3-champs-documents.svg" alt="Deux questions à se poser à chaque étape. À gauche, quels champs restent : le film Chihiro, avec ses 6 champs, passe dans $project, qui ne garde que les champs cités (titre et nb_notes), ou dans $addFields, qui garde les 6 champs et ajoute nb_notes. À droite, combien de documents restent : les 4 films passent dans $group par année, qui rend 3 documents, un par année, ou dans $setWindowFields partitionné par année, qui rend les 4 films, chacun avec un champ calculé sur son année." style="display:block; width:100%; margin:0.5rem auto 0;">

<!--
(1 min 5)

Les deux sorties ont été obtenues sur MongoDB 9.0.4, avec le pipeline de la diapo précédente sans son $sort, suivi de ce second $group puis de { $sort: { _id: 1 } }. Avec "$_id.source" : la presse a noté 3 années de sortie, meilleure moyenne 5 ; le public 2, meilleure moyenne 4. Avec "$source" : un seul groupe, _id: null, qui mélange les 5 documents, sans erreur ni avertissement.

Le schéma résume la partie : deux questions à se poser avant chaque étape, quels champs entrent (à gauche : $project ou $addFields), combien de documents (à droite : $group ou $setWindowFields). Un $group renomme tout : sa clé devient _id.

Un _id composé sert aussi à l'exercice 5 (le TIP de l'énoncé le décrit en mots) : ne pas en dire plus.
-->

---

## La tendance du mois : `$dateTrunc`, puis une fenêtre

<div class="cols" style="align-items: start;">
<div class="dense">

**Un groupe par mois**

```js
db.films.aggregate([
  { $unwind: "$notes" },
  { $group: { _id: { $dateTrunc:
      { date: "$notes.date", unit: "month" } },
      nb: { $sum: 1 } } },
  { $sort: { _id: 1 } }
])
// { _id: ISODate('2026-01-01T00:00:00.000Z'), nb: 2 }
// { _id: ISODate('2026-02-01T00:00:00.000Z'), nb: 1 }
// { _id: ISODate('2026-03-01T00:00:00.000Z'), nb: 1 }
// { _id: ISODate('2026-04-01T00:00:00.000Z'), nb: 1 }
```

</div>
<div class="dense">

**Une fenêtre : la durée cumulée**

```js
db.films.aggregate([
  { $setWindowFields: {
      sortBy: { annee: 1, titre: 1 },
      output: { duree_cumulee: { $sum: "$duree",
        window: { documents:
                  ["unbounded", "current"] } } } } },
  { $project: { _id: 0, titre: 1, duree_cumulee: 1 } }
])
// { titre: 'La Haine', duree_cumulee: 98 }
// { titre: 'Les Glaneurs et la Glaneuse',
//   duree_cumulee: 180 }
// { titre: 'Amélie Poulain', duree_cumulee: 302 }
// { titre: 'Le Voyage de Chihiro', duree_cumulee: 427 }
```

</div>
</div>

<div class="g2" style="margin-top: 0.3rem; align-items: stretch;">
<div class="box">

`$dateTrunc` ramène une date au **1<sup>er</sup> de son mois** : 14/01 et 28/01 donnent 01/01. Sur la date exacte : 5 groupes d'une note.

</div>
<div class="box">

`window` : `["unbounded", "current"]`, du premier au courant, fait un **cumul** ; `[-2, 0]`, le courant et les deux précédents.

</div>
</div>

<!--
(1 min 10)

Le besoin : combien de notes chaque mois ? Un $group sur la date exacte donne un groupe par jour (5 groupes d'une note, vérifié sur MongoDB 9.0.4) ; $dateTrunc calcule, pour chaque note, le premier jour de son mois (unit: "month" ; aussi "week", "year"...), et devient la clé du $group : un groupe par mois. Résultat obtenu sur MongoDB 9.0.4.

À droite, une fenêtre porte sur des documents voisins, dans l'ordre de sortBy, par rapport au document courant : c'est l'exemple de l'énoncé, ici sur les films par année. Résultat obtenu sur MongoDB 9.0.4 (la projection garde aussi annee et duree dans l'énoncé : { titre: 'La Haine', annee: 1995, duree: 98, duree_cumulee: 98 }...). Sans window, $sum porte sur toute la partition : 427 pour chaque film. documents: [-2, 0] figure dans l'énoncé ; en début de série, la fenêtre contient moins de documents. Le schéma du cumul est en annexe.

L'exercice 6 a besoin de $dateTrunc et d'une fenêtre, sur une autre question : ne pas en dire plus, et ne pas assembler les deux briques devant la salle.
-->

---

<!-- header: Partie 3 · joindre et résumer -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 3 - 🔗 Joindre, classer, résumer

De quel pays sont les réalisateurs ? Combien de films courts, moyens, longs ? Et tout le tableau de bord en une requête ?

<!--
(10 s)

Même titre que la partie 3 de l'énoncé (ex. 7 à 9) : les briques d'un tableau de bord.
-->

---

## Le pays du réalisateur est ailleurs : `$lookup`

<img src="assets/schemas/s3-lookup.svg" alt="Mécanisme de $lookup: { from: &quot;realisateurs&quot;, localField: &quot;realisateur&quot;, foreignField: &quot;nom&quot;, as: &quot;r&quot; }, sur deux films. 1, la valeur du champ realisateur du film est comparée au champ nom de chaque document de realisateurs ; 2, les documents égaux sont rangés dans le tableau r, ajouté au film. Le Voyage de Chihiro, &quot;Miyazaki&quot; : r contient { nom: &quot;Miyazaki&quot;, pays: &quot;Japon&quot; }. La Haine, &quot;Kassovitz&quot; : aucun nom égal, r est vide. r reçoit 0, 1 ou plusieurs documents, toujours dans un tableau." style="display:block; width:100%; margin:0.1rem auto 0;">

<p class="petit" style="margin-top: 0.4rem;">Critère de S2 : « données modifiées souvent, indépendamment du document parent » → <b>référencer</b>. Le réalisateur vit à part du film ; <code>&#36;lookup</code> le recolle au moment de la requête. En SQL : <code>LEFT OUTER JOIN</code>.</p>

<!--
(50 s)

Une ligne de rappel suffit : la ligne citée est celle du tableau des critères de l'énoncé du TP1 (« Modéliser la médiathèque »), repris en S2 ; le TP3 y revient. Le pays d'un réalisateur est écrit une fois, dans realisateurs : $lookup va le chercher.

Dérouler le schéma en suivant les numéros : la valeur de localField (realisateur), la comparaison avec foreignField (nom) de chaque document de from, le tableau as. MongoDB ne vérifie pas la « clé étrangère » : Kassovitz n'a pas de document dans realisateurs.

Dans le TP, la population de chaque borough est rangée à part, dans boroughs (exercice 7).
-->

---

## Ce que rend `$lookup` : toujours un tableau

<div class="dense">

```js
db.films.aggregate([
  { $lookup: { from: "realisateurs", localField: "realisateur", foreignField: "nom", as: "r" } },
  { $project: { _id: 0, titre: 1, "r.nom": 1, "r.pays": 1 } },
  { $sort: { titre: 1 } }
])
// { titre: 'Amélie Poulain', r: [ { nom: 'Jeunet', pays: 'France' } ] }
// { titre: 'La Haine', r: [] }
// { titre: 'Le Voyage de Chihiro', r: [ { nom: 'Miyazaki', pays: 'Japon' } ] }
// { titre: 'Les Glaneurs et la Glaneuse', r: [ { nom: 'Varda', pays: 'France' } ] }
```

</div>

<div class="warn" style="font-size: 0.8em;">

`"$r.pays"` est donc un **tableau** (`["France"]`), pas une valeur : `$concat` avec `"$r.pays"` échoue (« `$concat supports only strings` »), un calcul aussi.

</div>

<div class="box" style="font-size: 0.8em;">

❓ **À vous de prédire** : on ajoute `{ $unwind: "$r" }` après le `$lookup`. Combien de films en sortent ?

</div>

<!--
(45 s)

Même avec un seul document trouvé, r est un tableau : $lookup ne sait pas d'avance combien il en trouvera (deux réalisateurs du même nom donneraient deux documents). Chaque document trouvé garde son _id, que la projection masque ici.

Vérifié sur MongoDB 9.0.4 : le résultat affiché ; { $concat: ["$titre", " (", "$r.pays", ")"] } fait échouer l'agrégation avec « $concat supports only strings ».

Prédiction de la partie 3 : laisser répondre. Réponse fréquente : 4.
-->

---

## `$unwind` : du tableau à la valeur

<style scoped>
table { display: table; width: 100%; font-size: 0.72em; }
</style>

<div class="cols" style="grid-template-columns: 1fr 1fr; align-items: start;">
<div class="dense">

```js
db.films.aggregate([
  { $lookup: { from: "realisateurs",
      localField: "realisateur",
      foreignField: "nom", as: "r" } },
  { $unwind: "$r" },
  { $project: { _id: 0, titre: 1,
                pays: "$r.pays" } },
  { $sort: { titre: 1 } }
])
// { titre: 'Amélie Poulain', pays: 'France' }
// { titre: 'Le Voyage de Chihiro', pays: 'Japon' }
// { titre: 'Les Glaneurs et la Glaneuse',
//   pays: 'France' }
```

</div>
<div>

| Film | `r` | après `$unwind` |
|---|---|---|
| Amélie | Jeunet | gardé |
| La Haine | `[]` | **retiré** |
| Chihiro | Miyazaki | gardé |
| Glaneurs | Varda | gardé |

<p class="petit"><b>3 films</b> : comme un <code>INNER JOIN</code>. Avec <code>preserveNullAndEmptyArrays: true</code>, La Haine revient, sans <code>pays</code>.</p>

</div>
</div>

<div class="warn" style="font-size: 0.8em;">

`$lookup` cherche dans `from` **pour chaque document** qui lui arrive. S'il suffit d'une valeur par groupe, **regrouper d'abord**, joindre ensuite : 6 recherches au lieu de 25 359.

</div>

<!--
(45 s)

Réponse à la prédiction : 3. Le $unwind du TP1 : un document par élément du tableau. Ici r contient au plus un document, donc $unwind « sort » la valeur du tableau ; un tableau vide ne donne rien, d'où la disparition de La Haine.

Vérifié sur MongoDB 9.0.4 : le résultat affiché ; avec { $unwind: { path: "$r", preserveNullAndEmptyArrays: true } }, La Haine revient sans champ pays (LEFT OUTER JOIN).

Le dernier encadré est le TIP de l'exercice 7, en mots : compter d'abord (5 boroughs, plus « Missing »), joindre ensuite. Le borough « Missing » n'a pas de correspondance dans boroughs : il disparaît au $unwind, comme La Haine.
-->

---

## Compter par tranches, avec ce qu'on sait

<div class="cols" style="grid-template-columns: 0.9fr 1.1fr; align-items: start;">
<div class="dense">

**Un `$group` sur la durée**

```js
db.films.aggregate([
  { $group: { _id: "$duree",
              nb: { $sum: 1 } } },
  { $sort: { _id: 1 } } ])
// { _id: 82, nb: 1 }, { _id: 98, nb: 1 },
// { _id: 122, nb: 1 }, { _id: 125, nb: 1 }
```

</div>
<div class="dense">

**Un compteur par tranche : `$sum` et `$cond`**

```js
db.films.aggregate([
  { $group: { _id: null,
      courts: { $sum: { $cond:
        [{ $lt: ["$duree", 90] }, 1, 0] } },
      longs:  { $sum: { $cond:
        [{ $gte: ["$duree", 120] }, 1, 0] } } } } ])
// [ { _id: null, courts: 1, longs: 2 } ]
```

</div>
</div>

<div class="g2" style="margin-top: 0.4rem; align-items: stretch;">
<div class="warn">

Une valeur **continue** : un groupe par durée exacte, quatre groupes d'un film.

</div>
<div class="box">

`$cond` vaut 1 ou 0 : le `SUM(CASE WHEN … THEN 1 ELSE 0 END)` de SQL. Mais **une expression par tranche** : il faut un histogramme.

</div>
</div>

<!--
(45 s)

Le besoin : combien de films courts (moins de 90 min), moyens, longs (120 min et plus) ? Deux tentatives avec ce qu'on sait. À gauche, $group sur la durée exacte : un groupe par valeur. À droite, le comptage conditionnel : $cond: [condition, si vrai, si faux] vaut 1 ou 0 pour chaque film, et $sum additionne. Ça marche, mais il faut une expression par tranche, et la tranche « moyens » est déjà oubliée. Résultats obtenus sur MongoDB 9.0.4.

$sum + $cond reste utile pour compter sous condition dans un groupe (bonus 4 du TP2, projet).
-->

---

## `$bucket` : une tranche par plage de valeurs

<img src="assets/schemas/s3-bucket.svg" alt="Mécanisme de $bucket: { groupBy: &quot;$duree&quot;, boundaries: [0, 90, 120], default: &quot;long&quot;, output: { nb: { $sum: 1 } } }. Les bornes découpent l'axe des durées en deux tranches, de 0 inclus à 90 exclu et de 90 inclus à 120 exclu ; default reçoit le reste. Les Glaneurs, 82 minutes, tombent dans la tranche de 0 à 90 ; La Haine, 98, dans celle de 90 à 120 ; Amélie, 122, et Chihiro, 125, dans default. En sortie, un document par tranche : { _id: 0, nb: 1 }, { _id: 90, nb: 1 }, { _id: &quot;long&quot;, nb: 2 } ; l'_id est la borne basse, ou la valeur de default." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="dense">

```js
db.films.aggregate([ { $bucket: { groupBy: "$duree", boundaries: [0, 90, 120],
                                  default: "long", output: { nb: { $sum: 1 } } } } ])
// { _id: 0, nb: 1 }, { _id: 90, nb: 1 }, { _id: 'long', nb: 2 }
```

</div>

<p class="petit">Borne <b>basse incluse</b>, borne <b>haute exclue</b> : « de 90 à 119 min » s'écrit avec 90 et 120. <code>groupBy</code> accepte une expression. Les autres règles : en annexe.</p>

<!--
(1 min)

Lire le schéma de haut en bas : les bornes découpent l'axe, chaque film tombe dans une tranche, chaque tranche donne un document. Les bornes et la valeur de default, en ambre, sont écrites dans la requête ; elles deviennent les _id. En SQL, il faudrait un GROUP BY sur un CASE WHEN.

Résultat réel sur MongoDB 9.0.4 : { _id: 0, nb: 1 }, { _id: 90, nb: 1 }, { _id: 'long', nb: 2 }. Sur une collection d'essai, un film de 90 min va dans la tranche 90, un film de 120 min dans default.

Règles en annexe : une tranche vide n'apparaît pas ; sans default, un document hors bornes fait échouer la requête ; sans output, un seul champ count ; groupBy accepte une expression. Prépare l'exercice 8, sans en donner les bornes.
-->

---

## Plusieurs résumés en une requête : `$facet`, filtré d'abord

<p class="petit" style="margin-bottom: 0.2rem;">Par année <b>et</b> le plus long : deux requêtes feraient deux allers-retours. <code>&#36;facet</code> rend <b>un seul document</b>, un tableau par facette ; le filtre commun se fait <b>avant</b>, une fois.</p>

<img src="assets/schemas/s3-facet.svg" alt="Mécanisme de $facet sur les 4 films. Le $facet donne une copie des 4 films à chacune de ses deux facettes. par_annee applique $group par année puis $sort ; plus_long applique $sort par durée décroissante, $limit 1, puis $project du titre. En sortie, un seul document, un champ par facette, chacun un tableau : par_annee vaut [ { _id: 1995, nb: 1 }, { _id: 2000, nb: 1 }, { _id: 2001, nb: 2 } ] et plus_long vaut [ { titre: 'Le Voyage de Chihiro' } ]." style="display:block; width:100%; margin:0 auto;">

<div class="dense">

```js
db.films.aggregate([ { $match: { annee: { $gte: 2000 } } },          // une fois, avant les facettes
  { $facet: {
      par_annee: [ { $group: { _id: "$annee", nb: { $sum: 1 } } }, { $sort: { _id: 1 } } ],
      plus_long: [ { $sort: { duree: -1 } }, { $limit: 1 },
                   { $project: { _id: 0, titre: 1, duree: 1 } } ] } } ])
// { par_annee: [ { _id: 2000, nb: 1 }, { _id: 2001, nb: 2 } ],
//   plus_long: [ { titre: 'Le Voyage de Chihiro', duree: 125 } ] }
```

</div>

<!--
(1 min 10)

Le besoin d'abord : un écran d'accueil affiche plusieurs chiffres calculés sur les mêmes données. $facet lance plusieurs sous-pipelines sur les mêmes documents et rend un seul document : un champ par facette, chacun un tableau.

Le schéma montre le $facet seul, sur les 4 films (exemple de l'énoncé : par_annee 1995, 2000, 2001 ; plus_long Chihiro). Chaque facette reçoit sa copie des documents : le $sort et le $limit de plus_long n'enlèvent rien à par_annee.

Le code ajoute un $match commun avant : La Haine (1995) est retirée une seule fois, puis chaque facette travaille sur les 3 mêmes films ; les Glaneurs comptent en 2000, Amélie et Chihiro en 2001 ; plus_long garde Chihiro (125 min). Résultat obtenu sur MongoDB 9.0.4.

Un $match placé dans chaque facette filtrerait tous les films dans chaque facette, sans index. Vérifié sur 9.0.4 : avec un index { annee: 1 }, explain() montre un IXSCAN pour le $match placé avant $facet, et un COLLSCAN (les 4 films examinés) pour le même $match placé dans une facette ; avec un $match qui ne garde aucun film, le résultat est { par_annee: [], plus_long: [] }. Lire ce document dans une étape suivante, ou en Java : annexe.

Lien avec l'exercice 9, le tableau de bord de Brooklyn : un filtre commun avant $facet (l'énoncé le dit dans son TIP).
-->

---

<!-- header: Partie 4 · indexer -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 4 - ⚡ Index

Le tableau de bord rame : comment savoir ce qu'une requête **lit**, et lui éviter de tout lire ?

<!--
(10 s)

Même titre que la partie 4 de l'énoncé (ex. 10 à 12) : explain() et règle ESR. Deuxième morceau de la question directrice : répondre vite.
-->

---

## Mesurer d'abord : `explain("executionStats")`

<img src="assets/schemas/s3-explain.svg" alt="Extraits de db.restaurants.find({ borough: &quot;Bronx&quot; }).explain(&quot;executionStats&quot;). Sans index, winningPlan n'a qu'une étape, COLLSCAN ; nReturned 2338, totalKeysExamined 0, totalDocsExamined 25359 : 23 021 documents lus pour rien. Avec l'index { borough: 1 }, winningPlan a pour étape FETCH, dont l'entrée (inputStage) est IXSCAN sur l'index borough_1, exécutée en premier ; nReturned 2338, totalKeysExamined 2338, totalDocsExamined 2338 : aucun document lu pour rien." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="dense">

```js
db.restaurants.find({ borough: "Bronx" }).explain("executionStats")   // sans index : à gauche
db.restaurants.createIndex({ borough: 1 })
db.restaurants.find({ borough: "Bronx" }).explain("executionStats")   // avec l'index : à droite
```

</div>

<div class="g2" style="align-items: stretch;">
<div class="box">

Un **index** : les valeurs du champ, **triées**, chacune avec l'adresse de son document. `IXSCAN` parcourt l'index, `FETCH` lit les documents pointés.

</div>
<div class="warn">

Un index coûte de la place et du travail à chaque écriture. Il **reste** d'un exercice à l'autre : `getIndexes()`, `dropIndexes()`.

</div>
</div>

<!--
(1 min 5)

Ici les vraies données, comme dans l'énoncé (Exemple C du playground) : sur 4 films, rien ne se voit ; sur 25 359 restaurants, si. Chiffres obtenus sur MongoDB 9.0.4, base tp2 : sans index, COLLSCAN, nReturned 2338, totalKeysExamined 0, totalDocsExamined 25359 ; avec { borough: 1 }, FETCH ← IXSCAN (index borough_1), 2338 partout. Plus de 90 % du travail était perdu sans index.

"executionStats" exécute la requête et compte ; explain() seul ne donne que le plan (vérifié : pas de champ executionStats). Lire le plan de l'intérieur vers l'extérieur : l'étape la plus imbriquée (inputStage) s'exécute en premier. executionTimeMillis varie d'une exécution à l'autre ; les compteurs, non.

Le mécanisme, dessiné sur les films (COLLSCAN contre IXSCAN puis FETCH), est en annexe. createIndex({ borough: 1 }) correspond à CREATE INDEX en SQL. Exemple D du playground : getIndexes() et dropIndexes() ; un index de l'exercice 10 changerait le plan de l'exercice 11. Le correcteur automatique part toujours d'une base sans index. L'exercice 10 demande l'un de ces compteurs (executionStats.totalDocsExamined).
-->

---

## ❓ Une condition que l'index ne connaît pas

```js
db.films.createIndex({ annee: 1 })
db.films.find({ annee: 2001, realisateur: "Jeunet" })
  .explain("executionStats").executionStats
// nReturned: 1, totalKeysExamined: ?, totalDocsExamined: ?
```

<div class="box" style="font-size: 0.82em; margin-top: 0.8rem;">

❓ **À vous de prédire** : combien de clés lues, combien de documents lus ? Un seul film est renvoyé.

</div>

<!--
(20 s)

Prédiction de la partie 4. Laisser répondre. Réponse fréquente : 1 et 1, « puisqu'un seul film est renvoyé ».
-->

---

## Une condition hors de l'index : des documents lus pour rien

<style scoped>
table { display: table; width: 100%; font-size: 0.72em; }
</style>

| Film | Clé `annee` | `IXSCAN` | document lu, puis test de `realisateur` |
|---|---|---|---|
| La Haine | 1995 | sautée | jamais lu |
| Les Glaneurs et la Glaneuse | 2000 | sautée | jamais lu |
| Le Voyage de Chihiro | 2001 | lue | Miyazaki : **lu pour rien** |
| Amélie Poulain | 2001 | lue | Jeunet : renvoyé |

<p class="centre"><code>nReturned: 1, totalKeysExamined: 2, totalDocsExamined: 2</code></p>

<div class="box">

L'index ne connaît que l'année : `realisateur` se vérifie **après** la lecture (`FETCH`). Le remède : un **index composé**, `{ annee: 1, realisateur: 1 }` : 1 clé, 1 document, 1 renvoyé. À l'exercice 10, gardez l'index demandé : c'est ce coût qu'on mesure.

</div>

<!--
(50 s)

Réponse à la prédiction : 2 et 2. Vérifié sur MongoDB 9.0.4 : avec { annee: 1 }, plan FETCH ← IXSCAN ; dans l'explain, le filtre { realisateur: { $eq: 'Jeunet' } } est attaché à l'étape FETCH, pas à l'IXSCAN. Avec { annee: 1, realisateur: 1 } : 1 clé, 1 document, 1 renvoyé.

La règle : totalDocsExamined compte les documents pointés par les clés lues, pas les documents renvoyés. Toute condition absente de l'index se vérifie après lecture.

C'est la question posée par l'exercice 10 : pourquoi le nombre de documents examinés n'est pas le nombre de pizzerias du Queens. Ne pas donner le nombre.
-->

---

## Index composé : l'ordre des champs compte

<img src="assets/schemas/s3-esr.svg" alt="L'index composé { annee: 1, titre: 1 } range ses clés par annee, puis par titre à annee égale : (1995, La Haine), (2000, Les Glaneurs et la Glaneuse), (2001, Amélie Poulain), (2001, Le Voyage de Chihiro). À gauche, une égalité, find({ annee: 2001 }).sort({ titre: 1 }) : les clés 2001 forment un seul bloc, déjà trié par titre ; plan FETCH ← IXSCAN, pas de tri. À droite, un intervalle, find({ annee: { $gte: 2000 } }).sort({ titre: 1 }) : deux blocs, 2000 puis 2001, chacun trié à part ; l'ordre de lecture n'est pas l'ordre des titres ; plan FETCH ← SORT ← IXSCAN, un tri en mémoire." style="display:block; width:100%; margin:0.1rem auto 0;">

<p class="petit" style="margin-top: 0.4rem;">Les clés sont rangées par le 1<sup>er</sup> champ, puis par le 2<sup>e</sup> à valeur égale : comme un annuaire, par ville puis par nom. Après une <b>égalité</b>, le champ suivant est déjà trié ; après un <b>intervalle</b>, non : <code>SORT</code>, un tri en mémoire.</p>

<!--
(50 s)

Analogie de l'annuaire : les Martin de Marseille sont consécutifs, et déjà rangés par prénom. Mais « toutes les villes de A à M, triées par nom » : chaque ville est rangée à part, il faut tout retrier.

Plans obtenus sur MongoDB 9.0.4, avec les 4 films et le seul index { annee: 1, titre: 1 } : égalité, FETCH ← IXSCAN (2 clés) ; intervalle, FETCH ← SORT ← IXSCAN (3 clés). Mettre titre en premier, { titre: 1, annee: 1 }, supprimerait le SORT mais ferait parcourir toutes les clés : c'est ce compromis que règle la diapo suivante.
-->

---

## La règle ESR : égalité, puis tri (*Sort*), puis intervalle (*Range*)

<style scoped>
table { display: table; width: 100%; font-size: 0.7em; }
td:nth-child(1) code, td:nth-child(3) code { white-space: nowrap; }
td code { font-size: 0.95em; }
</style>

<p class="centre"><code>db.films.find({ annee: 2001, duree: { &#36;gt: 100 } }).sort({ titre: 1 })</code><br><span class="petit"><b style="color: var(--bleu-fonce)">E</b> : <code>annee</code> · <b style="color: var(--vert-mongo)">S</b> : <code>titre</code> · <b style="color: var(--orange-fonce)">R</b> : <code>duree</code></span></p>

| Index essayé | Ordre | Plan obtenu | Clés lues | Pourquoi |
|---|---|---|---|---|
| `{ annee: 1, duree: 1 }` | E R | `SORT ← FETCH ← IXSCAN` | 2 | tri en mémoire |
| `{ annee: 1, duree: 1, titre: 1 }` | E R S | `FETCH ← SORT ← IXSCAN` | 2 | tri en mémoire |
| `{ titre: 1, annee: 1, duree: 1 }` | S E R | `FETCH ← IXSCAN` | **4** | toutes les clés |
| `{ annee: 1, titre: 1, duree: 1 }` | **E S R** | `FETCH ← IXSCAN` | 2 | bloc déjà trié |

<div class="warn" style="margin-top: 0.6rem; font-size: 0.8em;">

**`SORT`** charge tous les résultats avant de renvoyer le premier : lent, et limité à 100 Mo en mémoire.

</div>

<!--
(1 min)

La même requête que l'énoncé (partie 4). Chaque ligne : la collection films avec ce seul index, exécutée sur MongoDB 9.0.4 ; plans et compteurs recopiés de explain("executionStats"), 2 documents lus et 2 renvoyés à chaque fois.

- Égalité d'abord : annee = 2001 désigne un seul bloc de clés (2 lues au lieu de 4).
- Tri ensuite : dans ce bloc, les clés sont déjà rangées par titre, pas de SORT.
- Intervalle à la fin : les bornes de l'IXSCAN incluent duree (100, inf] ; avec { annee: 1, titre: 1 } sans duree, le plan est le même (FETCH ← IXSCAN, 2 clés), mais la condition sur duree devient un filtre de FETCH : un film de 2001 trop court serait lu pour rien.
- Ligne 2 : après l'intervalle sur duree, titre n'est plus trié.

memLimit vaut 104857600 octets dans l'étape SORT ; au-delà, le tri passe par le disque. L'exercice 11 applique la règle aux restaurants : ne pas donner l'index.
-->

---

## Encore 2 documents lus pour 2 renvoyés. Et zéro ?

<img src="assets/schemas/s3-couverte.svg" alt="Avec l'index { annee: 1, titre: 1, duree: 1 }, la requête find({ annee: 2001, duree: { $gt: 100 } }, projection).sort({ titre: 1 }) lit la clé (2001, Amélie Poulain, 122). À gauche, projection { _id: 0, titre: 1, duree: 1 } : titre et duree sont pris dans la clé, le résultat se construit sans document ; plan PROJECTION_COVERED ← IXSCAN, totalDocsExamined 0. À droite, projection { titre: 1, duree: 1 } : _id, projeté par défaut, est absent de la clé ; MongoDB lit le document (FETCH) pour le prendre ; plan PROJECTION_SIMPLE ← FETCH ← IXSCAN, totalDocsExamined 2." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="dense">

```js
db.films.createIndex({ annee: 1, titre: 1, duree: 1 });
const e = db.films.find({ annee: 2001, duree: { $gt: 100 } }, { _id: 0, titre: 1, duree: 1 })
                  .sort({ titre: 1 }).explain("executionStats");
[e.queryPlanner.winningPlan.stage, e.executionStats.totalDocsExamined]   // [ 'PROJECTION_COVERED', 0 ]
```

</div>

<div class="carte vert" style="font-size: 0.7em;">
<b class="t">🤖 Requête couverte : l'index contient tout ce qui est filtré, trié et projeté</b>
<code>_id</code> est projeté par défaut : écrire <code>_id: 0</code>. Exercices 11 et 12 : le correcteur automatique lit aussi le <b>plan</b>. Créez l'index, <b>puis</b> la requête, dans la même réponse. Pas de <code>Ctrl+Alt+R</code>.
</div>

<!--
(1 min 10)

Le besoin, à l'écran : depuis le début de la partie, le meilleur plan lit autant de documents qu'il en renvoie. Peut-on n'en lire aucun ? Oui, si l'index contient tous les champs filtrés, triés et projetés : MongoDB construit le résultat avec les clés. C'est une requête couverte, comme le sommaire d'un livre.

Plans obtenus sur MongoDB 9.0.4 avec le seul index { annee: 1, titre: 1, duree: 1 } : avec { _id: 0, titre: 1, duree: 1 }, PROJECTION_COVERED ← IXSCAN, totalKeysExamined 2, totalDocsExamined 0 ; avec { titre: 1, duree: 1 }, PROJECTION_SIMPLE ← FETCH ← IXSCAN, totalDocsExamined 2. Sans projection du tout, FETCH ← IXSCAN. Le code s'exécute tel quel, points-virgules compris (sans le « ; » après explain, mongosh lit la ligne suivante comme un accès à une propriété) : mongosh affiche [ 'PROJECTION_COVERED', 0 ].

Le correcteur automatique lit le profileur de MongoDB : il voit le plan réellement exécuté. Le bon résultat obtenu sans l'index demandé vaut 0 aux exercices 11 et 12. Exercice 11 : index utilisé, pas de SORT, documents lus = renvoyés. Exercice 12 : index utilisé, pas de SORT, totalDocsExamined à 0. La grille « bon ou mauvais signe » est en annexe. Ctrl+Alt+R exécuterait tout le playground et créerait tous les index d'un coup ; npm run seed remet la base à zéro.
-->

---

<!-- header: Séance 3 · premier temps -->

## À retenir : questions et réponses rapides

<div class="g2" style="font-size: 0.72em; align-items: stretch;">
<div class="carte vert">
<b class="t">Poser les questions</b>

- Comparer deux champs : `$expr` (dans un filtre, `"$b"` est une chaîne).
- `null` trouve aussi l'absent ; `$type` repère le mauvais type.
- `$addFields` ajoute, `$project` choisit ; une fenêtre garde chaque document.
- Après `$group`, le chemin est `"$_id.x"`.

</div>
<div class="carte">
<b class="t">Croiser, résumer, aller vite</b>

- `$lookup` rend un tableau : `$unwind` ensuite ; regrouper avant de joindre.
- `$bucket` : borne basse incluse ; `$facet` : un document, filtré avant.
- Mesurer avec `explain("executionStats")` ; index composé : **E**, **S**, **R**.
- Couverte : `_id: 0`.

</div>
</div>

<div class="bandeau" style="margin-top: 0.8rem; font-size: 0.82em;">

Le tableau de bord : des questions écrites **étape par étape**, et un index **mesuré**, pas deviné.

</div>

<!--
(40 s)

Première moitié de la réponse à la question directrice : quelles questions poser (parties 1 à 3), comment y répondre vite (partie 4). Le troisième morceau, le servir, est l'objet du second temps (partie 6), avec la partie 5 (« où ? »).

Fin du premier temps : enchaîner sur les deux diapos « À vous », puis lancer le travail.
-->

---

<!-- header: "" -->

## À vous : la séance 3

<style scoped>
.g2 > div { display: flex; flex-direction: column; gap: 0.6rem; }
.g2 > div > .orange { margin-top: auto; }
</style>

<div class="bandeau" style="font-size: 1em; padding: 0.45rem 1.2rem;">
<a href="https://iutinfoaix-r510.github.io/tp2/">iutinfoaix-r510.github.io/tp2</a> : accepter le TP2, puis <code>npm run seed</code>
</div>

<div class="g2" style="margin-top: 0.9rem; font-size: 0.78em; grid-template-columns: 1.1fr 1fr; align-items: stretch;">
<div>

1. Mise en place, `./mvnw -q compile` dans <code style="white-space: nowrap">requetes-java/</code> : **15 min**
2. Parties 1 et 2, filtrer et calculer : **50 min**
3. Partie 3, joindre et résumer : **35 min**
4. Partie 4, index : **30 min**
5. Point cours, puis partie 5 : **30 min**
6. **Premier rendu** : `r510-rendre`, **10 min**

<div class="carte orange">
<b class="t">📅 Rendu final du TP2</b>
dimanche 13 décembre 2026, 23&nbsp;h&nbsp;59. Trois rendus au plus.
</div>

</div>
<div>

<div class="carte vert">
<b class="t">Les points</b>
18 exercices à 5 points, dont 4 en Java : 90 points, 8&nbsp;% de la note.
</div>

<div class="carte vert">
<b class="t">En autonomie</b>
Partie 6, Java et Javalin (1 h à 1 h 15). Quatre bonus, hors barème.
</div>

<div class="carte orange">
<b class="t">Base abîmée ?</b>
<code>npm run seed</code> vide la base <code>tp2</code> et recharge les données.
</div>

</div>
</div>

<!--
(50 s)

Fin du premier temps : diapos 1 à 31 en 23 min 40, plus les deux diapos « À vous » (50 s + 30 s), soit 25 min. Second temps (diapos 34 à 44) : 7 min 30.

Trois rendus au plus : fin de séance 3, un rendu intermédiaire facultatif, puis le rendu final au plus tard le dimanche 13 décembre 2026 à 23 h 59. r510-sauver sauvegarde sans noter ; seul r510-rendre déclenche la correction.

Le minutage suppose le premier temps du point cours déjà fait (25 min) : 15 + 50 + 35 + 30 + 30 + 10 = 2 h 50, soit 3 h 15 avec le point cours ; il reste 45 minutes de marge. La partie 6 (exercices 15 à 18) se termine en autonomie ; les diapos 39 à 42 et l'annexe servent de référence. Le bonus 4 ($merge) sera vu au point cours S4.

Lancer ./mvnw -q compile dès la mise en place : le premier lancement télécharge Maven et les dépendances (une à deux minutes).
-->

---

## Nouveau dans ce TP : le tuteur lit votre travail avec vous

<style scoped>
.g3 > .carte { font-size: 0.7em; }
.carte p { margin: 0.3em 0; }
</style>

<div class="g3" style="align-items: stretch;">
<div class="carte vert">
<b class="t">📋 faire-le-point</b>

Lit avec vous la sortie de `npm run check`, et vous laisse choisir la suite.

« Fais le point. »

</div>
<div class="carte">
<b class="t">🔧 deboguer-ma-requete</b>

Un exercice ❌ ou 🟡 : vous exécutez étape par étape, et comparez à ce que vous attendiez.

« Aide-moi à déboguer ma requête de l'exercice 6. »

</div>
<div class="carte violet">
<b class="t">🎤 interroge-moi</b>

Un exercice ✅ : c'est **vous** qui l'expliquez. Le meilleur entraînement aux **questions individuelles**.

« Interroge-moi sur ma requête de l'exercice 7. »

</div>
<div class="carte orange">
<b class="t">⚡ lire-mon-explain</b>

Partie 4 : apprendre à lire le plan que vous collez.

« Aide-moi à lire mon explain(). »

</div>
<div class="carte rouge">
<b class="t">☕ lire-une-erreur-java</b>

Partie 6 : où regarder, et ce que dit le message.

« Aide-moi à lire cette erreur de ./mvnw. »

</div>
<div class="carte">
<b class="t">🧪 Vos essais</b>

Dans `essais.mongodb.js`, sur les films. **Jamais sous un `// Votre réponse :`.**

</div>
</div>

<!--
(30 s)

Les skills propres au TP2, en plus de approfondir-une-notion et quiz-thematique (déjà au TP1). Elles se déclenchent sur une demande en langage naturel ; les invites sont celles de l'énoncé (section « Assistance IA »). Aucune n'écrit la requête ni le code Java d'un exercice ; sur un exercice, l'escalade du tuteur continue (explication, documentation, indice sur un autre exemple).

interroge-moi prépare les questions individuelles de la dernière séance du projet : c'est l'étudiant qui explique sa réponse, étape par étape ; en mode « épreuve blanche », le tuteur demande aussi une modification.

Les quiz de fin de partie restent dans l'énoncé (« Fais-moi un quiz sur… »).
-->

---

<!-- header: Partie 5 · localiser -->

<!-- _class: lead -->
<!-- _header: "" -->

# Reprise : partie 5 - 🗺️ Géospatial

Une question de plus au tableau de bord : **où** ?

<!--
(10 s)

Début du second temps : à projeter quand la majorité du groupe attaque la partie 5. Diapos 34 à 44, 7 min 30. Même titre que la partie 5 de l'énoncé (ex. 13 et 14).
-->

---

## Dans quel quartier ? Décrire un lieu en GeoJSON

<p class="petit" style="margin-bottom: 0.2rem;">Dans quel quartier est ce lieu ? Quels lieux sont dans ce quartier ? Un quartier n'est pas un rectangle : des <code>&#36;gt</code> sur les coordonnées n'y suffisent pas.</p>

<img src="assets/schemas/s3-geojson.svg" alt="Décrire un lieu en GeoJSON, sur les lieux inventés d'Aix-en-Provence. À gauche, une carte : la longitude en abscisse (x), la latitude en ordonnée (y). La zone Centre est un rectangle, de longitude 5.440 à 5.455 et de latitude 43.525 à 43.535, coins numérotés de 1 à 4. La Mairie est dedans, la Gare juste au sud, l'IUT plus au sud. À droite, les documents : dans lieux, { nom: &quot;Mairie&quot;, position: { type: &quot;Point&quot;, coordinates: [5.4474, 43.5297] } }, la longitude d'abord ; dans zones, { nom: &quot;Centre&quot;, contour: { type: &quot;Polygon&quot;, coordinates: [ [ cinq points ] ] } }, le cinquième point répète le premier." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="g2" style="margin-top: 0.4rem; align-items: stretch;">
<div class="box">

Un `type` (`Point`, `Polygon`, `MultiPolygon`) et des `coordinates` en degrés.

</div>
<div class="warn">

**La longitude d'abord**, comme x avant y. Le contour se **referme** : sans le 5<sup>e</sup> point, la requête échoue (*Loop is not closed*).

</div>
</div>

<!--
(1 min)

Le besoin, à l'écran : « dans quel quartier est ce restaurant ? » et « quels restaurants sont dans ce quartier ? ». Pour que MongoDB y réponde, lieux et zones doivent être décrits dans un format qu'il comprend : GeoJSON.

Lire la carte comme un repère : la longitude est l'abscisse (est-ouest), la latitude l'ordonnée (nord-sud). D'où [longitude, latitude], l'inverse de l'habitude « latitude, longitude » des cartes en ligne. Un Polygon est une liste d'anneaux : le premier est le contour, les suivants seraient des trous ; d'où les doubles crochets.

Ce sont les lieux inventés de l'énoncé (collections lieux et zones, script dans la partie 5 du README). Vérifié sur MongoDB 9.0.4 : un Polygon sans le 5e point, passé à $geometry, fait échouer la requête (« Loop is not closed, first vertex does not equal last vertex »).

Dans les vraies données : neighborhoods.geometry est un Polygon (168 quartiers) ou un MultiPolygon (27) ; address.coord des restaurants est un couple [longitude, latitude] seul, que MongoDB accepte comme un point.
-->

---

## Deux opérateurs, deux questions inverses

<img src="assets/schemas/s3-geo.svg" alt="Deux opérateurs, deux questions inverses. À gauche, $geoWithin répond à « quels points sont dans la zone ? » : { position: { $geoWithin: { $geometry: centre } } } sur la collection lieux ; la zone est donnée dans la requête, la position est lue dans chaque document. La Mairie est dedans, retenue ; la Gare et l'IUT sont dehors. À droite, $geoIntersects répond à « quelles zones touchent le point ? » : { contour: { $geoIntersects: { $geometry: point } } } sur la collection zones ; le point est donné dans la requête, le contour est lu dans chaque document. Point de la Mairie : [ { nom: 'Centre' } ] ; point de la Gare : []." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="box" style="font-size: 0.8em; margin-top: 0.4rem;">

❓ **À vous de prédire** : la Mairie écrite `[43.5297, 5.4474]` dans `$geoIntersects`. Erreur, `[]`, ou `Centre` ?

</div>

<!--
(50 s)

Lire le schéma par ses couleurs, comme pour $expr : en bleu, le champ filtré, lu dans chaque document ; en ambre, la forme écrite dans la requête ($geometry). Les rôles s'inversent : à gauche les points sont dans les documents et la zone dans la requête ; à droite, c'est l'inverse. $geoWithin garde les documents entièrement dans la forme ; $geoIntersects, ceux qui ont au moins un point commun avec elle. Un point n'a pas d'intérieur : $geoWithin le refuse dans $geometry (« $within not supported with provided geometry », vérifié sur 9.0.4).

En SQL avec PostGIS : ST_Within et ST_Intersects.

Prédiction de la partie 5 : laisser répondre. Beaucoup attendent une erreur.

Exercice 14 : des points dans une zone. Exercice 13 : la zone d'un point.
-->

---

## Pas à pas : la forme vient d'un document

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
</style>

<div class="dense">

```js
const centre = db.zones.findOne({ nom: "Centre" }).contour       // une zone, lue dans zones
db.lieux.find({ position: { $geoWithin: { $geometry: centre } } }, { _id: 0, nom: 1 })
// [ { nom: 'Mairie' } ]
const gare = db.lieux.findOne({ nom: "Gare" }).position          // un point, lu dans lieux
db.zones.find({ contour: { $geoIntersects: { $geometry: gare } } }, { _id: 0, nom: 1 })
// []
```

</div>

| Si l'on écrit… | MongoDB répond |
|---|---|
| `coordinates: [43.5297, 5.4474]`, la Mairie inversée | `[]`, **sans erreur** : un point en Éthiopie |
| `coordinates: [5.4474, 143.5297]` | *Longitude/latitude is out of bounds* |
| `$geometry: db.zones.findOne(…)`, sans `.contour` | *unknown GeoJSON type* |

<!--
(1 min)

findOne renvoie le document entier : la forme est un de ses champs (.contour, .position). On la range dans une variable, puis on s'en sert dans le filtre : le playground accepte plusieurs instructions, c'est la dernière qui affiche le résultat. Résultats obtenus sur MongoDB 9.0.4.

Réponse à la prédiction : [], sans erreur ; le point existe, ailleurs sur la Terre. Un résultat vide sans message doit faire vérifier l'ordre des coordonnées. Les trois lignes du tableau ont été obtenues sur MongoDB 9.0.4 (messages : « Longitude/latitude is out of bounds, lng: 5.4474 lat: 143.53 » ; « unknown GeoJSON type (type field missing or not a string) »).

$geoWithin et $geoIntersects fonctionnent sans index ; un index 2dsphere les accélère et devient obligatoire pour $nearSphere (bonus 1).
-->

---

<!-- header: Partie 6 · coder -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 6 - ☕ Du shell au code

Comment **servir** le tableau de bord : une URL, une requête Java, une réponse JSON ?

<!--
(10 s)

Même titre que la partie 6 de l'énoncé (ex. 15 à 18), faite en autonomie. Troisième morceau de la question directrice : le servir. Les exemples portent sur les films ; ces routes et ces méthodes, écrites pour le cours, ne sont pas dans requetes-java/.
-->

---

## Du navigateur à la base, et retour

<img src="assets/schemas/s3-api-aller-retour.svg" alt="L'aller-retour d'une requête dans le projet, sur les films, en six messages entre quatre acteurs : le navigateur, Javalin, Java avec le pilote MongoDB, et MongoDB. Aller : 1, le navigateur demande GET /api/annees/2001/films ; 2, la route Javalin appelle la méthode Java filmsDeLAnnee(2001) ; 3, le pilote envoie à MongoDB la requête find({ annee: 2001 }). Retour : 4, MongoDB renvoie 2 documents, Amélie et Chihiro ; 5, la méthode rend une List de Document de 2 éléments ; 6, Javalin répond avec le statut 200 et un corps JSON." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="g2" style="margin-top: 0.4rem; align-items: stretch;">
<div class="box">

**Javalin** associe une URL à une méthode Java. Le front du projet ne parle jamais à MongoDB : il demande une URL à une **API REST**.

</div>
<div class="box">

Le **pilote** MongoDB envoie depuis Java les requêtes du playground : c'est le JDBC de MongoDB.

</div>
</div>

<!--
(45 s)

Dérouler les six messages : trois à l'aller (traits pleins), trois au retour (pointillés). Suivre la valeur 2001 : elle arrive dans l'URL, devient l'argument de la méthode, puis la valeur du filtre.

Vérifié sur MongoDB 9.0.4, avec mongodb-driver-sync 5.14.0 et Javalin 7.2.4 (les versions de requetes-java/pom.xml) : la route config.routes.get("/api/annees/{annee}/films", ctx -> ctx.json(requetes.filmsDeLAnnee(Integer.parseInt(ctx.pathParam("annee"))))) renvoie exactement le JSON affiché.

Dans le TP : 3 méthodes à écrire dans RequetesRestaurants.java (exercices 15 à 17) et 1 route dans ApiRestaurants.java (exercice 18), vérifiées par le correcteur automatique (npm run check). Le projet part d'un squelette Java, Javalin et MongoDB : cette partie en est la première prise en main.
-->

---

## Du shell au pilote : une méthode, un appel par étape

<div class="cols" style="align-items: start;">
<div class="dense">

<p class="etiquette">find</p>

```java
public List<Document> filmsDeLAnnee(int annee) {
    return films     // MongoCollection<Document>
        .find(Filters.eq("annee", annee))
        .projection(Projections.fields(
            Projections.excludeId(),
            Projections.include("titre", "duree")))
        .sort(Sorts.ascending("titre"))
        .into(new ArrayList<>());
}
// filmsDeLAnnee(2001) renvoie :
// [Document{{titre=Amélie Poulain, duree=122}},
//  Document{{titre=Le Voyage de Chihiro, duree=125}}]
```

</div>
<div class="dense">

<p class="etiquette">aggregate</p>

```java
films.aggregate(List.of(
    Aggregates.match(Filters.gte("annee", 2000)),
    Aggregates.group("$annee",
        Accumulators.avg("duree_moy", "$duree")),
    Aggregates.sort(Sorts.ascending("_id"))
)).into(new ArrayList<>());
// [Document{{_id=2000, duree_moy=82.0}},
//  Document{{_id=2001, duree_moy=123.5}}]
```

</div>
</div>

<div class="g2" style="margin-top: 0.3rem; align-items: stretch;">
<div class="warn">

**`find(…)` ne lance rien** : `into(…)` envoie. Le compilateur ne vérifie ni les noms de champs ni les types : `Filters.eq("annee", "2001")` ne trouve **rien**.

</div>
<div class="warn">

**Le `$` compte**, comme en mongosh : `"annee"` **nomme** un champ ; `"$annee"` **lit** sa valeur. Oublié : `group("annee", …)` rend un seul groupe.

</div>
</div>

<!--
(1 min 15)

Une méthode statique par opérateur : Filters.eq, Projections.include, Sorts.ascending, Aggregates.match... fabrique le document que vous écririez en mongosh (schéma et tableau des correspondances en annexe). Le tableau [ … ] d'un pipeline devient List.of(…), chaque étape { $match: … } un appel Aggregates.match(…). Un org.bson.Document est une Map.

Exécuté sur MongoDB 9.0.4 avec le pilote 5.14.0 : filmsDeLAnnee(2001) renvoie la liste affichée ; getString("titre") sur le premier donne "Amélie Poulain". Le pipeline Java donne les mêmes documents que { $match: { annee: { $gte: 2000 } } }, { $group: { _id: "$annee", duree_moy: { $avg: "$duree" } } }, { $sort: { _id: 1 } } en mongosh ; mongosh affiche 82, Java 82.0 (un double dans les deux cas). find(...) renvoie un FindIterable : rien n'est lu tant qu'on ne le parcourt pas (into, une boucle for). Filters.eq("annee", "2001") renvoie une liste vide : la chaîne "2001" n'est pas le nombre 2001 (partie 1).

Vérifié avec le pilote 5.14.0 : Aggregates.group("annee", Accumulators.avg("duree_moy", "$duree")) renvoie un seul document, { _id: "annee", duree_moy: 106.75 }, sans erreur ; Accumulators.avg("duree_moy", "duree") donne duree_moy null pour chaque année.

Méthode à conseiller pour les exercices 15 à 17 : écrire la requête dans essais.mongodb.js, la vérifier, puis la traduire étape par étape. restaurantsParCuisine, fournie, a la forme de filmsDeLAnnee : c'est le point de départ de l'exercice 15.
-->

---

## Une route : lire l'URL, choisir le statut

<div class="dense">

```java
config.routes.get("/api/films", ctx -> {                       // GET /api/films?duree_min=120
    int dureeMin = ctx.queryParamAsClass("duree_min", Integer.class).getOrDefault(0);
    ctx.json(requetes.filmsPlusLongsQue(dureeMin));
});
config.routes.get("/api/films/{titre}", ctx -> {               // GET /api/films/La%20Haine
    Document film = requetes.film(ctx.pathParam("titre"));
    if (film == null) {
        ctx.status(404).json(Map.of("erreur", "film inconnu"));  // décidé par la route
    } else {
        ctx.json(film);
    }
});
```

</div>

<div class="box" style="font-size: 0.8em; margin-top: 0.6rem;">

❓ **À vous de prédire** : quel statut, et quel corps, pour `/api/films` sans paramètre ? pour `/api/films?duree_min=long` ? pour `/api/films/Titanic` ?

</div>

<!--
(50 s)

Deux routes écrites pour le cours. filmsPlusLongsQue(n) est un find sur { duree: { $gte: n } }, trié par durée décroissante ; film(titre) un find(...).first(), qui renvoie null si aucun film n'a ce titre.

Un paramètre de chemin ({titre}) désigne ce qu'on demande ; un paramètre de requête (?duree_min=) précise la demande et peut manquer. Les deux arrivent en String : queryParamAsClass le convertit, getOrDefault donne la valeur quand il manque.

Prédiction de la partie 6 : laisser répondre. Réponses fréquentes : une erreur sans paramètre, 500 pour « long », 200 avec null pour Titanic.
-->

---

## Ce que renvoie la route : un statut et un corps

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
td code { white-space: nowrap; }
</style>

| URL | Statut | Corps |
|---|---|---|
| `/api/films?duree_min=120` | **200** | Chihiro (125), puis Amélie (122), en JSON |
| `/api/films` | **200** | les 4 films : `duree_min` vaut 0 par défaut |
| `/api/films?duree_min=long` | **400** | conversion refusée par Javalin (`TYPE_CONVERSION_FAILED`) |
| `/api/films/La%20Haine` | **200** | `{"titre":"La Haine","annee":1995,"realisateur":"Kassovitz"}` |
| `/api/films/Titanic` | **404** | `{"erreur":"film inconnu"}` |

<div class="warn" style="margin-top: 0.7rem;">

Pour Javalin, une liste vide est une **réponse normale** (200). Le **404** est une décision de la route : `ctx.status(404)` change le statut, `json(…)` écrit le corps.

</div>

<div class="bandeau" style="margin-top: 0.6rem; font-size: 0.85em;">

Dans `requetes-java/` : `./mvnw -q compile exec:java`, puis l'onglet **Ports** (7070) : `/api/sante`

</div>

<!--
(50 s)

Les cinq lignes ont été exécutées avec Javalin 7.2.4 et le pilote 5.14.0 sur MongoDB 9.0.4 : ce sont les réponses obtenues. Corps exact de la première : [{"titre":"Le Voyage de Chihiro","duree":125},{"titre":"Amélie Poulain","duree":122}] ; de la troisième : {"duree_min":[{"message":"TYPE_CONVERSION_FAILED","args":{},"value":"long"}]}.

L'exercice 18 combine ces briques autrement (un paramètre avec valeur par défaut, un 404 décidé par la route) : ne pas en dire plus. Autres statuts (500 d'une exception, 404 d'une route inconnue) : annexe.

Au premier ./mvnw, Maven télécharge ses dépendances (une à deux minutes). Ctrl+C arrête l'API. Une route qui lève une exception répond 500 : relancer sans -q pour voir l'exception.
-->

---

<!-- header: Séance 3 · second temps -->

## À retenir : où, et comment servir

<div class="g2" style="font-size: 0.76em; align-items: stretch;">
<div class="carte vert">
<b class="t">Où ?</b>

- GeoJSON : **longitude d'abord**, contour refermé.
- Des points dans une zone : `$geoWithin` ; la zone d'un point : `$geoIntersects`.
- La forme vient souvent d'un document : `findOne(…).champ`.
- Un résultat vide sans erreur : vérifier l'ordre des coordonnées.

</div>
<div class="carte">
<b class="t">Servir</b>

- Une étape, un appel : `Filters`, `Aggregates`, `Accumulators`…
- `"$champ"` pour lire une valeur, comme en mongosh.
- `find(…)` prépare, `into(…)` envoie.
- La route lit l'URL et **décide** du statut.

</div>
</div>

<div class="bandeau" style="margin-top: 0.9rem; font-size: 0.82em;">

Le tableau de bord : des questions écrites étape par étape, un index mesuré, et une route qui sert le **JSON**.

</div>

<!--
(30 s)

Fin de la réponse à la question directrice : poser les questions, y répondre vite, le servir. Le projet (S6 à S8) reprend tout cela en Java : $lookup, $facet, index, routes Javalin.
-->

---

<!-- header: "" -->

<!-- _class: lead -->

# Des questions ?

**Sébastien Nedjar** (GA1) · **Leïla Sakli Miled** (GA2)
IUT d'Aix-Marseille, département Informatique

<div style="margin-top: 1.2rem; font-size: 0.85em;">

[iutinfoaix-r510.github.io/tp2](https://iutinfoaix-r510.github.io/tp2/)
sebastien.nedjar@univ-amu.fr · leila.SAKLI@univ-amu.fr

</div>

<div class="bandeau" style="margin-top: 1.6rem; text-align: left; font-size: 0.95em;">

🎯 **Dès maintenant, et d'ici le dimanche 13 décembre, 23&nbsp;h&nbsp;59** : terminez la partie 6 en autonomie, demandez « Interroge-moi » sur vos exercices réussis, puis le rendu final avec <code style="white-space: nowrap;">r510-rendre</code>.

</div>

<!--
(10 s)

Questions sur le cours : en séance, ou par courriel à l'enseignant de son groupe ; pour la partie en autonomie, une issue sur le dépôt syllabus.
-->

---

## Crédits

<div class="petit">

**Ce support** : R5.Real.10, IUT d'Aix-Marseille, sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Exemples (films, lieux d'Aix-en-Provence) écrits pour ce cours ; tous exécutés sur MongoDB 9.0.4, le code Java avec le pilote 5.14.0 et Javalin 7.2.4.

**Données du TP** : `sample_restaurants` de MongoDB, issu de *DOHMH New York City Restaurant Inspection Results* (NYC Open Data) ; quartiers *Pediacities NYC Neighborhoods* sous licence [ODC-By 1.0](https://opendatacommons.org/licenses/by/1-0/) ; populations et superficies du US Census Bureau (recensement de 2020). Détail : `data/PROVENANCE.md` du TP2.

**Pour aller plus loin** : [`$expr`](https://www.mongodb.com/docs/manual/reference/operator/query/expr/) · [`$setWindowFields`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/setWindowFields/) · [`$dateTrunc`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateTrunc/) · [`$lookup`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/lookup/) · [`$bucket`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/bucket/) · [`$facet`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/facet/) · [résultats d'`explain()`](https://www.mongodb.com/docs/manual/reference/explain-results/) · [règle ESR](https://www.mongodb.com/docs/manual/tutorial/equality-sort-range-guideline/) · [géospatial](https://www.mongodb.com/docs/manual/geospatial-queries/) · [pilote Java](https://www.mongodb.com/docs/drivers/java/sync/current/fundamentals/builders/) · [Javalin](https://javalin.io/documentation)

</div>

<!--
(Hors minutage : diapo de référence.)

Ce support ne reprend aucun contenu de MongoDB for Academia. Pour les étudiants qui consultent les présentations officielles (en anglais, pensées pour Atlas et l'ancien shell) : « Querying Data with Operators and Compound Conditions » traite $expr, « The MongoDB Aggregation Framework » $addFields, « Querying Data with the MongoDB Aggregation Framework » $facet et $bucket. Liens dans le README du dépôt cours.
-->

---

<!-- header: Annexe -->

<!-- _class: lead -->
<!-- _header: "" -->

# Annexe

Référence, non projetée : rangs, fenêtre, index et plans, `$bucket`, `$facet`, pilote Java, routes, types BSON

<!--
(Hors minutage : l'annexe n'est pas projetée. Elle reste dans le PDF et en ligne : l'énoncé du TP2 renvoie aux diapositives pour la partie 6. $merge (bonus 4 du TP2) et $jsonSchema (TP3) sont au point cours S4.)
-->

---

## `$rank`, `$denseRank`, `$documentNumber` : les égalités

<style scoped>
table { display: table; width: 100%; font-size: 0.76em; }
</style>

<p class="petit">Quatre films fictifs, un seul groupe (sans <code>partitionBy</code>), triés par <code>{ duree: -1 }</code> :</p>

| Film | duree | `$rank` | `$denseRank` | `$documentNumber` |
|---|---|---|---|---|
| F1 | 125 | 1 | 1 | 1 |
| F2 | 122 | **2** | **2** | 2 |
| F3 | 122 | **2** | **2** | 3 |
| F4 | 98 | **4** | **3** | 4 |

<p class="petit">F2 et F3 ont la même durée. <code>&#36;rank</code> leur donne le même rang, puis saute un rang ; <code>&#36;denseRank</code> ne saute pas ; <code>&#36;documentNumber</code> numérote sans égalité (l'ordre entre F2 et F3 n'est alors pas garanti). Ces trois opérateurs exigent un <code>sortBy</code>, et n'ont pas de <code>window</code>.</p>

<!--
Diapo de référence. Tableau obtenu sur MongoDB 9.0.4, sur une collection d'essai de quatre films (F1 125, F2 122, F3 122, F4 98), sans partitionBy. L'exercice 5 demande $rank.
-->

---

## Une fenêtre en image : le cumul

<img src="assets/schemas/s3-fenetre-cumul.svg" alt="Les 4 films triés par année puis titre ont pour durée 98 (La Haine), 82 (Glaneurs), 122 (Amélie) et 125 (Chihiro). Pour Amélie, document courant, la fenêtre documents: [&quot;unbounded&quot;, &quot;current&quot;] va du premier film jusqu'à elle : 98 + 82 + 122 = 302. Les durées cumulées valent 98, 180, 302 et 427." style="display:block; width:100%; margin:0.4rem auto 0;">

<p class="petit" style="margin-top: 0.6rem;">La fenêtre se définit par rapport au document <b>courant</b>, dans l'ordre de <code>sortBy</code>. Sans <code>window</code>, <code>&#36;sum</code> porte sur tout le groupe : 427 pour chaque film.</p>

<!--
Diapo de référence. L'exemple de l'énoncé : { $setWindowFields: { sortBy: { annee: 1, titre: 1 }, output: { duree_cumulee: { $sum: "$duree", window: { documents: ["unbounded", "current"] } } } } } donne 98, 180, 302, 427 sur MongoDB 9.0.4 ; sans window, 427 pour chaque film. window accepte aussi range avec une unité de temps (range: [-2, 0], unit: "month") quand sortBy porte sur une date.
-->

---

## Ce que fait un index, sur les films

<img src="assets/schemas/s3-collscan-ixscan.svg" alt="La requête db.films.find({ annee: 2001 }) exécutée de deux façons. Sans index, COLLSCAN : MongoDB lit les quatre films et teste annee sur chacun ; Chihiro et Amélie sont renvoyés, Glaneurs et La Haine lus pour rien : 4 documents lus, 2 renvoyés. Avec l'index { annee: 1 }, les clés sont rangées 1995, 2000, 2001, 2001 ; IXSCAN saute 1995 et 2000 et lit les deux clés 2001, puis FETCH lit seulement Chihiro et Amélie : 2 clés lues, 2 documents lus, 2 renvoyés." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.5rem;"><code>COLLSCAN</code> lit toute la collection ; <code>IXSCAN</code> parcourt les clés triées et saute à celles qui conviennent ; <code>FETCH</code> lit les documents pointés. MongoDB crée toujours un index sur <code>_id</code>.</p>

<!--
Diapo de référence. Vérifié sur MongoDB 9.0.4 : sans index, COLLSCAN, totalDocsExamined 4, nReturned 2 ; avec { annee: 1 }, FETCH ← IXSCAN, totalKeysExamined 2, totalDocsExamined 2, nReturned 2.
-->

---

## Lire un plan : bon ou mauvais signe ?

<style scoped>
table { display: table; width: 100%; font-size: 0.8em; }
</style>

| Dans `explain("executionStats")` | Mauvais signe | Bon signe |
|---|---|---|
| l'étape qui lit les données | `COLLSCAN` : toute la collection | `IXSCAN` : l'index |
| une étape `SORT` | présente : tri en mémoire | absente |
| `totalDocsExamined` | plus grand que `nReturned` | égal à `nReturned`, ou `0` si la requête est couverte |

<p class="petit" style="margin-top: 0.8rem;">Ce sont les trois questions que se pose le correcteur automatique aux exercices 11 et 12, sur le plan réellement exécuté. La skill <code>lire-mon-explain</code> apprend à lire le vôtre.</p>

<!--
Diapo de référence (ancienne diapo « Vérifier un plan avant de rendre »). Exercice 11 : index utilisé, pas de SORT, documents lus = renvoyés. Exercice 12 : index utilisé, pas de SORT, totalDocsExamined à 0.
-->

---

## `$bucket` : quatre règles à connaître

<style scoped>
.g2 { gap: 0.6em; align-items: stretch; }
.carte { font-size: 0.72em; }
.carte pre { font-size: 0.87em; margin: 0.3em 0 0 0; }
.carte p { margin: 0.2em 0; }
</style>

<div class="g2">
<div class="carte"><b class="t">Une tranche vide n'apparaît pas</b>

Aucun film de moins de 60 min : pas de tranche `0`.

```js
boundaries: [0, 60, 90, 120], default: "long"
// { _id: 60, nb: 1 }, { _id: 90, nb: 1 },
// { _id: 'long', nb: 2 }
```

</div>
<div class="carte rouge"><b class="t">Sans default, la requête échoue</b>

Dès qu'un document est hors bornes. Le message ne cite pas `$bucket` :

<div class="err">

```text
$switch could not find a matching branch
for an input, and no default was specified.
```

</div>

</div>
<div class="carte vert"><b class="t">output choisit les champs de chaque tranche</b>

Sans `output` : un seul champ, `count`.

```js
output: { nb: { $sum: 1 }, titres: { $push: "$titre" } }
// …, { _id: 'long', nb: 2, titres:
//   [ 'Le Voyage de Chihiro', 'Amélie Poulain' ] }
```

</div>
<div class="carte orange"><b class="t">groupBy accepte une expression</b>

Ici, l'âge du film, calculé pour chaque film.

```js
groupBy: { $subtract: [2026, "$annee"] },
boundaries: [0, 26, 30], default: "plus"
// { _id: 0, nb: 2 }, { _id: 26, nb: 1 },
// { _id: 'plus', nb: 1 }
```

</div>
</div>

<!--
Diapo de référence. Tout est vérifié sur MongoDB 9.0.4, sur les 4 films : les résultats et le message d'erreur affichés (précédé de « Executor error during aggregate command on namespace: tp2.films :: caused by :: ») ; sans output, les tranches sont { _id: 0, count: 1 }, { _id: 90, count: 1 }, { _id: 'long', count: 2 }. Des bornes non triées sont refusées, et default doit être hors des bornes.

Exercice 8 : groupBy y est une valeur calculée pour chaque restaurant (l'énoncé le dit dans son TIP), et la dernière tranche est le default. $bucketAuto (bonus 3) choisit lui-même les bornes pour faire des tranches d'effectifs voisins.
-->

---

## Lire le résultat d'un `$facet`

<div class="dense">

```js
db.films.aggregate([
  { $facet: {
      par_annee: [ { $group: { _id: "$annee", nb: { $sum: 1 } } }, { $sort: { _id: 1 } } ],
      plus_long: [ { $sort: { duree: -1 } }, { $limit: 1 }, { $project: { _id: 0, titre: 1 } } ] } },
  { $project: {
      nb_annees: { $size: "$par_annee" },
      le_plus_long: { $first: "$plus_long.titre" } } }
])
// [ { nb_annees: 3, le_plus_long: 'Le Voyage de Chihiro' } ]
```

</div>

<div class="box" style="margin-top: 0.8rem;">

Le résultat du `$facet` est **un document**, que les étapes suivantes peuvent transformer. Chaque facette est **un tableau**, même avec un seul élément : `$first`, `$size`, `$arrayElemAt` ou `$unwind` en tirent les valeurs. En Java : `doc.getList("par_annee", Document.class)`. Une facette qui ne reçoit rien rend `[]`.

</div>

<!--
Diapo de référence. Résultat obtenu sur MongoDB 9.0.4 ; le $facet seul rend { par_annee: [ { _id: 1995, nb: 1 }, { _id: 2000, nb: 1 }, { _id: 2001, nb: 2 } ], plus_long: [ { titre: 'Le Voyage de Chihiro' } ] }. Avec un $match qui ne garde aucun film avant le $facet : { par_annee: [], plus_long: [] }.
-->

---

## Les classes d'aide fabriquent le document

<img src="assets/schemas/s3-shell-vers-java.svg" alt="Le code Java Filters.and( Filters.gte(&quot;annee&quot;, 2000), Filters.gt(&quot;duree&quot;, 100) ) fabrique, appel par appel, le document { &quot;$and&quot;: [ { &quot;annee&quot;: { &quot;$gte&quot;: 2000 } }, { &quot;duree&quot;: { &quot;$gt&quot;: 100 } } ] }, de même sens que { annee: { $gte: 2000 }, duree: { $gt: 100 } } en mongosh. MongoDB l'applique aux 4 films : Chihiro et Amélie retenus, Glaneurs écarté par la durée, La Haine par l'année. Une classe d'aide par rôle : Filters, Projections, Sorts, Aggregates, Accumulators." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.5rem;">Java n'a pas d'écriture <code>{ annee: 2001 }</code> : chaque méthode statique renvoie le morceau de document que vous écririez en mongosh. Le <b>compilateur</b> vérifie le nom de chaque méthode, mais <b>pas</b> les noms de champs : <code>"anee"</code> compile, et ne trouve rien.</p>

<!--
Diapo de référence. Le document du milieu est celui qu'affiche toBsonDocument().toJson() avec le pilote 5.14.0 : {"$and": [{"annee": {"$gte": 2000}}, {"duree": {"$gt": 100}}]}. En mongosh, le « et » est implicite ; le pilote écrit $and : même sens. Exécutée sur MongoDB 9.0.4, la requête renvoie Le Voyage de Chihiro et Amélie Poulain.
-->

---

## Du shell au pilote, appel par appel

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
td:nth-child(1) code { white-space: nowrap; }
</style>

| En Java | En mongosh |
|---|---|
| `find(Filters.eq("annee", 2001))` | `find({ annee: 2001 })` |
| `.projection(Projections.fields(…))` | le 2<sup>e</sup> argument de `find` |
| `.sort(Sorts.ascending("titre"))` | `.sort({ titre: 1 })` |
| `.into(new ArrayList<>())` | rien : le shell affiche tout seul ; ici, la requête part |
| `Aggregates.match(…)`, `Aggregates.group("$annee", …)` | `{ $match: … }`, `{ $group: { _id: "$annee", … } }` |

<div class="box" style="margin-top: 0.6rem; font-size: 0.9em;">

**Pas de classe d'aide** pour une expression (`$toUpper`, `$round`…) : on écrit le document.

```java
Aggregates.project(Projections.computed("titre_maj",
    new Document("$toUpper", "$titre")))
```

</div>

<!--
Diapo de référence. Vérifié avec le pilote 5.14.0 sur MongoDB 9.0.4 : Projections.computed("titre_maj", new Document("$toUpper", "$titre")) compile et donne LE VOYAGE DE CHIHIRO, LES GLANEURS ET LA GLANEUSE, LA HAINE... mais « AMéLIE POULAIN » : $toUpper ne passe en majuscule que les lettres sans accent (ASCII). L'énoncé (partie 6, « Du shell au pilote ») donne d'autres équivalents : Filters.size, Aggregates.lookup, Sorts.orderBy.
-->

---

## Une route Javalin : paramètres de chemin et de requête

<img src="assets/schemas/s3-javalin-route.svg" alt="Comment une route Javalin lit les paramètres d'une URL. À gauche, un paramètre de chemin, sur la route des films /api/annees/{annee}/films : le motif est comparé à l'URL /api/annees/2001/films, {annee} capte le segment 2001 ; ctx.pathParam(&quot;annee&quot;) renvoie la chaîne &quot;2001&quot;, que Integer.parseInt convertit en l'entier 2001. À droite, un paramètre de requête, sur la route fournie du TP /api/boroughs/{borough}/restaurants, appelée avec /api/boroughs/Bronx/restaurants?cuisine=Pizza : ctx.pathParam(&quot;borough&quot;) renvoie &quot;Bronx&quot;, ctx.queryParam(&quot;cuisine&quot;) renvoie &quot;Pizza&quot;, et null si l'URL n'a pas de ?cuisine=." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.5rem;">Les deux arrivent en <code>String</code>. <code>ctx.pathParamAsClass("annee", Integer.class).get()</code> et <code>ctx.queryParamAsClass(…).getOrDefault(…)</code> convertissent, et répondent 400 si la conversion échoue.</p>

<!--
Diapo de référence. À gauche, la route des films de la diapo « Du navigateur à la base » ; à droite, la route fournie dans ApiRestaurants.java. Vérifié avec Javalin 7.2.4 sur MongoDB 9.0.4 : pathParam("annee") renvoie la chaîne "2001" ; queryParam("cuisine") renvoie "Pizza", ou null quand l'URL n'a pas de ?cuisine=.
-->

---

## Ce que renvoie une route : les autres statuts

<style scoped>
table { display: table; width: 100%; font-size: 0.7em; }
td code { white-space: nowrap; }
</style>

| URL demandée | Statut | Corps de la réponse | Pourquoi |
|---|---|---|---|
| `/api/annees/2001/films` | **200** | `[{"titre":"Amélie Poulain",…},…]` | 2 films |
| `/api/annees/1990/films` | **200** | `[]` | une liste vide, pas une erreur |
| `/api/annees/deux-mille/films` | **500** | `Server Error` | `Integer.parseInt` lève une exception |
| `/api/realisateurs` | **404** | `Endpoint GET /api/realisateurs not found` | aucune route n'a ce motif |
| `/api/boroughs/Bronx/restaurants` | **200** | `[]` | sans `?cuisine`, le filtre cherche une cuisine `null` |

<div class="warn" style="margin-top: 0.6rem;">

**200** : tout va bien, même pour une liste vide. **400** : la demande est mal formée. **404** : rien à cette adresse, ou ressource inconnue (la route le décide). **500** : le serveur a levé une exception ; lancez l'API sans `-q` pour la voir.

</div>

<!--
Diapo de référence. Les lignes ont été exécutées avec Javalin 7.2.4 et le pilote 5.14.0 sur MongoDB 9.0.4 : la route des films par année écrite pour le cours, puis une URL sans route, puis la route fournie (ApiRestaurants.java). Avec ?cuisine=Pizza, cette dernière renvoie les pizzerias du Bronx ; sans, ctx.queryParam renvoie null et Filters.eq("cuisine", null) ne trouve aucun restaurant. Statuts du projet (201, 204, écriture) : séances 6 et 7.
-->

---

## Types BSON : les noms que `$type` connaît

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
</style>

<div class="cols" style="grid-template-columns: 1.2fr 1fr; align-items: start;">
<div>

| `$type` | Exemple | Trouve |
|---|---|---|
| `"int"` | `1995` | entier écrit en mongosh |
| `"double"` | `124.5` | nombre décimal |
| `"number"` | `1995`, `124.5` | tout nombre |
| `"string"` | `"1999"` | texte |
| `"null"` | `null` | le champ existe et vaut `null` |
| `"array"` | `["drame"]` | un tableau |
| `"date"` | `ISODate(…)` | une date |

</div>
<div>

<p class="petit">Sur un tableau, <code>&#36;type</code> regarde aussi <b>chaque élément</b> : <code>{ genres: { &#36;type: "string" } }</code> trouve les 4 films, comme <code>{ genres: { &#36;type: "array" } }</code>.</p>

<p class="petit">En mongosh, <code>1995</code> part en <code>int</code> et <code>124.5</code> en <code>double</code> : <code>"number"</code> couvre les deux.</p>

</div>
</div>

<!--
Diapo de référence. Vérifié sur MongoDB 9.0.4 : une valeur 1995 insérée depuis mongosh est un int, 124.5 un double ($type en expression : 'int', 'double') ; sur les films (plus « Film sans durée » et « Film inconnu »), { annee: { $type: "int" } } en trouve 5, "number" 5, "string" 1 ; { genres: { $type: "array" } } 4, { genres: { $type: "string" } } 4 ; { "notes.date": { $type: "date" } } 3 (les films qui ont au moins une note datée).
-->
