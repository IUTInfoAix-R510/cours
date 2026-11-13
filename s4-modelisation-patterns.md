---
marp: true
theme: r510
paginate: true
lang: fr
title: "Séance 4 : modéliser à partir des requêtes, patterns de conception"
description: "R5.Real.10, point cours de la séance 4 (TP3, parties 1 à 7)"
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

# Modéliser à partir des requêtes

**R5.Real.10 - Nouveaux paradigmes de base de données**

Séance 4 · TP3 · semaine du 30 novembre 2026

<p class="question">Une page lue cent fois plus qu'elle n'est écrite : combien de documents doit-elle lire, et qui paie la différence ?</p>

<!--
(20 s)

Question directrice de la séance : « Une page lue cent fois plus qu'elle n'est écrite : combien de documents doit-elle lire, et qui paie la différence ? » Elle porte sur la page d'un épisode de podcast (les exemples) ; la fiche d'une station (le TP) sert de transfert. Le fil de toute la séance : ni tout embarquer, ni tout référencer. Elle est reprise en sous-titre des intercalaires et conclue dans le dernier « À retenir ».

Le point cours se fait en trois temps (somme des durées notées en tête de chaque diapo), 35 minutes en tout.

Premier temps, en début de séance, 20 min (« À vous » compris) :
- titre, objectifs, données (diapos 1 à 3) : 2 min 35 ;
- partie 1, mesurer (diapos 4 à 10) : 5 min 15, prédiction diapo 8 ;
- partie 2, Subset et $merge (diapos 11 à 17) : 5 min 35, prédiction diapo 14 ;
- partie 3, Computed (diapos 18 à 23) : 4 min 25, prédiction diapo 21 ;
- « À retenir » (24), « À vous » (25), « Nouveau dans ce TP » (26) : 2 min 10.

Second temps, quand la majorité du groupe attaque la partie 4, 11 min :
- partie 4, Bucket (diapos 27 à 35) : 5 min 05, prédiction diapo 31 ;
- partie 5, séries temporelles, rétention et validation (diapos 36 à 41) : 4 min 10, prédiction diapo 40 ;
- partie 7, Java (diapos 42 et 43) : 1 min 10, projetée ici pour que le troisième temps reste court ;
- « À retenir » (44) : 35 s.

Troisième temps, quand la majorité du groupe attaque la partie 6, 3 min 55 :
- partie 6, synthèse (diapos 45 à 50) : 3 min 10 ; la discrimination à quatre situations (diapo 47) sert de prédiction ;
- « À retenir » final (51) et « Des questions ? » (52) : 45 s.

L'annexe (après les Crédits, 13 diapos) n'est pas projetée : schémas de référence (trois sens de « bucket », cinq rangements dessinés, une collection time series vue de l'intérieur), $first et $slice, autres patterns (bonus 1 à 4), limites d'une collection time series, buckets internes vus de près, transaction exécutée, tableau complet des symptômes.

Deux jeux de données, comme dans l'énoncé : 🚲 les vélos de Valcerise (les données du TP : seulement pour poser le problème, jamais une réponse) et 🧪 les podcasts d'entraînement (tous les exemples exécutables). Tout a été exécuté sur MongoDB 9.0.4, dans la base tp3 d'un conteneur mongo:9.0.4, dans l'ordre des diapos ; les résultats affichés sont ceux obtenus. Le script des podcasts est dans les notes de la diapo 3 ; chaque diapo qui crée une autre collection d'essai donne son script dans ses notes.
-->

---

<!-- header: Séance 4 · objectifs -->

## Une page lue cent fois plus qu'elle n'est écrite

<div class="bandeau" style="font-size: 0.85em; text-align: left;">
❓ Combien de documents doit-elle lire, et qui paie la différence ?
</div>

<div class="g2" style="margin-top: 0.8rem; font-size: 0.74em; align-items: stretch;">
<div class="carte vert">
<b class="t">🎯 À la fin de la séance, vous saurez</b>

1. **mesurer** la charge d'une application et ce que coûte une lecture ;
2. **construire** et **tenir à jour** un sous-ensemble, un calcul, des buckets, et **ranger** un résultat avec `$merge` ;
3. **confier** des mesures au serveur, les faire **expirer**, **garantir** une forme avec `$jsonSchema` ;
4. **choisir** un rangement par relation, puis **lire** le modèle en Java.

</div>
<div class="carte">
<b class="t">🧠 Déjà vu</b>

- **S1** : l'upsert et `$setOnInsert`
- **S2** : embarquer ou référencer, et ses critères ; les capteurs, une journée par document
- **S3** : `$expr`, `$lookup`, `explain()`, `$dateTrunc`

</div>
</div>

<!--
(1 min)

Lire la question directrice : toute la séance y répond, pattern après pattern.

Les quatre objectifs suivent les niveaux de l'énoncé : Analyser (ex. 1 et 10), Appliquer (ex. 2 à 4, 6 à 9), Créer (ex. 5, 11 et 12). Deux outils sont nouveaux : $merge (objectif 2) et $jsonSchema (objectif 3) ; ils n'ont été vus qu'en annexe de S3 et au bonus 4 du TP2.

« Déjà vu » : l'upsert de S1 (le capteur du garage, avec $setOnInsert) revient pour écrire dans un bucket ; les critères « embarquer ou référencer » de S2 (ceux de l'énoncé du TP1, mot pour mot) sont le point de départ de la partie 1 ; les capteurs de S2 rangeaient déjà une journée de mesures dans un document : c'est l'accroche du Bucket. $expr sert au recalcul de contrôle (partie 3) ; $lookup et explain mesurent le coût d'une jointure ; $dateTrunc coupe les jours d'un bucket.
-->

---

<!-- header: Séance 4 · les données -->

## Deux jeux de données

<img src="assets/schemas/s4-donnees.svg" alt="Les collections de la base tp3, un réseau de vélos en libre-service dans une ville inventée. stations, 24 documents : _id (ST01 à ST24), nom, quartier, capacite, stats (departs, arrivees, minutes). velos, 300 documents : _id, type (mecanique, electrique, cargo), batterie ou caisse selon le type, derniersTrajets (les 5 derniers). avis, 981 documents : station, auteur, note de 1 à 5, texte, date. trajets, 5 556 documents de la semaine du 2 au 8 novembre 2026 : velo, depart { station, t }, arrivee { station, t }, duree. releves, 16 128 documents : station, t, velos, places, un relevé toutes les 15 minutes. occupation, 168 documents : l'historique de la semaine précédente, un document par station et par jour. Les avis, les trajets et les relevés désignent leur station par son _id ; un trajet désigne son vélo par son _id." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="bandeau" style="margin-top: 0.3rem; font-size: 0.8em; text-align: left;">🚲 Les vélos : le problème à résoudre, et les exercices. 🧪 Les podcasts (<code>episodes</code>, <code>commentaires</code>, <code>ecoutes</code>) : les exemples, dans <code>essais.mongodb.js</code>.</div>

<!--
(1 min 15)

En haut, les collections du TP (tableau « Découverte des données » de l'énoncé), des données inventées, toutes les dates en UTC. S'y ajoutent trajets_nouveaux (49), releves_nouveaux (60), sessions (30) et abonnes (50), qui servent aux exercices 3, 4, 6, 8 et 9. Faire repérer ce qui grandit sans fin (avis, trajets, relevés) et ce qui reste petit (24 stations, 300 vélos) : c'est déjà une question de modélisation. Les champs stats et derniersTrajets sont tenus à jour par l'application : on y reviendra (Computed, Subset). Au programme : 7 parties, 12 exercices, 60 points.

Les podcasts sont les données d'entraînement de l'énoncé et du tuteur : 4 épisodes (E1 « Les trous noirs », E2 « Le sommeil », E3 « Les volcans », de l'émission « Sciences en poche » ; E4 « La disparue de Vernon », de « Polar du soir »), 5 commentaires (K1 à K3 sur E1, K2 et K3 à la même minute ; K4 sur E2 ; K5 sur E4), 5 écoutes (E1 à 23 h 50 le 7 septembre, puis à 0 h 10 et 7 h 30 le 8 ; E4 à 19 h et 19 h 30 le 10). Un exemple sur les vélos donnerait la réponse d'un exercice : les podcasts montrent le mécanisme, les vélos le problème.

Script à coller dans essais.mongodb.js pour rejouer les exemples (le même que dans l'énoncé ; il vide d'abord les trois collections) :

use('tp3');
db.episodes.deleteMany({});
db.episodes.insertMany([
  { _id: "E1", emission: "Sciences en poche", titre: "Les trous noirs", duree: 32, publie: ISODate("2026-09-07T06:00:00Z") },
  { _id: "E2", emission: "Sciences en poche", titre: "Le sommeil", duree: 28, publie: ISODate("2026-09-14T06:00:00Z") },
  { _id: "E3", emission: "Sciences en poche", titre: "Les volcans", duree: 35, publie: ISODate("2026-09-21T06:00:00Z") },
  { _id: "E4", emission: "Polar du soir", titre: "La disparue de Vernon", duree: 47, publie: ISODate("2026-09-10T19:00:00Z") }
]);
db.commentaires.deleteMany({});
db.commentaires.insertMany([
  { _id: "K1", episode: "E1", auteur: "lou", note: 5, date: ISODate("2026-09-07T08:12:00Z") },
  { _id: "K2", episode: "E1", auteur: "sam", note: 3, date: ISODate("2026-09-08T21:40:00Z") },
  { _id: "K3", episode: "E1", auteur: "ana", note: 4, date: ISODate("2026-09-08T21:40:00Z") },
  { _id: "K4", episode: "E2", auteur: "lou", note: 2, date: ISODate("2026-09-15T07:05:00Z") },
  { _id: "K5", episode: "E4", auteur: "max", note: 5, date: ISODate("2026-09-11T22:30:00Z") }
]);
db.ecoutes.deleteMany({});
db.ecoutes.insertMany([
  { episode: "E1", t: ISODate("2026-09-07T23:50:00Z"), auditeurs: 40 },
  { episode: "E1", t: ISODate("2026-09-08T00:10:00Z"), auditeurs: 35 },
  { episode: "E1", t: ISODate("2026-09-08T07:30:00Z"), auditeurs: 52 },
  { episode: "E4", t: ISODate("2026-09-10T19:00:00Z"), auditeurs: 18 },
  { episode: "E4", t: ISODate("2026-09-10T19:30:00Z"), auditeurs: 21 }
])

Les diapos suivantes s'exécutent dans l'ordre, sur ces données : chaque diapo part de l'état laissé par les précédentes.
-->

---

<!-- header: Partie 1 · mesurer -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 1 - 🧭 Partir des requêtes : mesurer

Combien de documents une page lit-elle, pour combien d'affichés ?

<!--
(10 s)

Même titre que la partie 1 de l'énoncé du TP3 (exercice 1).
-->

---

## 🚲 La fiche d'une station : 981 avis examinés pour 3 affichés

<style scoped>
p.chiffre { font-size: 1.15em; margin-top: 1.2rem; }
</style>

<p class="chiffre">La fiche affiche les <b>3 derniers avis</b> d'une station. Lue par un <code>&#36;lookup</code> vers <code>avis</code>, sans index : <b>981</b> documents examinés à chaque ouverture.</p>

<div class="warn" style="margin-top: 1rem;">

Et la fiche s'ouvre **20 000 fois par jour**, pour des avis qui changent quelques fois par jour.

</div>

<!--
(40 s)

L'accroche : le problème du TP, avant toute notion. Un constat, pas une réponse : ce qui changerait avec un index, ou en rangeant les avis autrement, est l'objet de la prédiction (diapo 8) et de la mesure (diapo 9). 20 000 ouvertures par jour : c'est le chiffre de l'énoncé (partie 3 et tableau de l'exercice 10).

Mesuré sur MongoDB 9.0.4, sur les données du TP chargées par npm run seed : 981 documents examinés et un parcours de collection (collectionScans: 1) sans index ; c'est la taille de la collection avis. Le nombre d'avis d'une station n'est pas donné : c'est une valeur de l'exercice 1.

Transition : pour savoir qui doit payer ce coût, on change de méthode de conception.
-->

---

## Les données d'abord, ou les requêtes d'abord ?

<img src="assets/schemas/s4-demarche.svg" alt="Deux démarches de conception, en deux lignes. En relationnel : 1, les données (le MCD, des tables en troisième forme normale) ; 2, le schéma (les tables et leurs clés) ; 3, les requêtes, que l'application écrit avec des jointures ; 4, dénormaliser après coup, si c'est lent. Avec MongoDB : 1, les requêtes de l'application, avec leur fréquence ; 2, les relations entre les données, embarquer ou référencer ; 3, les patterns, Subset, Computed, Bucket ; et le résultat : le schéma, fait pour ces requêtes. En bas : en relationnel, un bon schéma vaut pour toutes les requêtes ; avec MongoDB, un bon schéma vaut pour une charge de travail." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.4rem;">Le TP suit cet ordre : mesurer (partie 1), construire les patterns (parties 2 à 5), et <b>décider en dernier</b>, relation par relation (exercice 10).</p>

<div class="bandeau" style="margin-top: 0.4rem;">Avec MongoDB, ce qui est <b>lu ensemble</b> est <b>rangé ensemble</b>, quitte à recopier.</div>

<!--
(50 s)

En relationnel, on normalise d'abord : chaque fait est écrit une fois, et les jointures recollent les morceaux à la lecture. La normalisation optimisait la place, la ressource chère des années 1970. Aujourd'hui, ce qui coûte, c'est le temps de réponse d'une lecture fréquente. En relationnel aussi on dénormalise pour les requêtes, mais après coup ; avec MongoDB, on le décide dès le départ.

C'est la démarche de la documentation de MongoDB (« Identify Application Workload », « Map Relationships », « Apply Patterns ») : trois étapes, dont le schéma est le résultat. Le TP la suit, à une différence près, dite à l'écran : l'étape 2 (embarquer, référencer ou un pattern, relation par relation) vient en dernier, à l'exercice 10, une fois les patterns connus.

Conséquence : il n'y a pas un bon schéma dans l'absolu. Deux applications qui stockent les mêmes données avec des requêtes différentes auront deux schémas différents, tous deux justes.
-->

---

## Étape 1 : le tableau de charge

<style scoped>
table { display: table; width: 100%; font-size: 0.7em; }
td, th { padding: 0.2em 0.6em; }
</style>

| Action, sur la plateforme de podcasts | Type | Fréquence | Données |
|---|---|---|---|
| ouvrir la page d'un épisode | lecture | **50 000 / jour** | l'épisode, ses 2 derniers commentaires, leur nombre |
| publier un commentaire | écriture | 500 / jour | un commentaire |
| lire tous les commentaires | lecture | 200 / jour | une page de commentaires |
| relever les auditeurs | écriture | chaque minute | une mesure |
| tracer la courbe d'une journée | lecture | 300 / jour | ❓ |
| enregistrer un brouillon | écriture | toutes les 30 s | un brouillon, inutile 1 h plus tard |

<div class="warn" style="margin-top: 0.5rem;">

Et la **croissance** : 4 épisodes, des commentaires **sans limite**, des mesures **chaque minute**.

</div>

<!--
(1 min 15)

Des chiffres inventés, mais du bon ordre de grandeur. Faire lire la colonne Fréquence : la page d'un épisode est lue 100 fois plus souvent qu'un commentaire n'est écrit (50 000 contre 500). C'est ce rapport qui va décider des choix de modèle. Un épisode viral peut recevoir 10 000 commentaires.

La salle remplit la case ❓ : la courbe d'une journée lit toutes les mesures d'un épisode sur un jour, soit 1 440 si l'on relève chaque minute. Puis demander quelle ligne pèse le plus : la première (la plus fréquente), et la quatrième (celle qui grandit le plus vite).

La dernière ligne servira à la partie 5 : des données qui ne servent plus au bout d'une heure (la rétention). On a pris des brouillons, et non des sessions, pour ne pas toucher à la collection sessions du TP dans la base tp3.

Lien avec l'exercice 1 : il mesure la charge réelle du réseau de vélos (avis par station, départs par jour).
-->

---

## ❓ Combien de documents pour la page de E1 ?

<style scoped>
.g3 { gap: 0.8em; align-items: stretch; }
.carte { font-size: 0.8em; text-align: center; }
</style>

La page affiche l'épisode et ses commentaires, sans index sur `commentaires.episode` (5 commentaires, dont 3 sur E1) :

<div class="dense">

```js
db.episodes.aggregate([
  { $match: { _id: "E1" } },
  { $lookup: { from: "commentaires", localField: "_id", foreignField: "episode", as: "c" } }
])
```

</div>

<div class="g3" style="margin-top: 0.6rem;">
<div class="carte"><b class="t">A</b>1 épisode + 3 commentaires</div>
<div class="carte"><b class="t">B</b>1 épisode + 5 commentaires</div>
<div class="carte"><b class="t">C</b>1 seul document</div>
</div>

<p class="petit" style="margin-top: 0.6rem;">Et avec un index sur <code>commentaires.episode</code> ? Et si les commentaires étaient dans l'épisode ?</p>

<!--
(30 s)

Faire voter à main levée, sans commenter. La réponse est sur la diapo suivante : B sans index, A avec un index, C si les commentaires sont embarqués.
-->

---

## Réponse : sans index, toute la collection jointe

<div class="dense">

```js
db.episodes.explain("executionStats").aggregate([ /* le même pipeline */ ]).stages[1]
// { '$lookup': { ... }, nReturned: Long('1'), ..., totalDocsExamined: Long('5'),
//   totalKeysExamined: Long('0'), collectionScans: Long('1'), indexesUsed: [], ... }
```

</div>

<img src="assets/schemas/s4-jointure.svg" alt="La page de l'épisode E1 lue par une jointure, en deux cas. En haut, sans index sur commentaires.episode : l'épisode E1 est lu (1 document), puis $lookup parcourt toute la collection commentaires (K1 à K5, 5 documents examinés) pour garder ceux de E1 (K1, K2, K3). En bas, avec un index sur episode : l'index donne directement les trois commentaires de E1 (3 clés, 3 documents examinés). À droite, troisième cas : les commentaires utiles sont embarqués dans l'épisode, la page lit 1 seul document." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.3rem;">Vous savez lire un <code>explain</code> depuis S3. Pour un pipeline, les compteurs de la jointure sont dans l'étape <code>&#36;lookup</code> du tableau <code>stages</code>.</p>

<!--
(50 s)

Vérifié sur MongoDB 9.0.4 : sans index, totalDocsExamined: 5 et collectionScans: 1 (sortie abrégée : les « ... » remplacent des champs) ; après db.commentaires.createIndex({ episode: 1 }), totalDocsExamined: 3, totalKeysExamined: 3, collectionScans: 0, indexesUsed: [ 'episode_1' ] ; un find sur _id, totalDocsExamined: 1. Le schéma reprend les trois cas.

Sur 5 commentaires, l'écart ne se voit pas. Sur les 981 avis du TP, c'est la fiche station. Et même avec un index, la jointure lit toujours plus qu'un document : 50 000 fois par jour, ce coût se répète 50 000 fois. $lookup reste le bon outil pour une requête rare (une statistique, une page d'administration).

L'index créé ici reste pour la suite des démonstrations ; il ne change aucun résultat affiché.
-->

---

## Les deux réponses de S2 échouent ici

<style scoped>
.cols { align-items: stretch; }
.carte { font-size: 0.8em; }
</style>

Les critères de S2 (ceux de l'énoncé du TP1), appliqués aux commentaires de la page :

<div class="cols" style="margin-top: 0.4rem;">
<div class="carte rouge"><b class="t">Tout embarquer</b>

✔ Lus ensemble : la page les affiche.
✘ Mais leur nombre est **sans limite**.

</div>
<div class="carte rouge"><b class="t">Tout référencer</b>

✔ Un nombre sans limite : chacun dans sa collection.
✘ Mais la page la plus lue fait une **jointure** à chaque ouverture.

</div>
</div>

<div class="bandeau" style="margin-top: 0.8rem; font-size: 0.82em; text-align: left;">

**Ni tout embarquer, ni tout référencer.** Quatre besoins à suivre : garder **quelques éléments** d'une liste (partie 2), **compter sans relire** (partie 3), **regrouper des mesures** (parties 4 et 5), **oublier** ce qui est périmé (partie 5). Vous déciderez à l'exercice 10.

</div>

<!--
(1 min)

Les critères de S2, mot pour mot ceux de l'énoncé du TP1 : peu d'éléments et un nombre borné, ou données presque toujours lues ensemble → embarquer ; nombre grand ou sans limite, ou données modifiées souvent, indépendamment → référencer. Ici, les commentaires cochent une case de chaque côté : aucune des deux réponses ne convient.

Le bandeau est la feuille de route de la séance, lue dans le tableau de charge : chaque partie répond à un besoin. Les noms des patterns viendront avec eux.

✍️ Question de la partie 1, à garder pour la mise en commun (ne pas projeter) : embarquer tous les avis dans la station la plus commentée, dans un an : un document qui grossit à chaque avis, transféré en entier à chaque ouverture pour en montrer 3, vers la limite de 16 Mo ; et des documents énormes, dont on n'utilise qu'une petite partie, chassent les autres de la mémoire (le working set).

L'exercice 1 : deux $lookup depuis stations, puis $size et $avg sur les tableaux obtenus, comme l'indique l'énoncé. Ne pas en dire plus.
-->

---

<!-- header: Partie 2 · embarquer un sous-ensemble -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 2 - ✂️ Le pattern Subset

La page montre 2 commentaires sur 10 000 : comment n'en lire que 2 ?

<!--
(10 s)

Même titre que la partie 2 de l'énoncé du TP3 (exercices 2 et 3).
-->

---

## Un sous-ensemble embarqué, la liste complète à part

<img src="assets/schemas/s4-subset.svg" alt="Le pattern Subset sur les podcasts. Au centre gauche, l'épisode E1 dans la collection episodes embarque un tableau derniersCommentaires de 2 éléments, les plus récents : { auteur: ana, note: 4, … } et { auteur: sam, note: 3, … }. Au centre droit, la collection commentaires garde tous les commentaires (K1, K2, K3…). À gauche, en vert, la lecture fréquente : la page de l'épisode lit le seul document E1. À droite, en gris, la lecture rare : la liste complète lit la collection commentaires. En bas, en orange, l'écriture : un nouveau commentaire est inséré dans commentaires et ajouté au tableau de l'épisode, qui garde les 2 plus récents." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.3rem;">K2 et K3 ont la même date : un <b>second critère</b> de tri décide (l'<code>_id</code> décroissant : ana, K3, avant sam, K2). Chaque élément ne garde que ce que la page <b>affiche</b>.</p>

<div class="bandeau" style="margin-top: 0.3rem;">La page fréquente lit <b>un</b> document, de taille <b>bornée</b> ; la liste rare paie la jointure.</div>

<!--
(1 min)

Faire suivre les trois chemins : la lecture fréquente (vert) ne lit qu'un document ; la lecture rare (gris) lit la collection complète ; l'écriture (orange) touche deux collections. « Les plus utiles » dépend de la requête : les plus récents (ici), les mieux notés, les plus lus.

Avant et après, document par document (l'état « après » est celui obtenu sur MongoDB 9.0.4 en rangeant dans E1 ses 2 commentaires les plus récents, triés par date puis _id décroissants ; le code qui le construit n'est pas montré, c'est la forme de l'exercice 2) :

// avant : episodes
{ _id: 'E1', emission: 'Sciences en poche', titre: 'Les trous noirs', duree: 32,
  publie: ISODate('2026-09-07T06:00:00.000Z') }
// commentaires, 3 sur E1
{ _id: 'K1', episode: 'E1', auteur: 'lou', note: 5, date: ISODate('2026-09-07T08:12:00.000Z') }
{ _id: 'K2', episode: 'E1', auteur: 'sam', note: 3, date: ISODate('2026-09-08T21:40:00.000Z') }
{ _id: 'K3', episode: 'E1', auteur: 'ana', note: 4, date: ISODate('2026-09-08T21:40:00.000Z') }
// après : episodes (commentaires ne change pas)
{ _id: 'E1', emission: 'Sciences en poche', titre: 'Les trous noirs', duree: 32,
  publie: ISODate('2026-09-07T06:00:00.000Z'),
  derniersCommentaires: [
    { auteur: 'ana', note: 4, date: ISODate('2026-09-08T21:40:00.000Z') },
    { auteur: 'sam', note: 3, date: ISODate('2026-09-08T21:40:00.000Z') } ] }

K1 n'est pas dans le sous-ensemble : c'est le plus ancien. Lien avec l'exercice 2 : la même idée sur les avis des stations, avec 3 avis et la forme cible de l'énoncé ; la règle de départage y est imposée.
-->

---

## Les N premiers de chaque groupe, d'un coup : `$topN`

Remplir le sous-ensemble de **tous** les documents d'un coup, c'est garder les N premiers de chaque groupe. Les 2 épisodes les plus longs de chaque émission :

<div class="dense">

```js
db.episodes.aggregate([
  { $group: { _id: "$emission",
      plusLongs: { $topN: { n: 2, sortBy: { duree: -1 },
                            output: { titre: "$titre", duree: "$duree" } } } } },
  { $sort: { _id: 1 } }
])
// [ { _id: 'Polar du soir', plusLongs: [ { titre: 'La disparue de Vernon', duree: 47 } ] },
//   { _id: 'Sciences en poche',
//     plusLongs: [ { titre: 'Les volcans', duree: 35 },
//                  { titre: 'Les trous noirs', duree: 32 } ] } ]
```

</div>

<p class="petit" style="margin-top: 0.4rem;"><code>sortBy</code> donne l'ordre (un second critère départage les égalités), <code>output</code> la forme de chaque élément. Mais le résultat s'affiche, puis disparaît : comment le <b>ranger</b> dans une collection ?</p>

<!--
(45 s)

Le besoin d'abord : construire le sous-ensemble de tous les documents en une fois, à partir de la collection complète. Dans un $group, $topN garde les n premiers documents de chaque groupe ; un groupe plus petit que n les garde tous (« Polar du soir » n'a qu'un épisode). C'est l'exemple de l'énoncé, sur un autre axe que l'exercice 2.

Vérifié sur MongoDB 9.0.4 : le résultat affiché (mis en forme sur moins de lignes que dans mongosh).

La question en bas amène $merge : un pipeline ne fait que lire.
-->

---

## ❓ Enregistrer le résultat : que devient `resumes` ?

<style scoped>
.cols { align-items: stretch; }
</style>

<div class="dense">

```js
db.resumes.insertMany([                                   // deux fiches existent déjà
  { _id: "E1", titre: "Trous noirs (brouillon)", aRevoir: true },
  { _id: "E4", titre: "La disparue de Vernon" } ]);
db.episodes.aggregate([
  { $match: { emission: "Sciences en poche" } },          // E1, E2, E3
  { $project: { titre: 1, duree: 1 } },
  { $merge: { into: "resumes", on: "_id", whenMatched: "merge", whenNotMatched: "insert" } }
])
```

</div>

<div class="cols" style="margin-top: 0.4rem;">
<div class="box">

`$merge`, en **dernière** étape, écrit chaque document du résultat dans `into` : il y cherche le même `on`, puis applique `whenMatched` s'il le trouve, `whenNotMatched` sinon.

</div>
<div class="warn">

**Prédire** : que contient `resumes` ensuite ? Que deviennent E1, puis E2 et E3, puis E4 ?

</div>
</div>

<!--
(40 s)

C'est l'exemple de l'énoncé (section « Enregistrer un résultat avec $merge » de la partie 2). Laisser une minute de réflexion à deux, sans répondre. La réponse est sur la diapo suivante.

Pour rejouer : db.resumes.deleteMany({}) avant l'insertMany.
-->

---

## Réponse : fusionné, insérés, laissé

<style scoped>
table { display: table; width: 100%; font-size: 0.68em; }
td, th { padding: 0.18em 0.6em; }
tr.predit td { background: #fff8e1 !important; font-weight: bold; }
</style>

<div class="dense">

```js
db.resumes.find()
// [ { _id: 'E1', titre: 'Les trous noirs', aRevoir: true, duree: 32 },
//   { _id: 'E4', titre: 'La disparue de Vernon' },
//   { _id: 'E2', titre: 'Le sommeil', duree: 28 }, { _id: 'E3', titre: 'Les volcans', duree: 35 } ]
```

</div>

<table>
<thead><tr><th>Étape finale</th><th>E1 (déjà là)</th><th>E2, E3 (nouveaux)</th><th>E4 (absent du résultat)</th></tr></thead>
<tbody>
<tr class="predit"><td><code>whenMatched: "merge"</code> (par défaut)</td><td>fusionné : <code>aRevoir</code> gardé</td><td>insérés</td><td>inchangé</td></tr>
<tr><td><code>whenMatched: "replace"</code></td><td>remplacé : <code>aRevoir</code> disparaît</td><td>insérés</td><td>inchangé</td></tr>
<tr><td><code>whenMatched: "keepExisting"</code></td><td>gardé tel quel</td><td>insérés</td><td>inchangé</td></tr>
<tr><td><code>"replace"</code>, <code>whenNotMatched: "discard"</code></td><td>remplacé</td><td><b>ignorés</b></td><td>inchangé</td></tr>
<tr><td><code>{ &#36;out: "resumes" }</code></td><td>remplacé</td><td>insérés</td><td><b>supprimé</b></td></tr>
</tbody>
</table>

<div class="bandeau" style="margin-top: 0.5rem; font-size: 0.86em;"><code>&#36;out</code> remplace <b>toute</b> la collection ; <code>&#36;merge</code> ne touche qu'aux documents du résultat.</div>

<!--
(1 min 15)

La ligne surlignée est celle de la prédiction. Le pipeline lui-même ne renvoie rien (un tableau vide) : son résultat est dans resumes, qu'on relit avec find.

Vérifié sur MongoDB 9.0.4, resumes remise dans son état de départ (les deux fiches) avant chaque essai : merge donne le résultat affiché ; replace donne { _id: 'E1', titre: 'Les trous noirs', duree: 32 } ; keepExisting laisse { _id: 'E1', titre: 'Trous noirs (brouillon)', aRevoir: true } ; replace avec discard laisse resumes à deux documents (E1 remplacé, E4) ; $out laisse E1, E2, E3, sans E4. Deux erreurs à connaître : placé avant une autre étape, « $merge can only be the final stage in the pipeline » ; avec on sur un autre champ que _id sans index unique, « Cannot find index to verify that join fields will be unique ».

C'est ce qui permet de recalculer de temps en temps une vue matérialisée sans perdre ce qu'elle contient d'autre (le bonus 4 du TP2 en construit une), ou d'écrire dans une collection qui contient déjà des données : c'est le cas des exercices 2 et 5. Ne pas dire quelles options ils demandent : l'énoncé pose la question dans son indice.
-->

---

## Tenir le sous-ensemble à jour : `$push` borné

<img src="assets/schemas/s4-push-slice.svg" alt="$push avec $each, $sort et $slice, en trois temps, sur l'épisode E3, qui n'a pas encore de champ derniersCommentaires ($push le crée). 1, $each ajoute les trois nouveaux éléments, dans l'ordre donné : lou (21 septembre, 8 h), sam (23 septembre, 19 h 30), zoe (22 septembre, 12 h 15). 2, $sort: { date: -1 } trie tout le tableau du plus récent au plus ancien : sam, zoe, lou. 3, $slice: 2 garde les 2 premiers : sam et zoe ; lou quitte le tableau, pas la collection commentaires." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="dense">

```js
db.episodes.updateOne({ _id: "E3" }, { $push: { derniersCommentaires: {
  $each: [ { auteur: "lou", note: 4, date: ISODate("2026-09-21T08:00:00Z") },
           { auteur: "sam", note: 5, date: ISODate("2026-09-23T19:30:00Z") },
           { auteur: "zoe", note: 3, date: ISODate("2026-09-22T12:15:00Z") } ],
  $sort: { date: -1 }, $slice: 2 } } });
db.episodes.findOne({ _id: "E3" }, { _id: 0, derniersCommentaires: 1 })
// { derniersCommentaires: [
//     { auteur: 'sam', note: 5, date: ISODate('2026-09-23T19:30:00.000Z') },
//     { auteur: 'zoe', note: 3, date: ISODate('2026-09-22T12:15:00.000Z') } ] }
```

</div>

<!--
(50 s)

Les trois modificateurs s'appliquent dans cet ordre : ajouter, trier tout le tableau (anciens et nouveaux éléments), couper. Un nombre positif dans $slice garde les premiers, un nombre négatif les derniers. Le tableau n'existait pas : $push l'a créé.

Vérifié sur MongoDB 9.0.4 : le résultat affiché (mis en forme sur deux lignes).

Deux temps de vie d'un sous-ensemble : on le construit une fois par une agrégation ($topN, puis $merge), puis on le tient à jour à chaque écriture ($push borné). Ce sont les exercices 2 et 3.
-->

---

## Le prix du Subset

<style scoped>
.g2 { gap: 0.6em; align-items: stretch; }
.carte { font-size: 0.74em; }
</style>

<div class="g2" style="margin-top: 0.3rem;">
<div class="carte orange"><b class="t">Deux écritures par commentaire</b>
Insérer dans <code>commentaires</code>, puis pousser dans l'épisode. Entre les deux, les collections ne sont pas d'accord.
</div>
<div class="carte orange"><b class="t">Des données recopiées</b>
L'auteur et la note existent deux fois.
</div>
<div class="carte violet"><b class="t">Quand l'utiliser</b>
Une liste sans fin dont une requête <b>fréquente</b> ne lit que quelques éléments, toujours les mêmes.
</div>
<div class="carte"><b class="t">🚲 Dans le TP</b>
Ex. 2 : les 3 derniers avis de chaque station, par <code>&#36;merge</code>. Ex. 3 : chaque nouveau trajet entre dans les 5 derniers trajets de son vélo.
</div>
</div>

<div class="bandeau" style="margin-top: 0.7rem; font-size: 0.88em;">Un symptôme, une solution éprouvée, un prix : c'est ce qu'on appelle un <b>pattern de conception</b>.</div>

<!--
(55 s)

Le prix est toujours le même avec une donnée recopiée : plus d'écritures et un risque d'incohérence. Il est acceptable ici parce que l'écriture est 100 fois moins fréquente que la lecture (tableau de charge). Sans ce rapport, le pattern complique pour rien : une page lue rarement se contente de la jointure.

Le bandeau nomme ce qu'on vient de faire : un pattern de conception, comme les design patterns objet (un nom partagé pour une solution connue, avec son contexte et ses conséquences). Chaque pattern de la séance suit la même fiche : le symptôme, le principe, les documents avant et après, le prix, quand l'utiliser.

Exercice 3 : les trajets anciens ont été archivés, ils ne sont plus dans trajets ; recalculer derniersTrajets à partir de trajets les perdrait. L'énoncé le dit dans son indice.

✍️ Questions de la partie 2, à garder pour la mise en commun (ne pas projeter) :
- un avis supprimé par la modération : le supprimer dans avis, et le retirer du sous-ensemble de la station s'il y est (tout ce qui change un avis doit changer ses deux copies) ; le sous-ensemble a alors un élément de moins, à compléter par le suivant (un recalcul pour cette station) ;
- 3 avis et pas 50 : la taille d'un sous-ensemble se règle sur l'affichage de la page fréquente, pas sur les données.
-->

---

<!-- header: Partie 3 · calculer à l'écriture -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 3 - 🧮 Le pattern Computed

Un nombre lu 50 000 fois et changé 500 fois : pourquoi le recompter ?

<!--
(10 s)

Même titre que la partie 3 de l'énoncé du TP3 (exercice 4).
-->

---

## Compter à l'écriture : un `$inc`

<div class="dense">

```js
// à la lecture : countDocuments({ episode: "E1" }) → 3, recompté 50 000 fois par jour
// à l'écriture : E1 porte nbCommentaires: 3 ; un nouveau commentaire, K6, l'augmente de 1
db.commentaires.insertOne({ _id: "K6", episode: "E1", auteur: "zoe", note: 5,
                            date: ISODate("2026-09-12T09:00:00Z") });
db.episodes.updateOne({ _id: "E1" }, { $inc: { nbCommentaires: 1 } });
db.episodes.findOne({ _id: "E1" }, { _id: 0, titre: 1, nbCommentaires: 1 })
// { titre: 'Les trous noirs', nbCommentaires: 4 }
```

</div>

<img src="assets/schemas/s4-computed.svg" alt="Le pattern Computed sur les podcasts. En haut, le chemin d'écriture : un nouveau commentaire sur E1, K6, est inséré dans commentaires, puis $inc: { nbCommentaires: 1 } augmente de 1 le compteur rangé dans l'épisode E1 (3 devient 4). En bas, le chemin de lecture : la page de l'épisode lit E1, qui contient déjà nbCommentaires: 4 ; aucun commentaire n'est relu. À droite, en pointillés : un recalcul par lot, de temps en temps, recompte les commentaires et compare au compteur." style="display:block; width:100%; margin:0.2rem auto 0;">

<!--
(1 min)

Le symptôme et le principe : une valeur dérivée (un compte, une somme) calculée au moment de l'écriture et rangée dans le document qui l'affiche. La valeur est lue 100 fois plus souvent qu'elle ne change : compter à la lecture, c'est relire 50 000 fois par jour les commentaires (ou leur index) pour un nombre qui n'a pas changé. En SQL : une colonne dénormalisée, tenue à jour par l'application ou par un trigger.

Sur le schéma : en haut, le chemin d'écriture (insérer K6, puis $inc : 3 devient 4) ; en bas, le chemin de lecture (la page lit E1, qui contient déjà le nombre) ; à droite, le recalcul par lot de contrôle (diapo « Personne ne voit la dérive »).

Entre l'insertOne et le $inc, les deux collections ne sont pas d'accord : K6 existe, le compteur vaut encore 3 (diapo « Une panne entre deux écritures »). $inc est atomique : deux commentaires écrits en même temps ajoutent bien 2. Pour une moyenne, on range la somme et le nombre, et on divise à la lecture.

Pour rejouer : le compteur de départ se pose une fois, db.episodes.updateOne({ _id: "E1" }, { $set: { nbCommentaires: 3 } }). Vérifié sur MongoDB 9.0.4 : countDocuments renvoie 3 ; le résultat affiché.
-->

---

## Rejouer des événements : une boucle, un calcul

Deux nouveaux commentaires sont enregistrés d'un coup : K7 sur E1, K8 sur E3. Puis, pour chacun, le compteur de son épisode :

<div class="dense">

```js
db.commentaires.insertMany([
  { _id: "K7", episode: "E1", auteur: "max", note: 4, date: ISODate("2026-09-12T10:00:00Z") },
  { _id: "K8", episode: "E3", auteur: "ana", note: 5, date: ISODate("2026-09-24T09:00:00Z") } ]);
db.commentaires.find({ _id: { $in: ["K7", "K8"] } }).forEach(c => {
  db.episodes.updateOne({ _id: c.episode }, { $inc: { nbCommentaires: 1 } });
});
db.episodes.find({}, { titre: 1, nbCommentaires: 1 })
// [ { _id: 'E1', titre: 'Les trous noirs', nbCommentaires: 5 },
//   { _id: 'E2', titre: 'Le sommeil' },
//   { _id: 'E3', titre: 'Les volcans', nbCommentaires: 1 },
//   { _id: 'E4', titre: 'La disparue de Vernon' } ]
```

</div>

<p class="petit" style="margin-top: 0.4rem;"><code>forEach</code> exécute la fonction pour chaque document ; <code>c</code> est le document courant. <code>&#36;inc</code> crée le champ s'il manque : E3 passe de rien à 1. 🚲 Les exercices 3, 4 et 6 parcourent ainsi <code>trajets_nouveaux</code> et <code>releves_nouveaux</code>.</p>

<!--
(55 s)

Un événement (un commentaire, un trajet, un relevé) entraîne une écriture du fait, puis de ce qu'on en tire (un compteur, un sous-ensemble, un bucket). Ici, les faits sont enregistrés d'abord, d'un seul insertMany ; la boucle ne fait que le calcul, comme celle de l'énoncé (section « Écrire dans une boucle »).

Vérifié sur MongoDB 9.0.4 : le résultat affiché (mis en forme sur deux lignes). E2 et E4 n'ont pas de compteur : on ne l'a posé que sur E1. Relancer la boucle seule par erreur ajouterait 1 de plus à chaque compteur : c'est la prédiction suivante.

Exercices 3, 4 et 6 : la boucle sur trajets_nouveaux ou releves_nouveaux est dans l'énoncé (section « Écrire dans une boucle ») ; ce sont les écritures de chaque exercice qui sont à trouver. Ne pas en dire plus.
-->

---

## ❓ Un message reçu deux fois

<div class="dense">

```js
// une panne réseau : l'application renvoie le $inc de K6, qui avait pourtant réussi
db.episodes.updateOne({ _id: "E1" }, { $inc: { nbCommentaires: 1 } })
```

</div>

<div class="cols" style="margin-top: 0.6rem; align-items: stretch;">
<div class="warn">

**Prédire** : E1 a 5 commentaires. Que vaut maintenant son `nbCommentaires` ?

</div>
<div class="warn">

**Et ensuite** : qui s'en aperçoit ? La page ? Une requête ? Personne ?

</div>
</div>

<!--
(25 s)

Faire répondre la salle. Rappel de S1 : $set se rejoue sans dommage (même résultat deux fois), $inc et $push non. La réponse est sur la diapo suivante.
-->

---

## Personne ne voit la dérive : un recalcul la révèle

<div class="cols dense" style="grid-template-columns: 0.8fr 1.2fr; align-items: start;">
<div>

<p class="etiquette">Le compteur ment</p>

```js
db.episodes.findOne({ _id: "E1" },
  { _id: 0, titre: 1, nbCommentaires: 1 })
// { titre: 'Les trous noirs',
//   nbCommentaires: 6 }
```

</div>
<div>

<p class="etiquette">Le contrôle par recalcul</p>

```js
db.episodes.aggregate([
  { $match: { nbCommentaires: { $exists: true } } },
  { $lookup: { from: "commentaires", localField: "_id",
      foreignField: "episode", as: "c" } },
  { $project: { stocke: "$nbCommentaires",
      recalcule: { $size: "$c" } } },
  { $match: { $expr: { $ne: ["$stocke", "$recalcule"] } } } ])
// [ { _id: 'E1', stocke: 6, recalcule: 5 } ]
```

</div>
</div>

<div class="bandeau" style="margin-top: 0.5rem; font-size: 0.86em;">En pratique : calculer à l'écriture, et <b>recalculer</b> de temps en temps, par lot, pour contrôler.</div>

<p class="petit" style="margin-top: 0.4rem;">🚲 Exercice 4 : les compteurs <code>stats</code> des stations, avec <code>&#36;inc</code>. Bonus 6 : le contrôle par recalcul.</p>

<!--
(55 s)

Vérifié sur MongoDB 9.0.4 : après le $inc rejoué, nbCommentaires vaut 6 pour 5 commentaires ; le contrôle ne renvoie que E1 (E3 a 1 commentaire et nbCommentaires: 1). Le premier $match écarte les épisodes sans compteur, qui sortiraient aussi (un champ absent est différent de 0). $expr compare deux champs du même document (S3). Le recalcul est rare : il peut se permettre une jointure.

Deux façons de tenir un calcul à jour, le tableau de l'énoncé (partie 3), à commenter sans le projeter :
- à l'écriture ($inc) : toujours à jour, une mise à jour de plus par écriture ;
- par lot (un pipeline terminé par $merge, une vue matérialisée, comme au bonus 4 du TP2) : en retard d'un lot, une agrégation sur toute la collection, mais aucune dérive durable, puisque le lot repart des données.
Le choix dépend de la fraîcheur exigée : un compteur affiché doit être à jour ; une statistique mensuelle peut attendre la nuit.

✍️ Question de la partie 3, à garder pour la mise en commun (ne pas projeter) : des stations dérivent ; une écriture faite deux fois, ou oubliée, fausse le compteur pour toujours, sans erreur ; on corrige la station fautive par un recalcul ciblé, sans tout recalculer.

Exercice 4 : deux stations par trajet (départ et arrivée), et la durée du trajet à ajouter au départ. Ne pas en dire plus.
-->

---

## Une panne entre deux écritures : qui garantit les deux ?

<style scoped>
.cols { align-items: stretch; }
.carte { font-size: 0.72em; }
</style>

<img src="assets/schemas/s4-transaction.svg" alt="Deux écritures, deux documents. Pour publier un commentaire : 1, insérer K6 dans commentaires ; 2, ajouter 1 à nbCommentaires de l'épisode E1. Si le programme s'arrête entre 1 et 2 (un éclair), K6 existe mais le compteur n'a pas bougé : les deux collections ne sont plus d'accord. Chaque écriture, seule, est atomique : elle se fait entièrement ou pas du tout. Rien ne lie les deux." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="cols" style="margin-top: 0.3rem;">
<div class="carte vert"><b class="t">D'abord : ranger ensemble ce qui change ensemble</b>

Le compteur et les derniers commentaires **dans l'épisode** : une seule `updateOne` les modifie ensemble, ou pas du tout.

</div>
<div class="carte orange"><b class="t">Sinon : une transaction</b>

Tout ou rien, sur plusieurs documents. Elle demande un *replica set* : le serveur seul du codespace la refuse (exemple exécuté en annexe).

</div>
</div>

<!--
(1 min)

Une seule ligne de rappel : l'atomicité d'un document a été vue en S2 (l'emprunt de la médiathèque, écrit deux fois), et l'énoncé du TP3 le redit (« Atomicité : un document à la fois »). Le schéma : le programme insère K6, puis s'arrête avant le $inc ; chaque écriture, seule, est atomique, mais rien ne lie les deux. C'est le prix de Subset et de Computed : chacun ajoute une seconde écriture.

L'énoncé du TP3 dit que les transactions sont « présentées au point cours » : c'est cette diapo. Une transaction multi-documents rend un ensemble d'écritures atomique ; elle coûte plus cher qu'une écriture simple, et demande un replica set (plusieurs serveurs qui gardent chacun une copie des données). La documentation de MongoDB le dit : une transaction ne remplace pas un bon modèle ; d'abord ranger ensemble ce qui change ensemble. Le cas d'école : un virement entre deux comptes, qui ne peuvent pas être fusionnés en un document.

Dans le codespace, mongosh refuse dès la première écriture : « This MongoDB deployment does not support retryable writes. Please add retryWrites=false to your connection string. » Les exercices n'en ont pas besoin ; le recalcul de contrôle (bonus 6) est l'autre garde-fou.
-->

---

<!-- header: Séance 4 · premier temps -->

## À retenir : mesurer, puis payer à l'écriture

<style scoped>
.g3 { gap: 0.7em; align-items: stretch; }
.carte { font-size: 0.72em; }
</style>

<div class="g3" style="margin-top: 0.3rem;">
<div class="carte"><b class="t">Mesurer</b>

- Les **requêtes** d'abord, avec leur **fréquence**.
- Une jointure lit **toujours** plus qu'un document.

</div>
<div class="carte vert"><b class="t">Subset</b>

- Quelques éléments **dans** le document, la liste complète **à part**.
- `$topN` construit, `$push` borné entretient, `$merge` **range**.

</div>
<div class="carte orange"><b class="t">Computed</b>

- La valeur se calcule **à l'écriture** (`$inc`).
- Une écriture rejouée la fausse : **recalculer** pour contrôler.

</div>
</div>

<div class="bandeau" style="margin-top: 0.8rem; font-size: 0.86em;">

La page la plus lue doit lire **un** document : l'écriture paie la différence, au prix de deux écritures à garder d'accord.

</div>

<!--
(40 s)

Première moitié de la réponse à la question directrice : combien de documents (un seul pour la page fréquente) et qui paie (l'écriture, avec ses risques). La suite (les mesures, la rétention, la forme des documents, puis la décision) vient aux deux autres temps.
-->

---

<!-- header: "" -->

## À vous : la séance 4

<style scoped>
.g2 > div { display: flex; flex-direction: column; gap: 0.6rem; }
.g2 > div > .orange { margin-top: auto; }
</style>

<div class="bandeau" style="font-size: 1em; padding: 0.45rem 1.2rem;">
<a href="https://iutinfoaix-r510.github.io/tp3/">iutinfoaix-r510.github.io/tp3</a> : accepter le TP3, puis <code>npm run seed</code>
</div>

<div class="g2" style="margin-top: 0.9rem; font-size: 0.78em; grid-template-columns: 1.1fr 1fr; align-items: stretch;">
<div>

1. Mise en place : **10 min**
2. Parties 1 à 3 : **50 min**
3. Point cours, puis partie 4 : **45 min**
4. Partie 5 : **35 min**
5. Point cours, puis partie 6 : **35 min**
6. Partie 7, **premier rendu** : **20 min**

<div class="carte orange">
<b class="t">📅 Rendu final du TP3</b>
dimanche 13 décembre 2026, 23&nbsp;h&nbsp;59
</div>

</div>
<div>

<div class="carte vert">
<b class="t">Les points</b>
12 exercices à 5 points, dont 1 en Java : 60 points, 8 % de la note.
</div>

<div class="carte orange">
<b class="t">Base abîmée ?</b>
<code>npm run seed</code>, puis rechargez les podcasts.
</div>

</div>
</div>

<!--
(1 min)

Fin du premier temps : 20 min de diapos, cette diapo et la suivante comprises.

Minutage de la séance : premier temps du point cours, 20 min ; mise en place, 10 min ; parties 1 à 3 (ex. 1 à 4), 50 min ; second temps (11 min) puis partie 4 (ex. 5 et 6), 45 min ; partie 5 (ex. 7 à 9), 35 min ; troisième temps (4 min) puis partie 6 (ex. 10 et 11), 35 min ; partie 7 (ex. 12) et le premier rendu, 20 min. Total : 3 h 35, il reste environ 25 minutes de marge. Les bonus prolongent en autonomie (la route Javalin est le bonus 8).

Trois rendus au plus : fin de séance 4, un rendu intermédiaire facultatif, puis le rendu final au plus tard le dimanche 13 décembre 2026 à 23 h 59. r510-rendre lance npm run check, puis rend ; r510-sauver sauvegarde sans noter. La mise en place comprend ./mvnw -q compile dans requetes-java/ (une à deux minutes au premier lancement). Les exercices portent sur les vélos, dans le playground ; les essais, sur les podcasts, dans essais.mongodb.js. Le minutage est indicatif, sur une séance de 4 h.

Rappeler : chaque réponse s'exécute seule, ligne use('tp3') comprise, par Ctrl+Alt+S ; jamais Ctrl+Alt+R, qui rejouerait toutes les écritures. Une écriture exécutée deux fois fausse la base de l'étudiant, pas sa note : npm run seed la remet à zéro.
-->

---

## Nouveau dans ce TP : le tuteur passe aux patterns

<style scoped>
.g3 { gap: 0.7em; align-items: stretch; }
.carte { font-size: 0.72em; }
</style>

<div class="g3" style="margin-top: 0.4rem;">
<div class="carte vert"><b class="t">🧠 approfondir-une-notion</b>

Un pattern ou un opérateur, expliqué sur les podcasts, avec ses pièges.

« Quelle différence entre le pattern Bucket et l'étape `$bucket` ? »

</div>
<div class="carte"><b class="t">❓ quiz-thematique</b>

Une question à la fin de chaque partie, corrigée et expliquée.

« Fais-moi un quiz pour choisir le bon pattern selon la situation. »

</div>
<div class="carte violet"><b class="t">📝 La note de modélisation</b>

Bonus 7 : justifier un modèle en dix lignes. Le tuteur vous **interroge** sur votre note ; il ne l'écrit pas.

</div>
</div>

<div class="box" style="margin-top: 0.8rem; font-size: 0.76em;">🧪 Les podcasts se chargent par le bloc de l'énoncé, dans <code>essais.mongodb.js</code> ; relancez-le après chaque <code>npm run seed</code>. <b>Jamais d'essai sous un <code style="white-space: nowrap;">// Votre réponse :</code>.</b></div>

<!--
(30 s)

Les deux skills du tuteur, dans .agents/skills/ du dépôt, adaptées au TP3 : leurs exemples et leurs quiz portent sur les podcasts, jamais sur les vélos, et ne montrent qu'une brique à la fois (jamais la combinaison d'un exercice). Pour l'exercice 9, le tuteur explique les mots-clés de $jsonSchema en mots et fait faire des essais d'insertion.

La note de modélisation (bonus 7) prépare les questions individuelles du projet, où l'on justifie un modèle sans assistant.

Les invites de quiz de l'énoncé, à la fin de chaque partie :
- partie 1 : « Fais-moi un quiz sur embarquer ou référencer, et le coût de $lookup. »
- partie 2 : « Fais-moi un quiz sur le pattern Subset, $topN, $push avec $slice et $merge. »
- partie 3 : « Fais-moi un quiz sur le pattern Computed et le recalcul par lot. »
- partie 4 : « Fais-moi un quiz sur le pattern Bucket, et sur ce qui le distingue de l'étape $bucket. »
- partie 5 : « Fais-moi un quiz sur les collections time series, les index TTL et les règles de validation $jsonSchema. »
- partie 6 : « Fais-moi un quiz pour choisir le bon pattern de conception selon la situation. »
- partie 7 : « Fais-moi un quiz sur la lecture d'un document et de ses tableaux avec le pilote Java. »
-->

---

<!-- header: Partie 4 · regrouper -->

<!-- _class: lead -->
<!-- _header: "" -->

# Reprise : partie 4 - 🪣 Le pattern Bucket

1 440 mesures par jour : un document chacune, ou un pour toutes ?

<!--
(10 s)

Début du second temps : à projeter quand la majorité du groupe attaque la partie 4 (exercices 5 et 6). Il couvre les parties 4, 5 et 7 ; la synthèse (partie 6) a son propre temps, plus tard.
-->

---

## Les capteurs de S2 : une journée par document

<style scoped>
.cols { align-items: stretch; }
.carte { font-size: 0.76em; }
</style>

<div class="dense">

```js
// S2 : un capteur, une journée de mesures, embarquée parce que bornée
{ _id: "C1", piece: "Salon", type: "temperature",
  mesures: [ { h: 8, v: 19.5 }, { h: 12, v: 21 }, { h: 18, v: 22.5 } ] }
```

</div>

Ici, le nombre d'auditeurs d'un épisode est relevé **chaque minute**, tous les jours :

<div class="cols" style="margin-top: 0.3rem;">
<div class="carte rouge"><b class="t">Une écoute, un document</b>
La courbe d'un jour lit <b>1 440</b> documents ; chacun répète l'épisode et prend une entrée dans chaque index.
</div>
<div class="carte rouge"><b class="t">Toutes les écoutes dans l'épisode</b>
Un tableau qui grandit <b>sans fin</b> : le critère « sans limite » de S2 l'interdit.
</div>
</div>

<!--
(40 s)

Le capteur C1 de S2 (étage omis) : une journée de mesures, embarquée parce que le tableau est borné. En S2, la note disait déjà : « pour garder plusieurs jours, un document par capteur et par jour, avec la date dans l'_id, par exemple "C1-2026-11-23" : c'est le pattern Bucket du TP3 ». Le voici.

Les deux extrêmes échouent, comme pour le Subset : ni un document par mesure, ni toutes les mesures dans un document. Le Bucket coupe la série en morceaux de taille bornée.
-->

---

## Un document par épisode et par jour

<img src="assets/schemas/s4-bucket.svg" alt="Le pattern Bucket sur les écoutes. À gauche, la collection ecoutes, une mesure par document : E1 le 7 septembre à 23 h 50 (40 auditeurs), E1 le 8 à 0 h 10 (35), E1 le 8 à 7 h 30 (52), E4 le 10 à 19 h (18), E4 le 10 à 19 h 30 (21). À droite, un document par épisode et par jour UTC : E1-2026-09-07 avec 1 mesure (nb 1, max 40), E1-2026-09-08 avec 2 mesures (nb 2, max 52), E4-2026-09-10 avec 2 mesures (nb 2, max 21). Chaque bucket a un _id lisible (épisode et jour), l'épisode, le jour, le nombre de mesures nb, le maximum max, et le tableau mesures trié par heure. Les deux premières écoutes de E1 ne vont pas dans le même bucket : le jour UTC change à minuit." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="warn" style="margin-top: 0.3rem; font-size: 0.72em;">

« Bucket » a **trois sens** : l'étape `$bucket` du TP2 (des tranches de valeurs) ; le **pattern** Bucket (ici) ; les **buckets internes** d'une collection time series (partie 5).

</div>

<!--
(50 s)

Lire écoute par écoute : la première écoute de E1 (23 h 50 le 7) part seule dans le bucket du 7 ; les deux suivantes, le 8, dans le bucket du 8. Les deux écoutes de E4 sont le même jour : un seul bucket.

Le Bucket combine deux idées déjà vues : un tableau borné embarqué (la période fixe une taille maximale : une journée a 1 440 minutes) et des valeurs calculées (Computed : nb et max, qui évitent même de parcourir le tableau). L'_id est fabriqué à partir de l'épisode et du jour : on retrouve un bucket sans le chercher.

Les trois documents sont ceux obtenus sur MongoDB 9.0.4 en regroupant ecoutes par épisode et par jour UTC ; le pipeline qui les construit n'est pas montré (c'est la forme de l'exercice 5). Ses briques sont sur les diapos suivantes, une à une, comme dans l'énoncé.

Trois sens du mot : l'étape $bucket range des documents existants dans des tranches au moment d'une requête ; le pattern change la forme des documents stockés ; les buckets internes sont invisibles et gérés par le serveur. Le schéma des trois sens est en annexe ; l'énoncé a le même encadré.
-->

---

## Fabriquer la clé d'un bucket, trier ses mesures

<div class="dense">

```js
db.episodes.aggregate([
  { $project: { cle: { $concat: ["$_id", "-",
      { $dateToString: { date: "$publie", format: "%Y-%m" } }] } } },
  { $limit: 2 } ])
// [ { _id: 'E1', cle: 'E1-2026-09' }, { _id: 'E2', cle: 'E2-2026-09' } ]

db.ecoutes.aggregate([
  { $group: { _id: "$episode", mesures: { $push: { t: "$t", auditeurs: "$auditeurs" } } } },
  { $project: { triees: { $sortArray: { input: "$mesures", sortBy: { auditeurs: -1 } } } } },
  { $sort: { _id: 1 } }, { $limit: 1 } ])
// [ { _id: 'E1', triees: [ { t: ISODate('2026-09-08T07:30:00.000Z'), auditeurs: 52 },
//                          { t: ISODate('2026-09-07T23:50:00.000Z'), auditeurs: 40 },
//                          { t: ISODate('2026-09-08T00:10:00.000Z'), auditeurs: 35 } ] } ]
```

</div>

<p class="petit" style="margin-top: 0.4rem;"><code>&#36;dateToString</code> écrit une date selon un format, <code>&#36;concat</code> colle des chaînes. <code>&#36;push</code> range les éléments dans l'ordre d'arrivée, que rien ne garantit : <code>&#36;sortArray</code> trie le tableau.</p>

<!--
(40 s)

Deux briques de l'énoncé (partie 4, « Fabriquer une clé, trier un tableau »), sur d'autres axes que l'exercice : une clé par épisode et par mois, des mesures triées par nombre d'auditeurs. Ne pas les assembler ici : c'est le travail de l'exercice 5. Les formats : %Y l'année, %m le mois, %d le jour.

Vérifié sur MongoDB 9.0.4 : les deux résultats affichés (mis en forme sur moins de lignes).
-->

---

## ❓ Dans quel jour tombe chaque écoute ?

<style scoped>
table { display: table; width: 100%; font-size: 0.8em; }
</style>

<div class="dense">

```js
db.ecoutes.aggregate([ { $match: { episode: "E1" } }, { $project: { _id: 0, t: 1,
  jourUTC: { $dateTrunc: { date: "$t", unit: "day" } },
  jourParis: { $dateTrunc: { date: "$t", unit: "day", timezone: "Europe/Paris" } } } } ])
```

</div>

| Écoute de E1 (`t`, en UTC) | `jourUTC` | `jourParis` |
|---|---|---|
| 7 septembre, 23 h 50 | ❓ | ❓ |
| 8 septembre, 0 h 10 | ❓ | ❓ |
| 8 septembre, 7 h 30 | ❓ | ❓ |

<p class="petit">Paris est à UTC+2 en septembre. Combien de jours différents, en UTC ? À Paris ?</p>

<!--
(20 s)

$dateTrunc a été vu en S3. Faire remplir le tableau à voix haute. Réponse sur la diapo suivante : deux jours en UTC, un seul à Paris.
-->

---

## Réponse : le jour dépend du fuseau

<style scoped>
table { display: table; width: 100%; font-size: 0.8em; }
</style>

| Écoute de E1 (`t`, en UTC) | `jourUTC` | `jourParis` |
|---|---|---|
| 7 septembre, 23 h 50 | **7** septembre, 0 h UTC | 7 septembre, **22 h UTC** (minuit à Paris) |
| 8 septembre, 0 h 10 | **8** septembre, 0 h UTC | 7 septembre, 22 h UTC |
| 8 septembre, 7 h 30 | 8 septembre, 0 h UTC | 7 septembre, 22 h UTC |

<div class="warn" style="margin-top: 0.6rem;">

Une même écoute change de bucket selon le **fuseau**. Dans le TP, un jour commence à **0 h UTC** (1 h du matin à Paris en novembre) : c'est `$dateTrunc` sans `timezone`.

</div>

<!--
(35 s)

Vérifié sur MongoDB 9.0.4 : jourParis vaut ISODate('2026-09-07T22:00:00.000Z') pour les trois écoutes, jourUTC 2026-09-07 pour la première et 2026-09-08 pour les deux autres.

Le choix du fuseau est une décision de modèle, comme la période : il faut le fixer une fois pour toutes et l'écrire dans la forme cible. L'énoncé fixe l'UTC.
-->

---

## Écrire une mesure dans son bucket

<img src="assets/schemas/s4-bucket-ecriture.svg" alt="Deux nouvelles écoutes arrivent, une à la fois. 1, E1 le 8 septembre à 12 h, 61 auditeurs : le bucket E1-2026-09-08 existe ; la mesure est ajoutée à la fin du tableau mesures, nb passe de 2 à 3, max de 52 à 61 (61 est plus grand). 2, E4 le 11 septembre à 7 h, 9 auditeurs : le bucket E4-2026-09-11 n'existe pas ; il est créé, avec episode et jour, nb: 1, max: 9 et un tableau d'une mesure. Une même écriture « trouve le bucket ou crée-le » : c'est un upsert (TP1)." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="bandeau" style="margin-top: 0.4rem;">Trouver le bucket, ou le créer : c'est un <b>upsert</b> (S1).</div>

<!--
(35 s)

Deux nouvelles écoutes, une à la fois. La première (E1, le 8 à 12 h, 61 auditeurs) trouve son bucket : la mesure va en fin de tableau, nb passe de 2 à 3, max de 52 à 61. La seconde (E4, le 11 à 7 h, 9 auditeurs) n'en trouve pas : le bucket est créé, avec l'épisode et le jour, nb: 1, max: 9 et un tableau d'une mesure.

Vérifié sur MongoDB 9.0.4 : les deux états « après » du schéma sont ceux obtenus à partir des buckets de la diapo « Un document par épisode et par jour » (E1-2026-09-08 : nb 3, max 61, trois mesures dans l'ordre des heures ; E4-2026-09-11 créé avec episode, jour, nb 1, max 9). Le code de cette écriture n'est pas montré : c'est l'exercice 6. Les opérateurs sont dans l'énoncé, un par un ; la diapo suivante montre $setOnInsert sur un autre exemple.
-->

---

## Créer le document s'il manque : `$setOnInsert`

<div class="dense">

```js
// la fiche d'une émission, créée au premier épisode publié
db.emissions.updateOne({ _id: "Sciences en poche" },
  { $set: { dernier: "E1" }, $setOnInsert: { creee: ISODate("2026-09-07T06:00:00Z") } },
  { upsert: true })
// 1re fois : upsertedCount: 1, puis findOne() :
//   { _id: 'Sciences en poche', creee: ISODate('2026-09-07T06:00:00.000Z'), dernier: 'E1' }
// 2e fois, avec dernier: "E2" et une autre date : matchedCount: 1, creee inchangée, dernier: 'E2'
```

</div>

<div class="err">

```text
db.emissions.updateOne({ _id: "Polar du soir" },
  { $set: { dernier: "E3" }, $setOnInsert: { dernier: "E1" } }, { upsert: true })
MongoServerError: Updating the path 'dernier' would create a conflict at 'dernier'
```

</div>

<p class="petit">Ce qui ne s'écrit qu'<b>à la création</b> va dans <code>&#36;setOnInsert</code>, et un même champ ne peut pas être dans deux opérateurs.</p>

<!--
(40 s)

Rappel de S1 (l'upsert du capteur du garage) : un filtre qui ne trouve rien crée le document, avec les champs du filtre, ceux de $set et ceux de $setOnInsert ; un filtre qui trouve met à jour, et $setOnInsert est ignoré. Le piège, en rouge : un même champ dans $set et dans $setOnInsert.

Vérifié sur MongoDB 9.0.4 : la première exécution renvoie upsertedCount: 1 et insertedId: 'Sciences en poche' ; la seconde ($set: { dernier: "E2" }, $setOnInsert: { creee: ISODate("2026-09-14T06:00:00Z") }) renvoie matchedCount: 1, modifiedCount: 1, et le document devient { _id: 'Sciences en poche', creee: ISODate('2026-09-07T06:00:00.000Z'), dernier: 'E2' }. L'erreur est recopiée de mongosh, préfixée « Uncaught » dans le shell.

$max et $min ne remplacent une valeur que si la nouvelle est plus grande, ou plus petite : l'exemple est dans l'énoncé (partie 4). Lien avec l'exercice 6 : chaque nouveau relevé dans son bucket, existant ou à créer, en une seule updateOne. Ne pas assembler les opérateurs ici.
-->

---

## Le prix du Bucket

<style scoped>
.g2 { gap: 0.6em; align-items: stretch; }
.carte { font-size: 0.72em; }
</style>

<div class="g2" style="margin-top: 0.3rem;">
<div class="carte vert"><b class="t">Ce qui devient simple</b>
La courbe d'un jour : <b>un</b> document. Le maximum du jour : un champ. Moins de documents, des index plus petits.
</div>
<div class="carte orange"><b class="t">Ce qui devient compliqué</b>
Une requête sur <b>une</b> mesure doit dérouler les tableaux (<code>&#36;unwind</code>). Corriger une mesure : la retrouver dans un tableau.
</div>
<div class="carte orange"><b class="t">Ce qu'il faut décider</b>
La période, le fuseau, l'<code>_id</code>, l'ordre du tableau, et le sort des mesures en retard.
</div>
<div class="carte"><b class="t">🚲 Dans le TP</b>
Ex. 5 : les buckets de la semaine, à côté de l'historique d'<code>occupation</code>. Ex. 6 : chaque nouveau relevé dans son bucket.
</div>
</div>

<div class="bandeau" style="margin-top: 0.7rem; font-size: 0.9em;">Et si le serveur faisait ce regroupement lui-même ?</div>

<!--
(35 s)

Quand l'utiliser : des mesures nombreuses, régulières, toujours lues par entité et par période. Les mesures en retard sont fréquentes avec des capteurs : l'upsert les range dans le bon bucket, mais $push les ajoute en fin de tableau ; si l'ordre compte, il faut écrire les relevés dans l'ordre des heures (l'exercice 6 le demande).

✍️ Questions de la partie 4, à garder pour la mise en commun (ne pas projeter) :
- un document par jour, parce que la lecture fréquente est la courbe d'un jour : par heure, la courbe lirait 24 documents ; par mois, un tableau de près de 3 000 relevés, toujours lu en entier ; la courbe d'une semaine lit 7 documents ;
- un relevé par seconde : 86 400 par jour, un tableau trop gros ; une période plus courte (l'heure), ou une collection time series.

Le bandeau amène la partie 5.
-->

---

<!-- header: Partie 5 · déléguer et garantir -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 5 - ⏱️ Séries temporelles, rétention et validation

Des mesures sans fin, des données périmées, des formes qui changent : qui s'en occupe, le serveur ou l'application ?

<!--
(10 s)

Même titre que la partie 5 de l'énoncé du TP3 (exercices 7 à 9).
-->

---

## Le bucket que le serveur écrit : une collection time series

<style scoped>
table { display: table; width: 100%; font-size: 0.7em; }
td, th { padding: 0.18em 0.6em; }
</style>

<div class="dense">

```js
// pour l'exemple : des écoutes relevées toutes les quelques heures
db.createCollection("ecoutes_ts",
  { timeseries: { timeField: "t", metaField: "episode", granularity: "hours" } });
db.ecoutes_ts.insertMany(db.ecoutes.find({}, { _id: 0 }).toArray());
db.getCollectionInfos({ name: "ecoutes_ts" })[0].options
// { timeseries: { timeField: 't', metaField: 'episode', granularity: 'hours',
//                 bucketMaxSpanSeconds: 2592000, fixedBucketing: true } }
```

</div>

| `granularity` | des mesures d'une même série espacées de… | un bucket interne couvre au plus |
|---|---|---|
| `"seconds"` (par défaut) | quelques secondes | 1 heure (3 600 s) |
| `"minutes"` | quelques minutes | 24 heures (86 400 s) |
| `"hours"` | quelques heures | 30 jours (2 592 000 s) |

<p class="petit">On écrit et on lit <b>une mesure par document</b> ; le serveur les range en <b>buckets internes</b>, par <code>metaField</code> et par tranche de temps. « Au plus » : un bucket interne n'est pas un jour du calendrier.</p>

<!--
(1 min)

C'est l'exemple de l'énoncé. Le vocabulaire de MongoDB : une mesure (measurement) a une date (timeField), une étiquette qui identifie la série et change rarement (metaField : l'épisode, la station, le capteur) et des valeurs. Les mesures sont compressées colonne par colonne dans chaque bucket interne. Le schéma de ce rangement, et les buckets internes tels que MongoDB les écrit, sont en annexe.

La granularité dit l'intervalle habituel entre deux mesures d'une même série ; MongoDB en déduit la durée maximale d'un bucket interne (bucketMaxSpanSeconds). Trop fine, elle multiplie les petits buckets ; trop grossière, une requête sur un jour lit des buckets d'un mois.

Vérifié sur MongoDB 9.0.4 : les options affichées ; avec seconds et minutes, bucketMaxSpanSeconds vaut 3600 et 86400. La nuance du bas, vérifiée avec minutes : les 3 écoutes de E1 (le 7 à 23 h 50, le 8 à 0 h 10 et 7 h 30) tiennent dans un seul bucket interne, dont control.min.t vaut ISODate('2026-09-07T23:00:00.000Z') : une tranche de 24 h au plus à partir d'une heure arrondie, qui chevauche minuit.

On y ajoute des mesures, on les lit, on les agrège ; on n'y modifie pas une mesure, et on n'y pose pas de règle de validation : les messages exacts sont en annexe.

✍️ Question de la partie 5, à garder pour la mise en commun (ne pas projeter) : le Bucket à la main ou la collection time series. Le pattern se corrige (une mise à jour dans un tableau) et accepte une règle $jsonSchema, mais il faut écrire l'upsert ; la collection time series demande le moins de code (un insertOne par mesure), mais une mesure s'y supprime et se réinsère, et elle refuse toute règle de validation.

Lien avec l'exercice 7 : choisir la granularité adaptée à des relevés toutes les 15 minutes. Ne pas la donner.
-->

---

## Les mesures s'accumulent : supprimer (TTL) ou déplacer ?

<style scoped>
.cols { align-items: stretch; }
.carte { font-size: 0.7em; }
</style>

<img src="assets/schemas/s4-ttl.svg" alt="Un index TTL sur une frise. Un brouillon d'épisode est modifié à 10 h (champ modifie). L'index { modifie: 1 } a expireAfterSeconds: 3600 : le document expire à 11 h. Le moniteur TTL, une tâche de fond, passe environ toutes les 60 secondes (traits verticaux) ; au premier passage après 11 h, il supprime le brouillon. Entre 11 h et ce passage, le document existe encore." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="cols" style="margin-top: 0.3rem;">
<div class="carte orange"><b class="t">Supprimer : un index TTL</b>

Ce qui ne vaut plus rien une fois périmé (un brouillon, une session). Le délai est en **secondes**, le champ doit être une **date**. Time series : l'option `expireAfterSeconds`.

</div>
<div class="carte violet"><b class="t">Déplacer : archiver</b>

Ce qu'on lit rarement mais qu'on doit garder : `$merge` vers une collection d'archives, puis `deleteMany`. La collection chaude reste petite.

</div>
</div>

<!--
(55 s)

La dernière ligne du tableau de charge : des brouillons inutiles une heure après leur dernière modification. Le schéma : un index TTL sur un champ date, avec un délai expireAfterSeconds ; un document expire quand sa date plus le délai est passée, et une tâche de fond, le moniteur TTL, le supprime à son passage suivant (environ toutes les 60 secondes, avec du retard sous forte charge). Une date écrite en chaîne n'expire jamais. L'index TTL porte sur un seul champ.

Vérifié sur MongoDB 9.0.4 : db.brouillons.createIndex({ modifie: 1 }, { expireAfterSeconds: 3600 }) renvoie 'modifie_1', et getIndexes() montre { v: 2, key: { modifie: 1 }, name: 'modifie_1', expireAfterSeconds: 3600 }.

Pour une collection time series, la rétention est une option de createCollection :
db.createCollection("ecoutes_recentes", { timeseries: { timeField: "t", metaField: "episode", granularity: "minutes" }, expireAfterSeconds: 86400 })
répond { ok: 1 } : MongoDB supprime un bucket interne entier quand toutes ses mesures ont expiré, si bien qu'une mesure peut durer un peu plus que le délai. Un index TTL ordinaire y est refusé (annexe). Recréer un index TTL avec un autre délai échoue (« An equivalent index already exists with the same name but different options ») : le supprimer d'abord, ou modifier le délai avec collMod.

Archiver (le pattern Archive, fusionné ici) : deux opérations sans atomicité ; entre le $merge et le deleteMany, une écoute existe deux fois ; un $merge relancé ne duplique pas (même _id).

✍️ Question de la partie 5, à garder pour la mise en commun (ne pas projeter) : une rétention sur releves ne touche pas aux buckets d'occupation, déjà construits ; ce qui a été calculé à partir des mesures (un bucket, un résumé) survit à ses sources, et il faut décider s'il doit expirer aussi.

Lien avec l'exercice 8 : un index TTL et une collection time series avec rétention, notés sur leur seule définition. Ne pas donner les délais en secondes.

Pour essayer : db.brouillons.insertOne({ _id: "B1", episode: "E4", modifie: new Date() }) ; le document disparaît une heure après sa date modifie.
-->

---

## La page suppose une forme de document : qui la garantit ?

<div class="cols-62" style="align-items: start;">
<div class="dense">

```js
db.nouveautes.insertOne({ titre: 12, format: "podcast" })
// { acknowledged: true, insertedId: ObjectId('…') }   accepté !

db.runCommand({ collMod: "nouveautes", validator: { $jsonSchema: {
  required: ["titre", "format"],
  properties: { titre: { bsonType: "string" } },
  oneOf: [
    { required: ["duree"],
      properties: { format: { enum: ["audio"] },
                    duree: { bsonType: "int", minimum: 1 } } },
    { required: ["definition"],
      properties: { format: { enum: ["video"] },
                    definition: { enum: ["720p", "1080p"] } } } ]
} } })
// { ok: 1 }
```

</div>
<div class="carte" style="font-size: 0.68em;"><b class="t">Une règle de validation</b>

La page d'un épisode lit son titre et son format. Un épisode à paraître est **audio** (avec sa durée) **ou vidéo** (avec sa définition).

- `required` : les champs présents
- `properties` : le schéma d'un champ, **s'il est là**
- `bsonType` : son type
- `enum` : les valeurs permises
- `oneOf` : **exactement un** des schémas (`anyOf` : au moins un)

</div>
</div>

<!--
(55 s)

La phrase-pont : chaque page suppose la forme du document qu'elle lit (un titre en chaîne, un format connu) ; MongoDB, lui, n'impose aucune forme. C'est ce qui permet de faire coexister deux formes d'un même objet, mais aussi d'insérer un document mal formé, comme le premier. Une règle de validation $jsonSchema décrit les documents acceptés ; elle se pose à la création (createCollection avec validator) ou, sur une collection qui existe déjà, par collMod. Un champ non cité dans properties reste permis.

C'est l'exemple de l'énoncé (section « Un garde-fou pour le schéma ») : deux formes d'un épisode, audio ou vidéo.

Pour rejouer : le premier insertOne crée la collection ; puis db.nouveautes.drop(); db.createCollection("nouveautes"); avant le collMod (sinon le document mal formé reste dans la collection : collMod ne vérifie pas les documents déjà là).

Vérifié sur MongoDB 9.0.4 : l'insertion sans règle est acceptée ; collMod répond { ok: 1 }.

Ne pas montrer, même sur les podcasts, comment interdire un champ ni comment décrire un tableau de documents : c'est l'exercice 9 (le tuteur a la même consigne). Les mots-clés not et items sont dans le tableau de l'énoncé, à lire.
-->

---

## ❓ Quatre insertions : lesquelles passent ?

<div class="dense">

```js
db.nouveautes.insertOne({ titre: "Les comètes", format: "audio", duree: 31 })              // 1
db.nouveautes.insertOne({ titre: "Les marées", format: "audio" })                          // 2
db.nouveautes.insertOne({ titre: "Volcans en images", format: "video", definition: "4K" }) // 3
db.nouveautes.insertOne({ titre: "Les abysses", format: "audio", duree: 40,
                          invitee: "Inès Valcourt" })                                      // 4
```

</div>

<div class="warn" style="margin-top: 0.6rem;">

**Prédire** : pour chaque insertion, acceptée ou refusée ? Et pour les refusées, quel schéma de `oneOf` a manqué, et pourquoi ?

</div>

<!--
(20 s)

Faire voter insertion par insertion. La quatrième est le piège : un champ que la règle ne cite pas reste permis. Réponse sur la diapo suivante.
-->

---

## Réponse : deux acceptées, deux refusées

<div class="dense">

```js
// 1 { acknowledged: true, insertedId: ObjectId('…') }
// 2 MongoServerError: Document failed validation   (audio, sans duree)
// 3 MongoServerError: Document failed validation   (video, mais definition hors de l'enum)
// 4 { acknowledged: true, insertedId: ObjectId('…') }   (invitee n'est pas cité : permis)
```

</div>

<div class="err">

```text
MongoServerError: Document failed validation
Additional information: { … propertyName: 'definition', details: [ { operatorName: 'enum',
  specifiedAs: { enum: [ '720p', '1080p' ] }, reason: 'value was not found in enum',
  consideredValue: '4K' } ] … }
```

</div>

<div class="bandeau" style="margin-top: 0.5rem; font-size: 0.82em;">Deux <b>versions</b> d'un même document cohabitent le temps d'une migration (Schema Versioning) : une règle peut accepter les deux, et rien d'autre. C'est l'exercice 9.</div>

<!--
(50 s)

Vérifié sur MongoDB 9.0.4 : les quatre réponses. Le message est le même pour tous les refus ; la raison est dans errInfo (« Additional information » dans mongosh), recopié ici en abrégé (les « … » remplacent le reste du détail) pour l'insertion 3 : le schéma vidéo échoue sur l'enum de definition, le schéma audio sur format et duree. Pour l'insertion 2 : le schéma audio échoue sur required (duree manquant), le schéma vidéo sur format et definition.

Autre piège vérifié : duree: 25.5 est refusé (« type did not match », consideredType: 'double') ; en mongosh, un entier comme 31 est envoyé en int. La règle s'applique aussi aux mises à jour : retirer duree à « Les comètes » répond « MongoServerError: Plan executor error during update :: caused by :: Document failed validation ».

Le bandeau relie la règle au Schema Versioning (annexe et bonus 4) en une phrase, sans montrer comment l'écrire : l'exercice 9 décrit les deux versions des abonnés, et l'étudiant combine lui-même les mots-clés.

✍️ Question de la partie 5, à garder pour la mise en commun (ne pas projeter) : une version 3 des abonnés ; d'abord une règle qui accepte les trois versions, puis le code qui lit (il doit comprendre la v3), puis le code qui écrit ; la règle ne se resserre qu'une fois la migration finie.
-->

---

<!-- header: Partie 7 · coder -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 7 - ☕ Du modèle au code

Comment lire un document, puis son tableau, sans `NullPointerException` ?

<!--
(10 s)

Même titre que la partie 7 de l'énoncé du TP3 (exercice 12 ; la route Javalin est le bonus 8). Projetée dans le second temps, avant la synthèse, pour que le second temps couvre toutes les parties « à construire » ; les étudiants la feront après la partie 6.
-->

---

## Lire un document, puis son tableau

<div class="dense">

```java
// le document, ou null
Document episode = episodes.find(Filters.eq("titre", "Les volcans")).first();
if (episode == null) {
    System.out.println("aucun épisode de ce titre");
} else {
    for (Document c : episode.getList("derniersCommentaires", Document.class, List.of())) {
        System.out.println(c.getString("auteur") + " : " + c.getInteger("note"));
    }
}
// sam : 5
// zoe : 3
```

</div>

<div class="cols" style="margin-top: 0.4rem;">
<div class="box">

**`first()`** termine une requête qui vise un seul document ; s'il n'y en a pas, `null`, à tester **avant** de s'en servir.

</div>
<div class="box">

**`getList`** lit un tableau de documents imbriqués. Sans le 3ᵉ argument, un champ **absent** donne `null`, et la boucle lève une `NullPointerException`.

</div>
</div>

<p class="petit" style="margin-top: 0.4rem;">🚲 Exercice 12 : les créneaux d'un bucket d'<code>occupation</code>. Bonus 8 : les servir par une route Javalin, avec un 404 si le bucket manque.</p>

<!--
(1 min)

Le pilote et ses classes d'aide sont ceux du TP2 ; la nouveauté est de lire un document précis et un tableau imbriqué. La méthode d'exemple station(id) de l'énoncé montre find(...).first().

Vérifié : ce code compile avec le pilote du TP3 (mongodb-driver-sync 5.14.0, ./mvnw -q compile dans une copie de requetes-java/), et s'exécute sur les podcasts après la diapo « $push borné » : « Les volcans » affiche sam : 5 puis zoe : 3 ; « Le sommeil », sans derniersCommentaires, n'affiche rien (List.of() évite la NullPointerException) ; un titre inconnu affiche « aucun épisode de ce titre ».

Exercice 12 : l'_id d'un document d'occupation se fabrique à partir de la station et du jour ; une projection évite de transférer le reste. Ne pas en dire plus.
-->

---

<!-- header: Séance 4 · second temps -->

## À retenir : regrouper, déléguer, garantir

<style scoped>
.g3 { gap: 0.7em; align-items: stretch; }
.carte { font-size: 0.72em; }
</style>

<div class="g3" style="margin-top: 0.3rem;">
<div class="carte"><b class="t">Bucket</b>

Un document par entité et par période, avec ses résumés. Le jour se coupe dans **un** fuseau ; l'upsert trouve ou crée le bucket.

</div>
<div class="carte vert"><b class="t">Time series et TTL</b>

Le serveur regroupe lui-même. Ce qui ne sert plus **expire** ; ce qu'on doit garder se **déplace**.

</div>
<div class="carte orange"><b class="t">Une règle <code>&#36;jsonSchema</code></b>

Un garde-fou posé par `collMod` : **plusieurs** formes permises, aucune autre.

</div>
</div>

<div class="bandeau" style="margin-top: 0.8rem; font-size: 0.86em;">

Et en Java : `first()` peut rendre `null`, `getList` aussi, sauf avec une valeur par défaut.

</div>

<!--
(35 s)

Fin du second temps (10 min 55). Reste la décision, relation par relation : elle a son propre temps, au début de la partie 6.
-->

---

<!-- header: Partie 6 · décider -->

<!-- _class: lead -->
<!-- _header: "" -->

# Reprise : partie 6 - 🧩 Synthèse : décider, puis la fiche station

Ni tout embarquer, ni tout référencer : quel rangement pour chaque relation ?

<!--
(10 s)

Troisième temps, court : à projeter quand la majorité du groupe attaque la partie 6 (exercices 10 et 11). Même titre que la partie 6 de l'énoncé du TP3.
-->

---

## Décider : cinq façons de ranger une relation

<style scoped>
table { display: table; width: 100%; font-size: 0.66em; }
td, th { padding: 0.2em 0.6em; }
</style>

| Choix | Ce que l'on range | Quand |
|---|---|---|
| `embarquer` | l'objet lié est un document imbriqué | toujours lu avec lui ; petit et borné ; non partagé |
| `referencer` | l'`_id` de l'objet lié, rangé dans sa propre collection | partagé par beaucoup de documents, ou modifié indépendamment |
| `sous-ensemble` | quelques éléments embarqués ; **tous** restent à part | une liste sans limite, dont on lit souvent une petite partie |
| `calcul` | une valeur dérivée, calculée **à l'écriture** | lue bien plus souvent qu'elle ne change |
| `bucket` | des mesures **regroupées** par entité et par période | des mesures très nombreuses, lues par période |

<div class="box" style="margin-top: 0.5rem; font-size: 0.74em;">

🚲 **Exercice 10** : un choix par relation du tableau de l'énoncé, à partir des questions de la partie 1 (fréquence, lecture conjointe, taille, croissance, partage). Tout ou rien.

</div>

<!--
(40 s)

C'est le tableau de l'énoncé (« Ranger une relation : cinq façons »), qui ouvre la synthèse. Les deux premières viennent de S2 ; les trois suivantes sont les patterns des parties 2 à 4. Les cinq formes de document correspondantes, dessinées sur les podcasts, sont en annexe.

Ne donner aucun choix de l'exercice 10 : faire relire les colonnes « Ce que l'application en fait » et « Taille et croissance » du tableau de l'énoncé. Deux relations peuvent avoir le même choix. Le champ justification (non noté) est un bon entraînement aux questions individuelles.
-->

---

## ❓ Quatre situations : quel rangement ?

<style scoped>
.g2 { gap: 0.7em; align-items: stretch; }
.carte { font-size: 0.74em; }
</style>

<div class="g2" style="margin-top: 0.3rem;">
<div class="carte"><b class="t">A. Une messagerie</b>
La liste des conversations affiche le <b>dernier message</b> de chacune ; une conversation en compte des milliers.
</div>
<div class="carte"><b class="t">B. Une émission</b>
Sa page affiche sa <b>durée totale d'écoute</b>, lue 10 000 fois par jour ; elle change à chaque écoute.
</div>
<div class="carte"><b class="t">C. Une station météo</b>
Elle envoie la <b>température</b> chaque minute ; l'application trace la courbe d'une journée.
</div>
<div class="carte"><b class="t">D. Un épisode</b>
Ses <b>2 ou 3 intervenants</b> (nom, rôle), affichés sur sa page ; ils ne changent plus après la publication.
</div>
</div>

<div class="warn" style="margin-top: 0.6rem; font-size: 0.76em;">

Pour chacune : **quel symptôme**, puis **quel rangement** ? Deux minutes, à deux.

</div>

<!--
(45 s)

Une discrimination entrelacée : quatre situations courtes, sur d'autres objets que le TP, et la même question. Laisser deux minutes à deux (hors minutage si la salle en a besoin), puis faire répondre une table par situation. Réponses sur la diapo suivante.
-->

---

## Réponse : le symptôme désigne le pattern

<style scoped>
table { display: table; width: 100%; font-size: 0.72em; }
</style>

| | Le symptôme | Le rangement |
|---|---|---|
| A | une liste sans fin, dont une page fréquente lit un élément | **sous-ensemble** (Subset) |
| B | une valeur dérivée, lue bien plus souvent qu'elle ne change | **calcul** (Computed) |
| C | des mesures très nombreuses, lues par période | **bucket**, ou une collection **time series** |
| D | peu d'éléments, bornés, lus avec leur document | **embarquer** : aucun pattern |

<div class="box" style="margin-top: 0.6rem; font-size: 0.76em;">

Et deux garde-fous : des données qui ne servent plus → un index **TTL** ; une forme de document à garantir → une règle **`$jsonSchema`**.

</div>

<!--
(30 s)

Faire justifier chaque ligne par le symptôme, pas par le nom du pattern. D est là pour rappeler qu'un pattern sans symptôme complique pour rien : la plupart des relations s'embarquent ou se référencent simplement.

Pour C, les deux réponses sont justes : une collection time series si l'on n'a besoin ni de résumés rangés ni d'un schéma imposé ; le pattern écrit à la main si la page lit un document par période, prêt, avec ses résumés.

C'est aussi un bon quiz à demander au tuteur : « Fais-moi un quiz pour choisir le bon pattern de conception selon la situation. »
-->

---

## Et les autres patterns ? Un symptôme, un nom, un bonus

<style scoped>
table { display: table; width: 100%; font-size: 0.7em; }
</style>

| Le symptôme | Le pattern | Dans le TP3 |
|---|---|---|
| une jointure fréquente pour lire un ou deux champs qui changent rarement | **Référence étendue** | — |
| des dizaines de champs rares, tous à indexer | **Attribute** | bonus 1 |
| quelques documents énormes imposent un modèle mauvais pour tous | **Outlier** | bonus 2 |
| des objets voisins mais pas identiques, interrogés ensemble | **Polymorphic** | bonus 3 |
| le schéma évolue sans tout migrer d'un coup | **Schema Versioning** | bonus 4, et l'ex. 9 |

<div class="bandeau" style="margin-top: 0.6rem; font-size: 0.88em;">Chacun a sa fiche en <b>annexe</b>, après les Crédits : avant, après, prix.</div>

<!--
(30 s)

La carte des patterns hors du noyau : on la projette pour que les noms soient connus, et on renvoie à l'annexe (non projetée) pour les bonus 1 à 4. La Référence étendue répond au coût de $lookup de la partie 1 : garder l'_id et recopier un ou deux champs lus souvent.

Archive est fusionné avec « supprimer ou déplacer » (partie 5). CQRS est coupé : c'est une architecture, pas un pattern MongoDB.
-->

---

## La fiche : un document, trois patterns

<img src="assets/schemas/s4-synthese.svg" alt="La fiche d'un épisode, lue par la page à chaque ouverture, assemble trois patterns dans un seul document. Le titre et l'émission viennent de l'épisode. nbCommentaires vient du pattern Computed (compté à l'écriture). derniersCommentaires vient du pattern Subset (les plus récents). derniereJournee (le jour, le maximum d'auditeurs) vient du pattern Bucket (le résumé du dernier bucket). Trois flèches partent des collections episodes, commentaires et ecoutes_par_jour vers la fiche. En bas : une lecture, un document, aucune jointure ; trois sources à tenir à jour." style="display:block; width:100%; margin:0.2rem auto 0;">

<p class="petit" style="margin-top: 0.3rem;">Un document fait pour <b>une page</b> : tout ce qu'elle affiche, rien d'autre, sans jointure. 🚲 <b>Exercice 11</b> : la fiche d'une station, en une seule agrégation.</p>

<!--
(35 s)

La fiche assemble les trois patterns dans un seul document, lu à chaque ouverture de la page : le compteur (Computed), les derniers commentaires (Subset), le résumé du dernier bucket (Bucket). Une lecture, un document, aucune jointure ; trois sources à tenir à jour.

Exercice 11 : les avis ne sont pas encore dans la station (le correcteur automatique part des données de départ), il faut les joindre ; l'énoncé donne les opérateurs dans son indice ($sortArray, $slice, $first, $map). L'annexe montre $first et $slice sur un tableau déjà dans le document. Ne pas les assembler ici.

Une fiche assemblée à part est un modèle de lecture, séparé du modèle d'écriture. Pousser cette idée jusqu'au bout donne une architecture, CQRS (un modèle pour écrire, un pour lire), qui n'est pas un pattern MongoDB : on ne la traite pas.

✍️ Questions de la partie 6, à garder pour la mise en commun (ne pas projeter) : à chaque nouvel avis, il faut écrire avis, la station (sous-ensemble) et, si elle est tenue à jour à l'écriture, la fiche ; fiches reconstruite par lot, par un pipeline terminé par $merge ou $out, c'est le recalcul par lot de la partie 3 (une vue matérialisée).
-->

---

<!-- header: Séance 4 · troisième temps -->

## À retenir : décider, relation par relation

<style scoped>
.g2 { gap: 0.6em; align-items: stretch; }
.carte { font-size: 0.74em; }
</style>

<div class="g2" style="margin-top: 0.3rem;">
<div class="carte violet"><b class="t">Décider</b>
Partir du <b>symptôme</b> : embarquer, référencer, sous-ensemble, calcul ou bucket. Sans symptôme, pas de pattern.
</div>
<div class="carte vert"><b class="t">Assembler</b>
Une page fréquente lit <b>un</b> document fait pour elle : plusieurs patterns dans une même fiche.
</div>
</div>

<div class="bandeau" style="margin-top: 0.8rem; font-size: 0.86em;">

Une page lue cent fois plus qu'elle n'est écrite lit **un** document. L'écriture paie la différence, et le modèle, décidé relation par relation, dit qui la paie.

</div>

<!--
(35 s)

Réponse finale à la question directrice. Combien de documents : un, pour la page fréquente. Qui paie la différence : l'écriture, une fois, avec ses risques (deux écritures à garder d'accord, une dérive à contrôler, des mesures à faire expirer, une forme à garantir), et c'est le modèle, décidé relation par relation, qui répartit ce coût.
-->

---

<!-- header: "" -->
<!-- _class: lead -->

# Des questions ?

**Sébastien Nedjar** (GA1) · **Leïla Sakli Miled** (GA2)
IUT d'Aix-Marseille, département Informatique

<div style="margin-top: 1.2rem; font-size: 0.85em;">

[iutinfoaix-r510.github.io/tp3](https://iutinfoaix-r510.github.io/tp3/)
sebastien.nedjar@univ-amu.fr · leila.SAKLI@univ-amu.fr

</div>

<div class="bandeau" style="margin-top: 1.6rem; text-align: left; font-size: 0.92em;">

🎯 **Dès maintenant**, en sortant : finir les exercices, faire le quiz de chaque partie, rédiger la note de modélisation (bonus 7), puis le rendu final avec <code style="white-space: nowrap;">r510-rendre</code> avant le **dimanche 13 décembre, 23&nbsp;h&nbsp;59**.

</div>

<!--
(10 s)

Questions sur le cours : en séance, ou par courriel à l'enseignant de son groupe ; après la séance, une issue sur le dépôt syllabus.
-->

---

## Crédits

<div class="petit">

**Ce support** : R5.Real.10, IUT d'Aix-Marseille, sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Exemples (podcasts) écrits pour ce cours ; tous exécutés sur MongoDB 9.0.4.

**Données du TP** : le réseau de vélos de Valcerise, ville et données inventées pour ce cours (`data/PROVENANCE.md` du TP3).

**Pour aller plus loin** : [modélisation des données](https://www.mongodb.com/docs/manual/data-modeling/) · [charge de travail](https://www.mongodb.com/docs/manual/data-modeling/schema-design-process/identify-workload/) · [patterns de conception](https://www.mongodb.com/docs/manual/data-modeling/design-patterns/) · W. Zola, [*6 Rules of Thumb for MongoDB Schema Design*](https://www.mongodb.com/company/blog/mongodb/6-rules-of-thumb-for-mongodb-schema-design) · D. Coupal et K. W. Alger, [*Building with Patterns*](https://www.mongodb.com/company/blog/building-with-patterns-a-summary) · [`$merge`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/merge/) · [time series](https://www.mongodb.com/docs/manual/core/timeseries-collections/) · [index TTL](https://www.mongodb.com/docs/manual/core/index-ttl/) · [validation de schéma](https://www.mongodb.com/docs/manual/core/schema-validation/) · [transactions](https://www.mongodb.com/docs/manual/core/transactions/)

</div>

<!--
(Hors minutage : diapo de référence, laissée en fin de support.)

Ce support ne reprend ni ne reformule aucun contenu de MongoDB for Academia : ses exemples (podcasts) et ses schémas (assets/schemas/s4-*.svg) sont faits pour ce cours. La démarche en trois étapes et le catalogue des patterns viennent de la documentation et du blog de MongoDB (Coupal et Alger), les tailles de relation et le « un-à-sans-fin » de William Zola : ce sont des idées citées, pas des passages recopiés. Pour les étudiants qui consultent les présentations officielles de MongoDB for Academia : « Data Modeling and Schema Design Patterns » traite embarquer ou référencer et les patterns Polymorphic, Schema Versioning, Attribute, Bucket et Subset.
-->

---

<!-- header: Annexe -->
<!-- _class: lead -->
<!-- _header: "" -->

# Annexe

Les schémas de référence, les autres patterns (bonus 1 à 4), les limites d'une collection time series, une transaction exécutée

<!--
(Hors minutage : l'annexe n'est pas projetée. Elle reste dans le PDF et en ligne : l'énoncé du TP3 y renvoie pour les bonus 1 à 4, « des patterns que le point cours décrit ».)

Tout y a été exécuté sur MongoDB 9.0.4, sur les podcasts, sauf la transaction, exécutée sur un replica set à un nœud.
-->

---

## Un mot, trois sens

<img src="assets/schemas/s4-trois-buckets.svg" alt="Trois sens du mot bucket, en trois colonnes. 1, l'étape $bucket du TP2 : elle répartit des documents en tranches de valeurs (les films de 0 à 90 minutes, de 90 à 120) ; c'est une étape de pipeline, elle ne change pas la base. 2, le pattern Bucket (cette partie) : un document par entité et par période (un épisode, un jour) contient les mesures de cette période ; c'est un modèle que l'on écrit soi-même. 3, les buckets internes d'une collection time series (partie 5) : MongoDB regroupe lui-même les mesures, sans qu'on les voie ; c'est un rangement du serveur." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="bandeau" style="margin-top: 0.5rem;">Dans ce cours, « bucket » seul désigne le pattern. Les deux autres disent toujours « l'étape <code>&#36;bucket</code> » ou « les buckets internes ».</div>

<!--
La confusion est fréquente et légitime : les trois parlent de « ranger dans des seaux ». L'étape $bucket du TP2 range des documents existants dans des tranches au moment d'une requête ; le pattern change la forme des documents stockés ; les buckets internes sont invisibles et gérés par le serveur. L'énoncé a le même encadré (« Trois sens du mot bucket »).
-->

---

## Cinq façons de ranger une relation, dessinées

<img src="assets/schemas/s4-rangements.svg" alt="Cinq façons de ranger une relation, chacune avec la forme de document qu'elle produit, sur les podcasts. Embarquer : l'épisode contient un document imbriqué (ses intervenants). Référencer : le commentaire contient episode: &quot;E1&quot;, l'_id de l'épisode, rangé ailleurs. Sous-ensemble : l'épisode contient ses 2 derniers commentaires, et tous les commentaires restent dans leur collection. Calcul : l'épisode contient nbCommentaires: 3, calculé à chaque écriture. Bucket : un document par épisode et par jour contient le tableau des mesures d'écoute de ce jour." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="box" style="margin-top: 0.4rem; font-size: 0.76em;">

Les deux premières viennent de S2. Les trois suivantes sont les **patterns** des parties 2 à 4 : ni tout embarquer, ni tout référencer.

</div>

<!--
Chaque façon de ranger, avec la forme de document qu'elle produit, sur les podcasts : E1 avec ses intervenants (embarquer), un commentaire et l'_id de son épisode (référencer), E1 et ses 2 derniers commentaires (sous-ensemble), son compteur (calcul), un bucket d'écoutes par jour (bucket). Le tableau de la synthèse dit quand choisir chacune.
-->

---

## Une collection time series, vue de l'intérieur

<img src="assets/schemas/s4-timeseries.svg" alt="Une collection time series. À gauche, ce que l'on écrit et ce que l'on lit : une mesure par document, comme dans une collection ordinaire (E1 le 7 septembre à 23 h 50, 40 auditeurs ; E1 le 8 à 0 h 10, 35 ; E1 le 8 à 7 h 30, 52 ; E4 le 10 à 19 h, 18 ; E4 le 10 à 19 h 30, 21). À droite, ce que MongoDB range en interne : des buckets, un par valeur du metaField (l'épisode) et par tranche de temps, avec la granularité hours. Le bucket de E1 garde ses 3 mesures : control.min { t: 7 septembre 0 h, auditeurs: 35 }, control.max { t: 8 septembre 7 h 30, auditeurs: 52 }, count: 3, et data, les mesures rangées par colonne et compressées. Le bucket de E4 garde 2 mesures : min { t: 10 septembre 0 h, auditeurs: 18 }, max { t: 10 septembre 19 h 30, auditeurs: 21 }, count: 2. Au milieu : MongoDB regroupe seul, à l'écriture ; il découpe à la lecture." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="box" style="margin-top: 0.4rem; font-size: 0.74em;">

On écrit et on lit **une mesure par document** ; MongoDB les range lui-même en **buckets internes**, par valeur du `metaField` et par tranche de temps. Ne pas y ranger des documents déjà regroupés : ce serait perdre le regroupement interne.

</div>

<!--
Les deux buckets du schéma sont ceux obtenus sur MongoDB 9.0.4 avec la collection ecoutes_ts (granularité hours) : les 3 écoutes de E1 tiennent dans un seul bucket interne, là où le pattern en faisait deux (un par jour). La diapo « Les buckets internes, vus de près » les montre tels que MongoDB les range (rawData). La documentation de MongoDB le dit : ne pas utiliser le pattern Bucket dans une collection time series.
-->

---

## Lire dans un tableau : `$first`, `$slice`

<div class="dense">

```js
db.episodes.aggregate([ { $match: { _id: "E3" } },
  { $project: { _id: 0,
      dernier: { $first: "$derniersCommentaires" },
      moinsBien: { $slice: [ { $sortArray: { input: "$derniersCommentaires",
                                             sortBy: { note: 1 } } }, 1 ] } } } ])
// [ { dernier: { auteur: 'sam', note: 5, date: ISODate('2026-09-23T19:30:00.000Z') },
//     moinsBien: [ { auteur: 'zoe', note: 3, date: ISODate('2026-09-22T12:15:00.000Z') } ] } ]
```

</div>

<div class="box" style="margin-top: 0.5rem; font-size: 0.78em;">

Des **opérateurs d'expression**, sur un tableau déjà dans le document : `$first` donne le premier élément, `$slice` en garde les `n` premiers, `$sortArray` trie avant. À ne pas confondre avec les accumulateurs `$first` et `$push` de `$group`.

</div>

<!--
Sur le sous-ensemble de E3 (diapo « $push borné »). Vérifié sur MongoDB 9.0.4 : le résultat affiché (mis en forme sur moins de lignes). L'indice de l'exercice 11 cite ces opérateurs.
-->

---

## Référence étendue : recopier ce qui ne bouge pas

<div class="cols dense" style="grid-template-columns: 1fr 1fr; align-items: start;">
<div>

<p class="etiquette">Avant : la référence seule</p>

```js
// commentaires
{ _id: "K1", episode: "E1", auteur: "lou", note: 5 }
// pour afficher le titre de l'épisode :
// une jointure à chaque fois
```

</div>
<div>

<p class="etiquette">Après : la référence et une copie</p>

```js
// commentaires
{ _id: "K1", episode: "E1", auteur: "lou", note: 5,
  titreEpisode: "Les trous noirs" }
```

</div>
</div>

<div class="box" style="margin-top: 0.4rem; font-size: 0.74em;">

On garde l'`_id` (la référence) et on recopie **un ou deux champs** lus souvent et **rarement modifiés** : la jointure de la partie 1 disparaît. Le prix : une copie à mettre à jour si le titre change. Une copie peut aussi être **voulue** : le prix d'un article figé dans une commande.

</div>

<!--
Le TP1 l'utilisait sans la nommer : le titre du livre recopié dans l'historique des emprunts d'un membre. Ne jamais recopier un champ qui change souvent (un stock, un nombre d'écoutes). Pas de bonus dans le TP3.
-->

---

## Attribute : des champs rares en paires `{ k, v }`

<div class="cols dense" style="grid-template-columns: 0.85fr 1.15fr; align-items: start;">
<div>

<p class="etiquette">Avant : un champ par propriété</p>

```js
{ _id: "E1", langue: "fr",
  explicite: false, saison: 2 }
{ _id: "E4", langue: "fr",
  narrateur: "Inès Valcourt" }
// un index par champ : langue,
// explicite, saison, narrateur…
// et tous les prochains
```

</div>
<div>

<p class="etiquette">Après : un tableau, un seul index</p>

```js
{ _id: "E1", proprietes: [ { k: "langue", v: "fr" },
  { k: "explicite", v: false }, { k: "saison", v: 2 } ] }
db.episodes.createIndex({ "proprietes.k": 1,
                          "proprietes.v": 1 })
db.episodes.find({ proprietes:
  { $elemMatch: { k: "langue", v: "fr" } } }, { titre: 1 })
// [ { _id: 'E1', titre: 'Les trous noirs' },
//   { _id: 'E4', titre: 'La disparue de Vernon' } ]
```

</div>
</div>

<p class="petit">Le plan utilise l'index <code>proprietes.k_1_proprietes.v_1</code> (IXSCAN). <code>&#36;elemMatch</code> (S2) garantit que <code>k</code> et <code>v</code> viennent du même élément.</p>

<!--
E4 a de même proprietes: [ { k: "langue", v: "fr" }, { k: "narrateur", v: "Inès Valcourt" } ]. Vérifié sur MongoDB 9.0.4 : le résultat et le plan (IXSCAN sur l'index composé, isMultiKey: true, bornes ["langue", "langue"] et ["fr", "fr"]). Bonus 1 : les caractéristiques variables des vélos électriques et cargos.
-->

---

## Outlier : ne pas modéliser pour l'exception

<div class="dense">

```js
{ _id: "E1", titre: "Les trous noirs", commentaires: [ /* au plus 50 */ ] }
{ _id: "E9", titre: "L'épisode viral", commentaires: [ /* les 50 plus récents */ ],
  debordement: true }    // les autres sont dans commentaires_debordement
```

</div>

<div class="box" style="margin-top: 0.5rem; font-size: 0.76em;">

Le modèle embarque les commentaires de chaque épisode, 50 au plus : il convient à 99 % des épisodes. Un épisode **viral** en reçoit 10 000. On garde le modèle fait pour le **cas courant**, et on **signale** l'exception par un champ (`debordement: true`) : l'application ne va chercher la suite que pour les documents marqués. Le prix : deux chemins de code.

</div>

<!--
Exemple classique des sources : le livre à succès dont la liste d'acheteurs dépasserait 16 Mo. Le drapeau est un booléen, pas une chaîne. Forme seule, non exécutée. Bonus 2 : les stations très commentées des données du TP.
-->

---

## Polymorphic : des formes voisines dans une collection

<div class="dense">

```js
// contenus : trois types, des champs communs (titre) et propres (duree, debut, places)
{ _id: "C1", type: "episode", titre: "Les trous noirs", duree: 32 }
{ _id: "C2", type: "bande-annonce", titre: "Saison 2", duree: 1, pourEmission: "Sciences en poche" }
{ _id: "C3", type: "direct", titre: "Questions des auditeurs",
  debut: ISODate("2026-10-01T18:00:00Z"), places: 200 }
db.contenus.find({ $or: [ { type: "episode", duree: { $gte: 30 } }, { type: "direct" } ] },
                 { titre: 1, type: 1 })
// [ { _id: 'C1', type: 'episode', titre: 'Les trous noirs' },
//   { _id: 'C3', type: 'direct', titre: 'Questions des auditeurs' } ]
```

</div>

<div class="box" style="margin-top: 0.4rem; font-size: 0.74em;">

Une **seule** collection, un champ **discriminant** (`type`) : « tous les contenus » se lit sans jointure. En SQL, une table par type, ou une table pleine de colonnes vides. À ne pas confondre avec Attribute : ici, ce sont les **documents** qui ont des formes différentes.

</div>

<!--
Pour essayer : contenus n'est pas dans le script des podcasts ; un insertMany des trois documents affichés la crée. Vérifié sur MongoDB 9.0.4 : le résultat affiché. Bonus 3 : les vélos mécaniques, électriques et cargos, dans la même collection.
-->

---

## Schema Versioning : faire évoluer sans tout migrer

<div class="dense">

```js
// auditeurs : deux versions du schéma cohabitent
{ _id: "A1", nom: "Lou Martin", ville: "Lyon" }                                       // version 1
{ _id: "A2", versionSchema: 2, prenom: "Sam", nom: "Petit", adresse: { ville: "Brest" } }
db.auditeurs.aggregate([ { $project: {
  ville: { $ifNull: ["$adresse.ville", "$ville"] },
  version: { $ifNull: ["$versionSchema", 1] } } } ])
// [ { _id: 'A1', ville: 'Lyon', version: 1 }, { _id: 'A2', ville: 'Brest', version: 2 } ]
```

</div>

<div class="box" style="margin-top: 0.4rem; font-size: 0.74em;">

Un champ `versionSchema` dit la forme du document ; l'application lit **toutes** les versions, et migre un document **quand elle l'écrit** (migration paresseuse), sans `ALTER TABLE` ni arrêt de service. Une règle de validation peut accepter les deux versions pendant la migration (exercice 9).

</div>

<!--
S1 l'annonçait : faire évoluer un schéma reste du travail, même sans ALTER TABLE. Le travail est dans l'application, qui doit comprendre chaque version.

Pour essayer : auditeurs n'est pas dans le script des podcasts ; un insertMany des deux documents affichés la crée. Vérifié sur MongoDB 9.0.4 : le résultat affiché. Bonus 4 : la migration de l'abonné AB001, sous la règle de l'exercice 9 si elle est posée.
-->

---

## Ce qu'une collection time series refuse

<style scoped>
table { display: table; width: 100%; font-size: 0.68em; }
</style>

| Essai sur `ecoutes_ts` | Réponse de MongoDB 9.0.4 |
|---|---|
| `updateOne({ episode: "E1" }, { $set: { auditeurs: 0 } })` | `Cannot perform a non-multi update on a time-series collection` |
| `updateMany({ episode: "E1" }, { $set: { auditeurs: 0 } })` | `Cannot perform an update on a time-series collection which updates a field that is not the metaField 'episode'` |
| `runCommand({ collMod: "ecoutes_ts", validator: … })` | `option not supported on a time-series collection: validator` |
| un pipeline terminé par `$merge` vers `ecoutes_ts` | `Cannot find index to verify that join fields will be unique: Timeseries collections cannot have unique indexes` |
| `createIndex({ t: 1 }, { expireAfterSeconds: 60 })` | `TTL indexes on time-series collections require a partialFilterExpression on the metaField` |

<div class="box" style="margin-top: 0.5rem; font-size: 0.74em;">

**Permis** : insérer, lire, agréger, supprimer une mesure (`deleteOne`), remplir par `insertMany` ou par `$out` avec l'option `timeseries`. Une mesure ne se corrige pas : elle se supprime, puis se réinsère.

</div>

<!--
Tous les messages sont recopiés de MongoDB 9.0.4 ; le dernier, sur la collection ecoutes_recentes, créée dans les notes de la diapo « Les mesures s'accumulent : supprimer (TTL) ou déplacer ? ». Une collection time series est faite pour des mesures qu'on ajoute et qu'on ne touche plus. C'est la même liste que dans l'énoncé (partie 5).
-->

---

## Les buckets internes, vus de près

<div class="dense">

```js
db.runCommand({ find: "ecoutes_ts", rawData: true, filter: { meta: "E4" } }).cursor.firstBatch
// [ { _id: ObjectId('6aa1f300bcabcf62fb598070'),
//     control: { version: 2,
//       min: { t: ISODate('2026-09-10T00:00:00.000Z'), auditeurs: 18, _id: … },
//       max: { t: ISODate('2026-09-10T19:30:00.000Z'), auditeurs: 21, _id: … },
//       count: 2 },
//     meta: 'E4',
//     data: { auditeurs: Binary.createFromBase64(…), t: Binary.createFromBase64(…), _id: … } } ]
```

</div>

<style scoped>
table { display: table; width: 100%; font-size: 0.72em; }
</style>

| Bucket interne | `meta` | `control.min.t` | `control.count` | `control.max.auditeurs` | `data` |
|---|---|---|---|---|---|
| Pattern Bucket (partie 4) | `episode` | `jour` (arrondi) | `nb` | `max` | `mesures` (en colonnes compressées) |

<!--
La commande find avec rawData: true lit les buckets internes tels que MongoDB les range ; c'est un outil d'observation, pas une requête d'application. L'ancien accès par system.buckets.ecoutes_ts est refusé en 9.0 (« Direct access to timeseries buckets namespaces is not allowed anymore… Use the rawData API »).

Vérifié sur MongoDB 9.0.4 : la sortie affichée, abrégée (les « … » remplacent les _id des mesures et le contenu des colonnes Binary) ; db.runCommand({ count: "ecoutes_ts", rawData: true }) donne n: 2 (2 buckets internes pour 5 mesures). La borne control.min.t est arrondie au début du jour pour la granularité hours, au début de l'heure pour minutes.
-->

---

## Une transaction, sur un *replica set*

<div class="dense">

```js
// départ : les podcasts, E1 avec ses 3 commentaires et nbCommentaires: 3
const session = db.getMongo().startSession();
const s = session.getDatabase("tp3");
session.startTransaction();
s.commentaires.insertOne({ _id: "K9", episode: "E1", auteur: "noe", note: 4,
                          date: ISODate("2026-09-12T10:00:00Z") });
s.episodes.updateOne({ _id: "E1" }, { $inc: { nbCommentaires: 1 } });
session.commitTransaction();                 // les deux écritures, ou aucune
db.episodes.findOne({ _id: "E1" }, { _id: 0, titre: 1, nbCommentaires: 1 })
// { titre: 'Les trous noirs', nbCommentaires: 4 }

session.startTransaction();
s.commentaires.insertOne({ _id: "K10", episode: "E1", auteur: "lou", note: 1,
                          date: ISODate("2026-09-12T11:00:00Z") });
s.commentaires.countDocuments({ episode: "E1" })   // 5, vu de la transaction
db.commentaires.countDocuments({ episode: "E1" })  // 4, vu du reste de la base
session.abortTransaction();                  // K10 n'a jamais existé
db.commentaires.findOne({ _id: "K10" })
// null
```

</div>

<div class="err">

```text
MongoServerError: This MongoDB deployment does not support retryable writes.
Please add retryWrites=false to your connection string.
```

</div>

<!--
Le schéma « Une panne entre deux écritures » (partie 3) montre le problème ; voici la transaction qui le résout.

Vérifié sur MongoDB 9.0.4, dans un conteneur lancé en replica set à un nœud (mongod --replSet rs0, puis rs.initiate()), à partir des podcasts et de nbCommentaires: 3 posé sur E1 : la transaction validée donne nbCommentaires: 4 ; pendant la seconde, la session compte 5 commentaires sur E1 et le reste de la base 4 (isolation : les écritures en cours ne se voient pas du dehors) ; la transaction annulée ne laisse aucune trace de K10.

En rouge : la réponse du MongoDB du codespace (un serveur seul), dès la première écriture dans la transaction (« Uncaught » en tête dans mongosh). Les exercices n'en ont pas besoin. Les transactions existent depuis MongoDB 4.0 (2018) ; une transaction dure au plus 60 secondes par défaut.
-->

---

## Quel pattern, pour quel symptôme ? Le tableau complet

<style scoped>
table { display: table; width: 100%; font-size: 0.66em; }
td, th { padding: 0.16em 0.6em; }
</style>

| Le symptôme | La réponse |
|---|---|
| une page fréquente lit une liste sans fin pour en afficher quelques éléments | **Subset** |
| une valeur dérivée est recalculée à chaque lecture | **Computed** |
| des mesures nombreuses, une par document, lues par période | **Bucket** ou collection **time series** |
| des données qui ne servent plus au bout d'un délai | index **TTL** |
| des années d'historique ralentissent les données récentes | **Archive** : déplacer |
| une forme de document à garantir | règle **`$jsonSchema`** |
| une jointure fréquente pour lire un ou deux champs qui changent rarement | **Référence étendue** |
| des dizaines de champs rares, tous à indexer | **Attribute** |
| quelques documents énormes imposent un modèle mauvais pour tous | **Outlier** |
| des objets proches mais pas identiques, interrogés ensemble | **Polymorphic** |
| le schéma doit évoluer sans tout migrer d'un coup | **Schema Versioning** |

<!--
Se lit de gauche à droite : on part toujours du symptôme. Pour réviser, cacher la colonne de droite et retrouver la réponse ; c'est aussi un bon quiz à demander au tuteur du codespace.
-->
