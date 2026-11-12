---
marp: true
theme: r510
paginate: true
lang: fr
title: "Séance 2 : documents imbriqués, tableaux et premiers pipelines"
description: "R5.Real.10, point cours de la séance 2 (TP1, parties 5 à 7)"
---


<!-- _class: lead -->
<!-- _paginate: false -->

<style scoped>
section {
  background-image: url('assets/logo.png');
  background-repeat: no-repeat;
  background-position: bottom 40px center;
  background-size: 380px;
}
h1 { font-size: 1.9em; }
</style>

# Documents imbriqués, tableaux et premiers pipelines

**R5.Real.10 - Nouveaux paradigmes de base de données**

Séance 2 · TP1, parties 5 à 7 · semaine du 23 novembre 2026

<!--
(Hors minutage : plan des temps du point cours.)

Question directrice de la séance : « Tout un livre tient dans un document : comment l'interroger, le modifier, puis en tirer des statistiques ? »

Le point cours se fait en deux temps, comme le prévoit l'énoncé (questions de modélisation avant la partie 5, second temps avant la partie 7).

Premier temps, en début de séance, 15 min 50 de diapos : diapos 2 à 6 (objectifs et médiathèque, 5 minutes), puis les questions de modélisation (5 minutes à deux, 3 minutes de mise en commun : 8 minutes hors minutage des diapos), puis les parties 5 et 6 (diapos 7 à 20, 10 min 20) et « À retenir » (diapo 21, 30 s). La diapo 22 (« À vous ») lance le travail : 1 minute. Ce premier temps dure 24 min 50 en tout.

Second temps, quand la majorité du groupe attaque la partie 7 : diapos 23 à 36, 12 min 40, plus 10 s pour « Des questions ? » (diapo 37).

Le cours seul dure 29 min 40 (somme des durées notées en tête de chaque diapo, « À vous » et « Des questions ? » compris), pour 37 diapos projetées. Si le temps manque : les diapos 13 (projeter) et 34 (le pipeline complet et le SQL) se lisent vite, l'énoncé les reprend ; l'annexe (après les Crédits, 6 diapos, dont le pipeline document par document) n'est pas projetée.

Les exemples portent sur deux jeux de données, pas sur ceux du TP : les films de la séance 1, enrichis d'un document imbriqué (realisation) et d'un tableau de documents (seances), et cinq capteurs. Tout a été exécuté sur MongoDB 9.0.4, et les résultats affichés sont ceux obtenus. Le script qui recharge chaque jeu est dans les notes de la diapo qui le présente (diapos 8 et 24). Pour rejouer en direct, le coller dans essais.mongodb.js : les démos tournent dans une base à part, demo (use('demo')), que le correcteur automatique ne lit pas, et chaque script commence par vider sa collection : on peut le relancer avant chaque essai.
-->

---

<!-- header: Séance 2 · objectifs -->

## Tout un livre tient dans un document

<div class="bandeau" style="font-size: 0.9em;">

❓ Comment l'**interroger**, le **modifier**, puis en tirer des **statistiques** ?

</div>

<div class="g2" style="margin-top: 0.9rem; font-size: 0.78em; align-items: stretch;">
<div class="carte vert">
<b class="t">🎯 À la fin de la séance, vous saurez</b>

1. **lire** un modèle document, et dire ce que coûte une donnée recopiée ;
2. **interroger** des documents imbriqués et des tableaux (partie 5) ;
3. **modifier** un élément précis d'un tableau, et deux documents liés (partie 6) ;
4. **construire** un pipeline d'agrégation, étape par étape (partie 7).

</div>
<div class="carte">
<b class="t">Déjà vu en séance 1</b>

- `find` et ses opérateurs : `$gt`, `$in`, `$exists`, `$regex` ;
- projection, `sort`, `limit` ;
- `updateOne`, `updateMany` : `$set`, `$inc`, `$push`, `$pull`, `$unset` ;
- l'upsert ;
- les films : `_id`, `titre`, `annee`, `duree`, `genres`.

</div>
</div>

<!--
(1 min)

Lire la question directrice : elle donne les trois temps de la séance, dans l'ordre des parties 5, 6 et 7. On y répond dans les deux diapos « À retenir ».

Les objectifs reprennent les niveaux « Analyser » (ex. 26 à 38) et « Créer » (ex. 39 à 43) de l'énoncé.

« Déjà vu » : tout ce qui sert ce matin a été vu en séance 1 sur les films ; on garde les mêmes films, qui vont s'enrichir. $push et $pull ont été vus sur des tableaux de valeurs (prix, genres) : ils reviennent en partie 6 sur un tableau de documents.
-->

---

<!-- header: Séance 2 · la médiathèque -->

## La fiche d'un livre, en SQL

<div class="cols" style="grid-template-columns: 1fr 1.5fr; align-items: center;">
<div class="petit">

L'énoncé part de **neuf tables** : `livres`, `auteurs`, `livre_auteur`, `categories`, `livre_categorie`, `exemplaires`, `membres`, `emprunts`, `avis`.

Afficher la fiche de Dune, avec ses auteurs, ses exemplaires et ses avis :

</div>
<div class="dense">

```sql
SELECT l.titre, a.nom, e.code, v.note
FROM livres l
JOIN livre_auteur la ON la.livre_id = l.id
JOIN auteurs a       ON a.id = la.auteur_id
JOIN exemplaires e   ON e.livre_id = l.id
LEFT JOIN avis v     ON v.livre_id = l.id
WHERE l.id = 'L06';
-- 9 lignes : 1 auteur × 3 exemplaires × 3 avis
```

</div>
</div>

<div class="cols" style="margin-top: 0.8rem;">
<div class="warn">

**Quatre jointures**, et une fiche éclatée en 9 lignes, que l'application doit recoller.

</div>
<div class="box">

**En MongoDB**, on range ensemble ce qui se lit ensemble : la fiche tient dans **un** document.

</div>
</div>

<!--
(1 min)

Le besoin d'abord : c'est le paragraphe « En SQL » de la section « Modéliser la médiathèque » de l'énoncé.

La requête a été exécutée sur SQLite avec les données de Dune (1 auteur, 3 exemplaires, 3 avis) : elle renvoie 9 lignes, le produit des deux relations un-à-plusieurs. Le titre et l'auteur y sont répétés 9 fois. Avec les catégories, il faudrait deux jointures de plus.

Transition : voici la même fiche, rangée comme un document.
-->

---

## La médiathèque : deux collections

<img src="assets/schemas/s2-mediatheque-structure.svg" alt="Structure des deux collections. livres : _id, titre, annee ; auteurs, tableau de documents ; categories, tableau ; serie, document imbriqué facultatif ; exemplaires, tableau de documents dont chaque élément peut contenir emprunt_actuel, document imbriqué de troisième niveau avec membre_id qui référence un membre ; avis, tableau facultatif de documents avec membre_id. membres : _id, prenom, nom, ville, inscription ; parrain_id, référence facultative vers un membre ; emprunts, tableau de documents avec exemplaire, livre_id qui référence un livre, titre, dates et date_retour facultative. Un emprunt en cours est écrit deux fois : dans le livre et dans le membre." style="display:block; width:93%; margin:0.2rem auto 0 auto;">

<p class="petit" style="margin-top: 0.3rem;">Les neuf tables tiennent en <b>deux collections</b>. Auteurs, exemplaires et avis sont <b>embarqués</b> dans le livre ; <code>membre_id</code>, <code>livre_id</code> et <code>parrain_id</code> sont des <b>références</b>.</p>

<!--
(1 min)

Données du TP : on les présente, on ne les interroge pas ici. Lire la structure avant de lire un document.

Les couleurs disent la forme de chaque champ : orange pour les tableaux (auteurs, categories, exemplaires, avis, emprunts), bleu pour le document imbriqué serie, violet pour emprunt_actuel, un document imbriqué dans un élément du tableau exemplaires, soit un troisième niveau. Le point d'interrogation signale un champ facultatif. Les flèches grises sont des références : un identifiant qui renvoie à un document d'une autre collection (ou de la même, pour parrain_id).

Pour les dates, le TP1 fixe sa date de référence au 15 novembre 2026 (encadré « Tableaux et dates » de la partie 5) : jamais la date du jour. Les dates de la médiathèque sont à minuit UTC.

Même dépôt, même playground, même base tp1 qu'en séance 1. Les exercices de la séance 2 ne dépendent pas des réponses de la séance 1 : le correcteur automatique part toujours de l'état attendu. Au TP4, la même médiathèque passe dans Neo4j.
-->

---

## Un emprunt écrit deux fois : voulu, mais pas gratuit

<img src="assets/schemas/s2-mediatheque.svg" alt="Un des 26 documents de la collection livres : _id L06, titre Dune, annee 1965 ; auteurs, un tableau de documents, avec l'auteur A04, Frank Herbert ; categories, le tableau [ Science-Fiction ] ; serie, un document imbriqué { nom: Dune, tome: 1 } ; exemplaires, un tableau de documents : l'exemplaire L06-1, état Bon, disponible false, porte emprunt_actuel, un document imbriqué de troisième niveau avec membre_id M12, date_emprunt et date_retour_prevue ; l'exemplaire L06-2, état Neuf, disponible true, n'en a pas ; avis, un tableau de documents, dont celui du membre M01 avec la note 5. Un des 14 documents de la collection membres : _id M12, Tom Lambert ; emprunts, un tableau de documents, dont l'emprunt de l'exemplaire L06-1, titre Dune : le même emprunt que dans le livre." style="display:block; height:515px; margin:0 auto;">

<p class="petit centre" style="margin-top: 0.2rem;">L'emprunt de <code>L06-1</code> est <b>dans le livre et dans le membre</b>. C'est voulu ; on verra ce qu'il coûte en partie 6.</p>

<!--
(45 s)

Faire lire le document de Dune à voix haute, en retrouvant la structure de la diapo précédente : la fiche de la diapo SQL est là, entière, sans jointure.

Puis montrer les deux encadrés violets : le même emprunt en cours est écrit dans exemplaires.emprunt_actuel du livre et dans emprunts du membre (sans date_retour). Le titre du livre est aussi recopié chez le membre.

Ne pas dire ici ce que chaque copie rend simple, ni ce qui se passe si une seule écriture réussit : c'est la question de modélisation 3. On y revient à la fin de la partie 6 (diapo « Un document : tout ou rien »).
-->

---

## Embarquer ou référencer : les critères de l'énoncé

<style scoped>
table { width: 100%; font-size: 0.68em; }
td, th { padding: 0.2em 0.6em; }
</style>

| Situation | Choix |
|---|---|
| Relation un-à-plusieurs avec peu d'éléments, et un nombre borné (un livre a quelques exemplaires) | Embarquer |
| Données presque toujours lues ensemble | Embarquer |
| Un nombre d'éléments grand ou sans limite (toutes les mesures d'un capteur) | Référencer |
| Données modifiées souvent, indépendamment du document parent | Référencer |

<img src="assets/schemas/s2-relations.svg" alt="Trois sortes de relations, dont la 1-N en deux cas, et le choix le plus courant : 1-1, une personne et son adresse postale, embarquer le document ; 1-N avec peu d'éléments, un client et ses adresses de livraison, embarquer un tableau ; 1-N sans limite, un capteur et ses mesures, référencer avec l'_id du capteur dans chaque mesure ; N-N, des étudiants et des cours, un tableau d'_id d'un côté ou des deux." style="display:block; width:92%; margin:0.3rem auto 0 auto;">

<div class="warn" style="font-size: 0.72em; margin-top: 0.2rem;">

✍️ **Questions de modélisation** de l'énoncé : **5 min à deux**, réponses dans le bloc prévu du playground (non notées).

</div>

<!--
(1 min 15)

Le tableau est celui de l'énoncé (section « Modéliser la médiathèque »), mot pour mot : c'est la liste commune à toutes les séances (S3, S4 et S5 la reprendront telle quelle).

Le schéma décline les cardinalités : 1-1 et 1-N bornée, on embarque ; 1-N sans limite, on référence (l'_id du parent dans chaque enfant) ; N-N, un tableau d'_id d'un côté ou des deux. Pour le N-N, ne pas donner d'exemple sur les livres et les auteurs : c'est la question de modélisation 2.

Puis laisser vraiment les 5 minutes aux questions de modélisation de l'énoncé, à deux, et 3 minutes de mise en commun (hors minutage), sur les questions 1 à 3 seulement ; les questions 4 et 5 restent ouvertes jusqu'au TP4. Ne pas projeter de réponse. Éléments à faire sortir pendant la mise en commun, pas avant :
- Q1 : un livre a quelques exemplaires, lus avec lui (lignes 1 et 2 du tableau) ; on changerait d'avis si les exemplaires devenaient très nombreux, ou modifiés sans cesse indépendamment du livre (lignes 3 et 4).
- Q2 : embarquer, c'est parfois recopier : le nom d'un auteur vit dans chacun de ses livres, et un changement doit toucher toutes les copies (un updateMany, autant de documents que de livres de l'auteur).
- Q3 : la copie du livre dit qui a l'exemplaire ; celle du membre donne son historique sans lire livres. Si une seule écriture réussit, les deux copies se contredisent : partie 6.
- La duplication existe en SQL (dénormalisation), mais ici elle est un choix courant. Un document BSON ne dépasse pas 16 Mo : un tableau qui grandit sans fin finit par bloquer. https://www.mongodb.com/docs/manual/reference/limits/
-->

---

<!-- header: Partie 5 · interroger -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 5 - 🔎 Interroger des documents imbriqués et des tableaux

Comment atteindre un champ rangé **dans** un document imbriqué ou **dans** un tableau ?

<!--
(10 s)

Même titre que la partie 5 de l'énoncé du TP1 (ex. 26 à 32).
-->

---

## Les films de la séance 1, enrichis

<div class="dense">

```js
{ _id: "F01", titre: "Le Voyage de Chihiro", annee: 2001, duree: 125,
  genres: ["animation", "fantastique"],
  realisation: { nom: "Miyazaki", pays: "Japon" },                   // document imbriqué
  seances: [                                                         // tableau de documents
    { salle: 1, date: ISODate("2026-11-27"), libres: 0 },
    { salle: 2, date: ISODate("2026-11-28"), libres: 12 },
    { salle: 1, date: ISODate("2026-11-29"), libres: 40, evenement: "ciné-débat" } ] }
```

</div>

<style scoped>
table { font-size: 0.66em; width: 100%; }
td, th { padding: 0.15em 0.6em; }
</style>

| `_id` | titre | realisation | seances : salle (date, places libres) |
|---|---|---|---|
| F02 | Mon voisin Totoro | Miyazaki, Japon | 2 (28/11, 30) · 3 (29/11, 8) |
| F03 | La Haine | Kassovitz, France | 1 (28/11, 5) |
| F04 | Les Glaneurs et la Glaneuse | Varda, France | aucune : `[]` |
| F05 | Amélie Poulain | Jeunet, France | 1 (28/11, 0) · 3 (29/11, 25) |

<div class="box" style="font-size: 0.74em;">

❓ **À vous de prédire** : que renvoie `db.films.find({ realisation: { nom: "Miyazaki" } })` ?

</div>

<!--
(45 s)

Les mêmes films qu'en séance 1, avec deux champs de plus : realisation, un document imbriqué, et seances, un tableau de documents. Ce sont les deux formes de la médiathèque (serie, exemplaires), sur d'autres données. Au TP2 (séance 3), la réalisation sortira du film pour devenir une référence vers une collection realisateurs.

Laisser répondre la salle avant de passer à la diapo suivante : la plupart répondent « Chihiro et Totoro ».

Script de rechargement, à coller dans essais.mongodb.js (jamais dans le playground noté, jamais sur livres ou membres). Il repart des cinq films de la séance 1 ; le film inséré sans _id en séance 1 (Le Dîner de cons) n'est pas repris. Les mises à jour de la partie 6 partent toutes de cet état : relancer le script avant chaque essai.

use('demo');
db.films.deleteMany({});
db.films.insertMany([
  { _id: "F01", titre: "Le Voyage de Chihiro", annee: 2001, duree: 125,
    genres: ["animation", "fantastique"],
    realisation: { nom: "Miyazaki", pays: "Japon" },
    seances: [ { salle: 1, date: ISODate("2026-11-27"), libres: 0 },
               { salle: 2, date: ISODate("2026-11-28"), libres: 12 },
               { salle: 1, date: ISODate("2026-11-29"), libres: 40, evenement: "ciné-débat" } ] },
  { _id: "F02", titre: "Mon voisin Totoro", annee: 1988, duree: 86,
    genres: ["animation"],
    realisation: { nom: "Miyazaki", pays: "Japon" },
    seances: [ { salle: 2, date: ISODate("2026-11-28"), libres: 30 },
               { salle: 3, date: ISODate("2026-11-29"), libres: 8 } ] },
  { _id: "F03", titre: "La Haine", annee: 1995, duree: 98,
    genres: ["drame"],
    realisation: { nom: "Kassovitz", pays: "France" },
    seances: [ { salle: 1, date: ISODate("2026-11-28"), libres: 5 } ] },
  { _id: "F04", titre: "Les Glaneurs et la Glaneuse", annee: 2000, duree: 82,
    genres: ["documentaire"],
    realisation: { nom: "Varda", pays: "France" },
    seances: [] },
  { _id: "F05", titre: "Amélie Poulain", annee: 2001, duree: 122,
    genres: ["comédie", "romance"],
    realisation: { nom: "Jeunet", pays: "France" },
    seances: [ { salle: 1, date: ISODate("2026-11-28"), libres: 0 },
               { salle: 3, date: ISODate("2026-11-29"), libres: 25 } ] }
]);

Sans sort, l'ordre des résultats n'est pas garanti : ceux des diapos suivantes sont dans l'ordre obtenu sur MongoDB 9.0.4.
-->

---

## Le réflexe de la séance 1 ne trouve rien

<div class="dense">

```js
db.films.find({ realisation: { nom: "Miyazaki" } })                 // []
db.films.find({ realisation: { nom: "Miyazaki", pays: "Japon" } })  // titres : Chihiro, Totoro
db.films.find({ realisation: { pays: "Japon", nom: "Miyazaki" } })  // []
db.films.find({ "realisation.nom": "Miyazaki" })                    // titres : Chihiro, Totoro
```

</div>

<img src="assets/schemas/s2-egalite-ou-champ.svg" alt="Lignes 1 à 3 : le filtre { realisation: { ... } } compare le document imbriqué entier du Voyage de Chihiro, nom: Miyazaki puis pays: Japon. Ligne 1, pays absent : pas de résultat. Ligne 2, identique : résultat. Ligne 3, ordre inversé : pas de résultat. Ligne 4 : realisation.nom ne teste que nom et ignore pays : un seul champ testé, presque toujours le bon choix." style="display:block; width:100%; max-height:300px; margin:0.4em auto 0 auto;">

<p class="petit" style="margin-top: 0.3rem;"><code>"realisation.nom"</code> : la <b>notation pointée</b>. Un document écrit en entier dans un filtre demande une égalité <b>exacte</b>.</p>

<!--
(1 min)

Réponse à la prédiction : aucun film. En séance 1, { champ: valeur } suffisait parce que la valeur était simple. Ici la valeur est un document : MongoDB compare le document imbriqué entier, champ par champ, dans l'ordre. La troisième ligne surprend toujours : les deux mêmes champs, dans un autre ordre, et plus aucun résultat.

Les quatre requêtes ont été exécutées sur MongoDB 9.0.4, avec la projection { _id: 0, titre: 1 }, omise pour la lisibilité ; les commentaires abrègent les titres obtenus (Le Voyage de Chihiro, Mon voisin Totoro).

L'encadré WARNING de la partie 5 de l'énoncé signale ce piège ; c'est lui qui motive la notation pointée.
-->

---

## La notation pointée : un chemin dans le document

<div class="cols" style="align-items: center;">
<div>

<img src="assets/schemas/s2-notation-pointee.svg" alt="Arbre du film F01 : le chemin realisation.pays descend dans le document imbriqué realisation jusqu'à pays, qui vaut Japon ; le chemin seances.libres traverse le tableau seances et vise le champ libres de chaque séance (0, 12 et 40)." style="display:block; width:100%; margin:0 auto;">

</div>
<div class="petit">

- On enchaîne les noms de champ : `"a.b.c"`, sur autant de niveaux qu'il faut.
- **À travers un tableau**, le chemin vise le champ de chaque élément : **un seul** élément qui convient suffit.
- Ça marche aussi dans `sort` et dans la projection.

</div>
</div>

<p style="margin: 1rem 0 0;"><b>Guillemets obligatoires</b> autour d'un chemin :</p>

<div class="err">

```text
db.films.find({ realisation.nom: "Miyazaki" })
SyntaxError: Unexpected token, expected "," (1:27)
```

</div>

<!--
(45 s)

Lire le schéma : en vert, un chemin dans un document imbriqué ; en orange, un chemin qui traverse un tableau. { "seances.libres": 0 } est vrai pour Chihiro, parce qu'une de ses trois séances est complète.

L'erreur vient de JavaScript, avant même d'atteindre le serveur : sans guillemets, realisation.nom est lu comme un accès à une propriété, pas comme une clé. Elle se produit à l'identique dans mongosh et dans le playground (message obtenu dans mongosh 2.x avec MongoDB 9.0.4).

Renvoi : ex. 27 et 29 de la partie 5 (un chemin, parfois sur trois niveaux).
-->

---

## Un tableau écrit en entier : égalité exacte, ordre compris

<p class="petit" style="margin: 0 0 0.3rem;">Les films d'animation, puis ceux qui sont à la fois fantastiques et d'animation :</p>

```js
db.films.find({ genres: "animation" })                             // titres : Chihiro, Totoro
db.films.find({ genres: ["animation"] })                           // titres : Totoro
db.films.find({ genres: ["fantastique", "animation"] })            // []
db.films.find({ genres: { $all: ["fantastique", "animation"] } })  // titres : Chihiro
db.films.find({ genres: { $in: ["drame", "documentaire"] } })      // titres : La Haine, Glaneurs
```

<div class="g2" style="margin-top: 1rem;">
<div>

- Une **valeur** : le tableau la **contient**.
- Un **tableau** : égalité **exacte**, ordre compris, comme pour un document imbriqué.

</div>
<div>

- `$all` : **toutes** ces valeurs, dans n'importe quel ordre.
- `$in` (séance 1) : **au moins une**.

</div>
</div>

<!--
(45 s)

Projection { _id: 0, titre: 1 } omise ; les commentaires abrègent les titres obtenus sur MongoDB 9.0.4 (Les Glaneurs et la Glaneuse).

Même piège que sur la diapo précédente : un tableau écrit en entier dans le filtre demande une égalité exacte, ordre compris. Totoro sort à la ligne 2 parce que son tableau vaut exactement ["animation"] ; Chihiro non, il a un genre de plus.

$size (nombre exact d'éléments) et "tab.0" (l'élément d'indice 0) sont dans l'annexe.
-->

---

## Une séance en salle 1 avec des places : deux conditions

<style scoped>
.cols { align-items: stretch; }
.cols > div:first-child p { margin: 0.1em 0 0.2em; }
</style>

<div class="cols">
<div class="dense">

**Deux conditions séparées**

```js
db.films.find({ "seances.salle": 1,
                "seances.libres": { $gt: 0 } })
// titres : Chihiro, La Haine, Amélie Poulain
```

**`$elemMatch` : un même élément**

```js
db.films.find({ seances: { $elemMatch:
    { salle: 1, libres: { $gt: 0 } } } })
// titres : Chihiro, La Haine
```

<p class="petit">Deux conditions qui doivent porter sur <b>la même</b> séance : <code>&#36;elemMatch</code>.</p>

</div>
<div>

<img src="assets/schemas/s2-elemmatch.svg" alt="Les deux séances d'Amélie Poulain : salle 1, 0 place libre ; salle 3, 25 places libres. Avec deux conditions séparées, salle: 1 est vraie pour la première séance et libres > 0 pour la seconde : Amélie Poulain est renvoyé. Avec $elemMatch, aucune séance ne vérifie les deux : Amélie Poulain est écarté." style="display:block; width:100%; max-height:440px; margin:0 auto;">

</div>
</div>

<!--
(1 min)

Partir de la question : « un film qu'on peut voir en salle 1 ce week-end ». La première requête est la traduction naïve, avec deux chemins pointés. Amélie Poulain sort alors qu'aucune de ses séances ne convient : sa séance en salle 1 est complète, et sa séance avec des places est en salle 3. Chaque condition a trouvé son élément.

Résultats obtenus sur MongoDB 9.0.4, projection { _id: 0, titre: 1 } omise.

C'est la note de la partie 5 de l'énoncé (« deux conditions sur un tableau de documents... »). $elemMatch sert aussi dans le filtre d'une mise à jour : partie 6, diapo « La mauvaise séance ».
-->

---

## On ne veut que la séance trouvée, et le pays à plat

<div class="cols">
<div class="dense">

**`seances: 1` : tout le tableau revient**

```js
db.films.find({ seances: { $elemMatch:
    { salle: 1, libres: { $gt: 0 } } } },
  { _id: 0, titre: 1, seances: 1 })
// Chihiro revient avec ses 3 séances
```

**`"seances.$": 1` : la séance trouvée**

```js
  { _id: 0, titre: 1, "seances.$": 1 })
// [ { titre: 'Le Voyage de Chihiro',
//     seances: [ { salle: 1,
//       date: ISODate('2026-11-29T00:00:00.000Z'),
//       libres: 40, evenement: 'ciné-débat' } ] },
//   { titre: 'La Haine',
//     seances: [ { salle: 1,
//       date: ISODate('2026-11-28T00:00:00.000Z'),
//       libres: 5 } ] } ]
```

</div>
<div class="dense">

**`"realisation.pays": 1` : l'imbrication reste**

```js
db.films.find({ _id: "F01" },
  { _id: 0, titre: 1, "realisation.pays": 1 })
// [ { titre: 'Le Voyage de Chihiro',
//     realisation: { pays: 'Japon' } } ]
```

**`"$realisation.pays"` : le champ remonte**

```js
db.films.find({ _id: "F01" },
  { _id: 0, titre: 1, pays: "$realisation.pays" })
// [ { titre: 'Le Voyage de Chihiro',
//     pays: 'Japon' } ]
```

<p class="petit"><code>"tab.&#36;"</code> garde le <b>premier</b> élément qui a satisfait le filtre.</p>

</div>
</div>

<!--
(45 s)

Le besoin d'abord : on reprend la requête $elemMatch de la diapo précédente, avec la projection { titre: 1, seances: 1 }. Chihiro revient avec ses trois séances (le commentaire résume la sortie), alors qu'une seule convient. "seances.$" ne garde que celle-là. À droite, même démarche pour le pays : la projection pointée le laisse dans realisation ; pour l'avoir au premier niveau, on écrit une expression.

Les requêtes ont été exécutées sur MongoDB 9.0.4 ; les sorties sont recopiées, seuls les retours à la ligne ont été regroupés.

L'expression "$realisation.pays" dans la projection de find est décrite à la fin de la section « La notation pointée » de l'énoncé. Le "$" en tête d'une chaîne veut dire « la valeur de ce champ » : on retrouvera cette écriture dans les pipelines de la partie 7.

La projection positionnelle garde le premier élément qui a satisfait le filtre : le filtre doit donc porter sur ce même tableau. Contre-exemple, si le temps le permet : avec les deux conditions séparées de la diapo précédente, la même projection renvoie pour Chihiro la séance en salle 2 (libres: 12), qui ne vérifie qu'une condition, et pour Amélie Poulain sa séance en salle 3. Vérifié sur MongoDB 9.0.4 ; la documentation ne garantit d'ailleurs pas quel élément est gardé dans ce cas.
-->

---

<!-- header: Partie 6 · modifier -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie 6 - 🔧 Modifier des documents imbriqués et des tableaux

Comment changer **un** champ, **un** élément précis, et que coûte une donnée écrite deux fois ?

<!--
(10 s)

Même titre que la partie 6 de l'énoncé du TP1 (ex. 33 à 38).
-->

---

## Ajouter le prénom du réalisateur : pointé ou remplacé ?

<div class="dense">

```js
db.films.updateOne({ _id: "F03" }, { $set: { realisation: { prenom: "Mathieu" } } })
// { acknowledged: true, insertedId: null, matchedCount: 1, modifiedCount: 1, upsertedCount: 0 }
db.films.findOne({ _id: "F03" }, { _id: 0, realisation: 1 })
// { realisation: { prenom: 'Mathieu' } }
```

</div>

<img src="assets/schemas/s2-set-pointee.svg" alt="Deux écritures de $set sur La Haine. Avant : realisation vaut { nom: Kassovitz, pays: France }. Avec $set sur realisation.prenom, le champ prenom: Mathieu s'ajoute, nom et pays restent. Avec $set sur realisation, le document imbriqué entier est remplacé : il ne reste que prenom: Mathieu, nom et pays ont disparu." style="display: block; margin: 0.3em auto 0; width: 100%;">

<p class="petit centre" style="margin-top: 0.2rem;">Avec <code>"realisation.prenom"</code>, le champ s'ajoute ; sans notation pointée, <code>&#36;set</code> remplace <b>tout</b> le document imbriqué.</p>

<!--
(45 s)

Le besoin : on connaît le prénom de Kassovitz, on veut l'ajouter. Le réflexe de la séance 1, { $set: { realisation: … } }, « réussit » : modifiedCount: 1. Seul le findOne montre la perte : nom et pays ont disparu. Puis la notation pointée : on écrit dans le document imbriqué sans toucher au reste (branche verte du schéma).

Les deux mises à jour ont été exécutées sur MongoDB 9.0.4, chacune sur les films rechargés ; chacune renvoie le compte rendu affiché. Relu avec le même findOne après la version pointée : { realisation: { nom: 'Kassovitz', pays: 'France', prenom: 'Mathieu' } }.

Habitude à prendre au TP : relire le document modifié.

Renvoi : ex. 33 (un champ d'un document imbriqué, dans plusieurs documents).
-->

---

## Programmer une séance, retirer les séances passées

<p class="petit" style="margin: 0 0 0.2rem;">Chihiro passe aussi le 30 en salle 3 ; le 29 au matin, on retire les séances déjà passées.</p>

<div class="dense">

```js
db.films.updateOne({ _id: "F01" },
  { $push: { seances: { salle: 3, date: ISODate("2026-11-30"), libres: 50 } } })
db.films.updateOne({ _id: "F01" },
  { $pull: { seances: { date: { $lt: ISODate("2026-11-29") } } } })
```

</div>

<img src="assets/schemas/s2-push-pull.svg" alt="Le tableau seances du Voyage de Chihiro : au départ, les séances du 27/11 en salle 1, du 28/11 en salle 2 et du 29/11 en salle 1. Après $push : la séance du 30/11 en salle 3 est ajoutée à la fin. Après $pull avec une date antérieure au 29 novembre : les séances du 27 et du 28 sont retirées toutes les deux, il reste celles du 29 et du 30." style="display: block; margin: 0.5em auto 0.3em; width: 100%;">

<p class="petit">Vus en séance 1 sur des valeurs : <code>&#36;push</code> ajoute aussi un <b>document entier</b> ; <code>&#36;pull</code> accepte une <b>condition</b>, écrite comme un filtre, et retire <b>tous</b> les éléments qui la vérifient.</p>

<!--
(45 s)

Exécutées sur MongoDB 9.0.4, l'une après l'autre, sur les films rechargés ; chacune renvoie matchedCount: 1, modifiedCount: 1. Le schéma résume chaque séance par sa date et sa salle ; relu avec findOne, le tableau final contient { salle: 1, date: ISODate('2026-11-29T00:00:00.000Z'), libres: 40, evenement: 'ciné-débat' } et { salle: 3, date: ISODate('2026-11-30T00:00:00.000Z'), libres: 50 }.

Le $pull avec une condition surprend : il ne retire pas « le » premier élément trouvé, mais tous ceux qui la vérifient, ici les séances du 27 et du 28. Ne pas recharger : la diapo suivante part de cet état (la séance du 29 est passée de la position 2 à la position 0).

$push n'est pas idempotent : exécuté deux fois, il ajoute deux fois la séance (à l'inverse d'un $set, qui laisse le même document à la deuxième exécution). Encore une raison d'éviter Ctrl+Alt+R sur tout le playground.

Renvoi : ex. 35 et 36.
-->

---

## Modifier une séance : à quelle position ?

<div class="cols" style="grid-template-columns: 1fr 1fr;">
<div class="dense">

**Par son indice : la séance a bougé**

```js
// 2 places vendues, séance du 29 de Chihiro,
// en position 2… avant le $pull de la diapo 16
db.films.updateOne({ _id: "F01" },
  { $inc: { "seances.2.libres": -2 } })
// modifiedCount: 1, et seances.2 vaut
// { libres: -2 } : une séance fantôme
```

</div>
<div class="dense">

**Par le filtre : `$`, la position trouvée**

```js
db.films.updateOne({ _id: "F01",
    "seances.date": ISODate("2026-11-29") },
  { $inc: { "seances.$.libres": -2 } })
```

<div class="err">

```text
db.films.updateOne({ _id: "F01" },
  { $inc: { "seances.$.libres": -2 } })
MongoServerError: Plan executor error during
update :: caused by :: The positional operator
did not find the match needed from the query.
```

</div>

</div>
</div>

<img src="assets/schemas/s2-positionnel.svg" alt="Le tableau seances du Voyage de Chihiro après le $push et le $pull : la séance du 29 novembre en position 0, celle du 30 novembre en position 1. Le filtre seances.date égal au 29 novembre trouve l'élément en position 0 ; dans seances.$.libres, $ vaut cette position, comme si l'on avait écrit seances.0, et les places libres passent de 40 à 38." style="display: block; margin: 0.3em auto 0; width: 92%;">

<!--
(1 min 15)

Le besoin : une place vendue, c'est une séance précise qui change, pas tout le tableau. On part de l'état laissé par la diapo précédente, sans recharger : la séance du 29, en position 2 au départ, est passée en position 0 après le $pull. L'indice écrit au départ ne vise plus rien : MongoDB crée un élément à cette position, { libres: -2 }, sans erreur (modifiedCount: 1). En pratique, l'application connaît la date ou la salle, pas la position, et la position change dès qu'on ajoute ou retire une séance.

Le $ positionnel vaut la position que le filtre a trouvée : ici 0. Le $inc est celui de la séance 1. Sans condition sur seances dans le filtre, $ n'a rien à désigner : erreur (bloc rouge).

Exécutées sur MongoDB 9.0.4, après le $push et le $pull de la diapo précédente : chacune renvoie matchedCount: 1, modifiedCount: 1. Tableau relu après l'indice 2 : [ { salle: 1, date: ISODate('2026-11-29T00:00:00.000Z'), libres: 40, evenement: 'ciné-débat' }, { salle: 3, date: ISODate('2026-11-30T00:00:00.000Z'), libres: 50 }, { libres: -2 } ]. Avec $ (sans l'essai par l'indice), la séance du 29 passe de 40 à 38 places libres.

$ ne vise que le premier élément trouvé. Pour viser tous les éléments qui vérifient une condition, il existe $[<identifiant>] avec arrayFilters (bonus 4) : https://www.mongodb.com/docs/manual/reference/operator/update/positional-filtered/

Renvoi : ex. 34 (« Vous ne connaissez pas la position de l'exemplaire dans le tableau »).
-->

---

## Le ciné-débat du 29 est annulé, la séance passe en salle 2

<div class="cols-62">
<div class="dense">

```js
db.films.updateOne(
  { _id: "F01", "seances.salle": 1,
                "seances.date": ISODate("2026-11-29") },
  { $set:   { "seances.$.salle": 2 },
    $unset: { "seances.$.evenement": "" } })
// { acknowledged: true, insertedId: null,
//   matchedCount: 1, modifiedCount: 1, upsertedCount: 0 }
```

</div>
<div>

<style scoped>
table { font-size: 0.68em; }
</style>

| pos. | salle | date | libres | evenement |
|---|---|---|---|---|
| 0 | 1 | 27/11 | 0 | |
| 1 | 2 | 28/11 | 12 | |
| 2 | 1 | 29/11 | 40 | ciné-débat |

</div>
</div>

<div class="box" style="font-size: 0.8em; margin-top: 1rem;">

❓ **À vous de prédire** : quelle séance de Chihiro passe en salle 2 ? Le ciné-débat disparaît-il ?

</div>

<!--
(30 s)

Prédiction de la partie 6. On reprend les séances de Chihiro (films rechargés). Le filtre a l'air juste : « la séance en salle 1 du 29 ». Laisser la salle répondre : presque tout le monde répond « la séance en position 2 ».

Ce n'est pas une question de l'énoncé : on montre la brique ($elemMatch dans le filtre, $ dans $set et $unset), pas l'exercice.
-->

---

## La mauvaise séance : `$elemMatch` désigne la bonne

<style scoped>
table { font-size: 0.66em; }
td, th { padding: 0.15em 0.5em; }
tr.modif td { background: #fde2dd; font-weight: bold; }
</style>

<div class="cols">
<div class="dense">

**Deux conditions séparées** : seances relu

<table>
<tr><th>pos.</th><th>salle</th><th>date</th><th>libres</th><th>evenement</th></tr>
<tr class="modif"><td>0</td><td>1 → 2</td><td>27/11</td><td>0</td><td></td></tr>
<tr><td>1</td><td>2</td><td>28/11</td><td>12</td><td></td></tr>
<tr><td>2</td><td>1</td><td>29/11</td><td>40</td><td>ciné-débat</td></tr>
</table>

<p class="petit">Aucune erreur, <code>modifiedCount: 1</code> : <code>&#36;</code> a pris la position trouvée par <code>salle: 1</code>, la <b>0</b>.</p>

</div>
<div class="dense">

**`$elemMatch` : un même élément**

```js
db.films.updateOne(
  { _id: "F01", seances: { $elemMatch:
      { salle: 1, date: ISODate("2026-11-29") } } },
  { $set:   { "seances.$.salle": 2 },
    $unset: { "seances.$.evenement": "" } })
// séance en position 2 :
// { salle: 2,
//   date: ISODate('2026-11-29T00:00:00.000Z'),
//   libres: 40 }
```

</div>
</div>

<p class="petit centre" style="margin-top: 0.4rem;">Le filtre trouve l'élément, <code>&#36;</code> le désigne dans <code>&#36;set</code> <b>et</b> dans <code>&#36;unset</code>, dans la même mise à jour.</p>

<!--
(1 min)

Le piège de la partie 5, côté écriture, et plus grave : en lecture, on obtenait un film en trop ; ici, on modifie la mauvaise séance, sans erreur ni avertissement. Avec deux conditions séparées, chacune trouve son élément, et la position que retient $ n'est pas celle qu'on croit : sur MongoDB 9.0.4, c'est la position 0 (salle 1, le 27), quel que soit l'ordre des deux conditions dans le filtre (essayé dans les deux ordres). Le $unset ne trouve pas de champ evenement dans cette séance : il ne fait rien, et le ciné-débat reste.

Sorties obtenues sur MongoDB 9.0.4, sur les films rechargés avant chaque essai ; le tableau de gauche résume seances relu avec findOne après la mise à jour de la diapo précédente : [ { salle: 2, date: ISODate('2026-11-27T00:00:00.000Z'), libres: 0 }, { salle: 2, date: ISODate('2026-11-28T00:00:00.000Z'), libres: 12 }, { salle: 1, date: ISODate('2026-11-29T00:00:00.000Z'), libres: 40, evenement: 'ciné-débat' } ]. Avec $elemMatch, le tableau relu vaut [ { salle: 1, date: ISODate('2026-11-27T00:00:00.000Z'), libres: 0 }, { salle: 2, date: ISODate('2026-11-28T00:00:00.000Z'), libres: 12 }, { salle: 2, date: ISODate('2026-11-29T00:00:00.000Z'), libres: 40 } ].

Règle à retenir : deux conditions sur le même élément, c'est $elemMatch, en lecture comme en écriture. Renvoi : ex. 37 et 38 (TIP de l'ex. 38 : « Relisez la note sur $elemMatch de la partie 5 »). Ne pas en dire plus sur ces exercices.
-->

---

## Un document : tout ou rien. Deux documents : deux écritures

<img src="assets/schemas/s2-atomicite.svg" alt="À gauche, une seule écriture sur le film F01 applique les deux modifications de la séance, la nouvelle salle et le retrait du ciné-débat, ou aucune. À droite, un emprunt de la médiathèque : l'écriture 1 rend l'exemplaire indisponible dans livres, puis une panne survient : l'écriture 2, qui ajoute l'emprunt dans membres, n'a pas lieu. L'exemplaire est sorti, mais l'emprunt est introuvable chez le membre." style="display: block; margin: 0.6em auto 0; width: 100%;">

<div class="g2" style="margin-top: 1rem; font-size: 0.82em; align-items: stretch;">
<div class="box">

**Une mise à jour** touche un document : elle s'applique **en entier**, ou pas du tout.

</div>
<div class="warn">

**L'emprunt** de la médiathèque est écrit dans `livres` **et** dans `membres` : deux instructions, sans garantie entre les deux. Les **transactions** multi-documents : TP3.

</div>
</div>

<!--
(45 s)

Retour à l'emprunt écrit deux fois (diapo « Un emprunt écrit deux fois ») : c'est maintenant qu'on voit ce qu'il coûte. À gauche, la mise à jour de la diapo précédente : deux modifications du même document, appliquées ensemble ou pas du tout. À droite, l'emprunt : deux documents, deux collections, deux instructions ; une panne entre les deux laisse un exemplaire sorti sans emprunt chez le membre.

C'est l'encadré « Deux documents, deux écritures » de la partie 6 : la réponse aux exercices 37 et 38 contient deux instructions, une par collection, et le correcteur automatique compare l'état des deux collections. Ne pas en dire plus sur ces exercices.

C'est aussi la réponse à la deuxième moitié de la question de modélisation 3, qu'on peut reprendre ici.
-->

---

<!-- header: Séance 2 · premier temps -->

## À retenir : interroger et modifier

<div class="g2" style="font-size: 0.78em; align-items: stretch;">
<div class="carte vert">
<b class="t">Interroger</b>

- On **embarque** ce qui se lit ensemble : la fiche tient dans un document.
- `"a.b"` descend dans un document imbriqué ou traverse un tableau.
- Un document ou un tableau écrit en entier : égalité **exacte**.
- Deux conditions sur **le même** élément : `$elemMatch`.

</div>
<div class="carte">
<b class="t">Modifier</b>

- `$set` sans chemin pointé remplace **tout** le document imbriqué.
- `$pull` avec une condition retire **tous** les éléments qui la vérifient.
- `"tab.$"` : l'élément trouvé par le filtre, pas un indice deviné.
- Une donnée **recopiée** s'écrit à chaque endroit : deux écritures, non atomiques.

</div>
</div>

<div class="bandeau" style="margin-top: 0.9rem; font-size: 0.85em;">

Tout un livre tient dans un document : on l'interroge par **chemins**, on le modifie **élément par élément**.

</div>

<!--
(30 s)

Première moitié de la réponse à la question directrice : interroger et modifier un livre entier. La seconde moitié (en tirer des statistiques) est l'objet du second temps.
-->

---

<!-- header: "" -->

## À vous : la séance 2

<style scoped>
.g2 > div { display: flex; flex-direction: column; gap: 0.6rem; }
.g2 > div > .orange { margin-top: auto; }
</style>

<div class="bandeau" style="font-size: 1em; padding: 0.45rem 1.2rem;">
<a href="https://iutinfoaix-r510.github.io/tp1/">iutinfoaix-r510.github.io/tp1</a>, section « Séance 2 »
</div>

<div class="g2" style="margin-top: 0.8rem; font-size: 0.78em; grid-template-columns: 1.1fr 1fr; align-items: stretch;">
<div>

1. Partie 5, interroger : **55 min**
2. Partie 6, modifier : **1 h**
3. Point cours, puis partie 7, agréger : **1 h 15**
4. **Deuxième rendu** : `r510-rendre`, **10 min**

<p style="font-size: 0.85em; margin: 0;">Minutage indicatif. À la fin de chaque partie, le quiz de l'énoncé, dans votre assistant : « Fais-moi un quiz sur… ».</p>

<div class="carte orange">
<b class="t">📅 Rendu final du TP1</b>
dimanche 6 décembre 2026, 23&nbsp;h&nbsp;59
</div>

</div>
<div>

<div class="carte vert">
<b class="t">Les points</b>
Parties 5 à 7 : 18 exercices, 108 des 208 points du TP1, qui compte pour 16 % de la note.
</div>

<div class="carte vert">
<b class="t">🧪 Les essais</b>
Dans <code>essais.mongodb.js</code>, base <code>demo</code> ou collection <code>brouillon</code>. Jamais sous un <code>// Votre réponse :</code>.
</div>

<div class="carte orange">
<b class="t">Base abîmée ?</b>
<code>npm run seed -- --avant N</code> la répare.
</div>

</div>
</div>

<!--
(1 min)

Fin du premier temps (15 min 50 de diapos, plus les 8 minutes des questions de modélisation et cette minute : 24 min 50).

Rappeler les trois rendus du TP1 : fin de séance 1, fin de séance 2, rendu final au plus tard le dimanche 6 décembre 2026 à 23 h 59. r510-rendre lance npm run check, puis rend ; trois rendus au plus pour tout le TP1. r510-sauver sauvegarde, il ne note pas : seul r510-rendre, qui pose le tag submit/…, déclenche la correction.

Le minutage suppose le premier temps du point cours déjà fait (25 min). Reste : partie 5 (7 exercices), 55 min ; partie 6 (6 exercices, plus difficiles), 1 h ; le second temps du point cours (13 min) puis la partie 7 (5 exercices), 1 h 15 ; le rendu, 10 min. Le total fait 3 h 45 : il reste un quart d'heure de marge. En cas de retard, faire le deuxième rendu quand même, les exercices manquants iront au rendu final.

Les assistants du codespace sont configurés en tuteurs : ils expliquent une notion (skill approfondir-une-notion : « explique-moi $elemMatch ») et mènent un quiz sur d'autres données que celles du TP (skill quiz-thematique), mais n'écrivent pas la réponse d'un exercice. Les trois invites de quiz sont à la fin de chaque partie de l'énoncé. Pour la partie 7, aller le plus loin possible seul avant de les solliciter.
-->

---

<!-- header: Partie 7 · agréger -->

<!-- _class: lead -->
<!-- _header: "" -->

# Reprise : partie 7 - ⚙️ Premiers pipelines d'agrégation

Comment tirer une **statistique** de documents qui rangent leurs mesures dans un tableau ?

<!--
(10 s)

Début du second temps : à projeter quand la majorité du groupe attaque la partie 7. Diapos 23 à 36, 12 min 40. Même titre que la partie 7 de l'énoncé du TP1 (ex. 39 à 43).
-->

---

## Cinq capteurs, une journée, une question

<div class="dense">

```js
{ _id: "C1", piece: "Salon",   etage: 0, type: "temperature",
  mesures: [ { h: 8, v: 19.5 }, { h: 12, v: 21 }, { h: 18, v: 22.5 } ] }
{ _id: "C2", piece: "Salon",   etage: 0, type: "humidite",    mesures: [ … ] }
{ _id: "C3", piece: "Cuisine", etage: 0, type: "temperature",
  mesures: [ { h: 8, v: 18 }, { h: 12, v: 23 } ] }
{ _id: "C4", piece: "Salon",   etage: 0, type: "temperature", mesures: [ { h: 8, v: 20 } ] }
{ _id: "C5", piece: "Chambre", etage: 1, type: "temperature",
  mesures: [ { h: 8, v: 17 }, { h: 12, v: 17.5 }, { h: 18, v: 18 } ] }
```

</div>

<div class="cols" style="align-items: stretch;">
<div class="petit">

- Séance 1 : la **dernière** mesure ; ici, **une journée**, embarquée.
- → TP3 : un document par capteur **et par jour** (Bucket).

</div>
<div class="box">

❓ Quelle est la **température moyenne de chaque pièce**, de la plus chaude à la plus froide ?

</div>
</div>

<!--
(1 min)

Les capteurs de la séance 1 (upsert), avec un étage, et une journée de mesures au lieu de la seule dernière (champ derniere). Le capteur du garage, créé par l'upsert de la séance 1, n'est pas repris. C2 mesure l'humidité (ses deux mesures, 55 et 48, sont abrégées à l'écran : le script ci-dessous les donne) ; le Salon a deux capteurs de température (C1 et C4).

Une journée de mesures par capteur : le nombre de mesures par document est borné, d'où l'embarquement (ligne 1 du tableau des critères ; « toutes les mesures d'un capteur », sans limite, se référenceraient). Pour garder plusieurs jours, on ferait un document par capteur et par jour, avec la date dans le document (et dans l'_id, par exemple "C1-2026-11-23") : c'est le pattern Bucket du TP3. Ici, une seule journée, d'où l'_id du capteur.

Lire la question avant le code : c'est elle qui dictera les étapes.

Pour rejouer (essais.mongodb.js) :

use('demo');
db.capteurs.deleteMany({});
db.capteurs.insertMany([
  { _id: "C1", piece: "Salon", etage: 0, type: "temperature",
    mesures: [ { h: 8, v: 19.5 }, { h: 12, v: 21 }, { h: 18, v: 22.5 } ] },
  { _id: "C2", piece: "Salon", etage: 0, type: "humidite",
    mesures: [ { h: 8, v: 55 }, { h: 18, v: 48 } ] },
  { _id: "C3", piece: "Cuisine", etage: 0, type: "temperature",
    mesures: [ { h: 8, v: 18 }, { h: 12, v: 23 } ] },
  { _id: "C4", piece: "Salon", etage: 0, type: "temperature",
    mesures: [ { h: 8, v: 20 } ] },
  { _id: "C5", piece: "Chambre", etage: 1, type: "temperature",
    mesures: [ { h: 8, v: 17 }, { h: 12, v: 17.5 }, { h: 18, v: 18 } ] }
]);

Montrer la démarche en direct : on écrit l'étape 1, on sélectionne, Ctrl+Alt+S, on regarde ; on ajoute l'étape suivante, on réexécute, on regarde. Tous les résultats des diapos suivantes ont été obtenus ainsi sur MongoDB 9.0.4.
-->

---

## `find` sait filtrer, pas calculer : le pipeline

<img src="assets/schemas/s2-pipeline-principe.svg" alt="Dans le serveur MongoDB, les documents d'une collection traversent des étapes successives : étape 1, filtrer, il en reste moins ; étape 2, découper, il y en a plus ; étape 3, regrouper, il en reste deux, le résultat. Chaque étape reçoit les documents de la précédente et en produit de nouveaux." style="display:block; width:88%; margin:0.2em auto 0;">

<div class="cols-62" style="margin-top: 0.4rem; align-items: center;">
<div class="dense">

```js
db.capteurs.aggregate([                // un TABLEAU d'étapes
  { $match: { type: "temperature" } }  // étape 1 : filtrer
])
// 4 documents : C1, C3, C4, C5
```

</div>
<div class="petit">

`find` rend des documents, pas une moyenne. Un **pipeline** enchaîne des étapes, comme `grep | sort | head`. `$match` filtre comme `find`.

</div>
</div>

<!--
(1 min)

Le besoin : find({ type: "temperature" }) rend bien les 4 capteurs utiles, mais pas une moyenne par pièce. Il faudrait rapatrier toutes les mesures dans l'application et calculer en JavaScript. Le pipeline fait ce calcul dans le serveur, et seul le résultat revient.

Le parallèle avec le shell : chaque commande lit la sortie de la précédente ; une étape d'agrégation lit les documents produits par l'étape d'avant. Le schéma ne nomme que la première étape : les suivantes, marquées d'un point d'interrogation, se construisent dans les diapos qui suivent, à partir de ce qui échoue.

$match prend un filtre écrit comme celui de find, avec les mêmes opérateurs ($gt, $in…). Il se place le plus tôt possible : les étapes suivantes traitent moins de documents, et un $match en tête peut utiliser un index (TP2). C'est le WHERE du SQL.

mongosh accepte une étape isolée, aggregate({ $match: ... }), mais la documentation et les pilotes, dont le pilote Java du TP2 et du projet, passent toujours un tableau : prendre dès maintenant l'habitude de aggregate([ ... ]).
-->

---

## Regrouper tout de suite par pièce ?

<div class="dense">

```js
db.capteurs.aggregate([
  { $match: { type: "temperature" } },
  { $group: { _id: "$piece",                       // un groupe par pièce
              moyenne: { $avg: "$mesures.v" } } }  // la moyenne des valeurs
])
```

</div>

<div class="g2" style="margin-top: 0.8rem; font-size: 0.82em; align-items: stretch;">
<div class="box">

❓ **À vous de prédire** : combien de documents sortent, et que vaut `moyenne` pour le Salon ?

</div>
<div>

- `"$piece"` : **la valeur** du champ `piece`, comme `"$realisation.pays"` en partie 5.
- `$avg` : un **accumulateur**, calculé sur les documents du groupe.

</div>
</div>

<!--
(30 s)

Prédiction de la partie 7. Les étudiants qui viennent du SQL répondent souvent « 3 documents, et 20.75 pour le Salon » : c'est le GROUP BY qu'ils connaissent. Le nombre est juste ; la moyenne, non.

Le $ en tête d'une chaîne désigne la valeur d'un champ du document courant : vu en partie 5 dans la projection de find.
-->

---

## `moyenne: null` : il faut un document par mesure

<div class="cols" style="grid-template-columns: 1fr 1.5fr; align-items: center;">
<div class="dense">

```js
// étapes $match, $group :
// [ { _id: 'Chambre', moyenne: null },
//   { _id: 'Salon', moyenne: null },
//   { _id: 'Cuisine', moyenne: null } ]
```

```js
db.capteurs.aggregate([
  { $match: { type: "temperature" } },
  { $unwind: "$mesures" }
])
// 9 documents : 3 + 2 + 1 + 3
```

</div>
<div>

<img src="assets/schemas/s2-unwind.svg" alt="$unwind : le document C1, dont le tableau mesures contient 3 éléments, devient 3 documents de même _id C1, chacun avec une seule mesure dans le champ mesures : h 8 v 19.5, h 12 v 21, h 18 v 22.5. Un document par élément." style="display: block; width: 100%; margin: 0 auto;">

</div>
</div>

<div class="petit" style="margin-top: 0.4rem;">

- Pour un capteur, `"$mesures.v"` est un **tableau** de valeurs ; `$avg` dans `$group` l'ignore.
- `$unwind` fait **un document par élément** ; les autres champs sont recopiés, avec le même `_id`. Après lui, `mesures` est un document : `"$mesures.v"` est **un nombre**.

</div>

<!--
(1 min 30)

Sortie réelle sur MongoDB 9.0.4 : trois groupes, mais moyenne: null. Dans $group, $avg calcule sur les documents du groupe et ignore les valeurs qui ne sont pas des nombres ; or "$mesures.v" vaut, pour C1, le tableau [19.5, 21, 22.5]. Aucun nombre : null. Pas d'erreur, un résultat faux : c'est l'erreur la plus fréquente en agrégation, une mauvaise idée de la forme du document qui entre dans l'étape.

Le remède : un document par mesure. Le schéma montre C1 (champs piece, etage et type omis) ; en tout, 9 documents pour les 4 capteurs. Le même _id apparaît plusieurs fois, ce qui est normal à l'intérieur d'un pipeline. Équivalent SQL : la jointure capteurs JOIN mesures, une ligne par mesure.

Un document dont le tableau est vide ou absent disparaît à cette étape : voir l'annexe (preserveNullAndEmptyArrays).

Renvoi : ex. 39, 42 et 43 (« il faut d'abord un document par couple... »).
-->

---

## `$group` : un document par pièce

<div class="cols" style="grid-template-columns: 1.15fr 1fr; align-items: center;">
<div class="dense">

```js
  { $group: {
      _id: "$piece",           // la clé
      moyenne: { $avg: "$mesures.v" },
      nb: { $sum: 1 }
  } }
// [ { _id: 'Cuisine', moyenne: 20.5, nb: 2 },
//   { _id: 'Salon', moyenne: 20.75, nb: 4 },
//   { _id: 'Chambre', moyenne: 17.5, nb: 3 } ]
```

</div>
<div class="petit">

- Un document par valeur de `_id`, la clé.
- `$sum: 1` compte les documents : `COUNT(*)`.
- `$avg`, `$min`, `$max`, `$sum: "$x"`.
- `_id: null` : un seul groupe pour tout.
- Les groupes sortent dans un ordre **quelconque**.

</div>
</div>

<img src="assets/schemas/s2-group.svg" alt="$group : les 9 documents issus de $unwind sont rangés par pièce. Salon reçoit 19.5, 21, 22.5 et 20 ; Cuisine 18 et 23 ; Chambre 17, 17.5 et 18. Chaque groupe donne un document : Salon moyenne 20.75, nb 4 ; Cuisine moyenne 20.5, nb 2 ; Chambre moyenne 17.5, nb 3." style="display: block; margin: 0.5em auto 0; width: 100%;">

<!--
(1 min 15)

Après $match et $unwind (étapes inchangées, non recopiées). Un groupe = un document en sortie, avec la clé dans _id. Le Salon a 4 mesures : 3 du capteur C1 et 1 du capteur C4, soit (19.5 + 21 + 22.5 + 20) / 4 = 20.75. Le capteur d'humidité C2 a été écarté par le $match. Les documents d'entrée du schéma sont abrégés (champs h, etage et type omis).

Sortie obtenue sur MongoDB 9.0.4 ; l'ordre des groupes change d'une exécution à l'autre (on y revient avec $sort).

Le tableau des accumulateurs et de leur équivalent SQL est dans l'énoncé, partie 7. C'est le GROUP BY piece du SQL.
-->

---

## Seulement les pièces à 20 °C ou plus ?

<div class="cols">
<div class="dense">

**Avant `$group` : `moyenne` n'existe pas**

```js
  // $match, $unwind, puis :
  { $match: { moyenne: { $gte: 20 } } },
  { $group: { _id: "$piece",
      moyenne: { $avg: "$mesures.v" },
      nb: { $sum: 1 } } }
// []
```

</div>
<div class="dense">

**Après `$group` : il filtre les groupes**

```js
  // $match, $unwind, $group, puis :
  { $match: { moyenne: { $gte: 20 } } }
// [ { _id: 'Cuisine', moyenne: 20.5, nb: 2 },
//   { _id: 'Salon', moyenne: 20.75, nb: 4 } ]
```

</div>
</div>

<div class="box" style="margin-top: 1rem; font-size: 0.85em;">

Un second `$match`, **après** `$group`, filtre sur un champ que `$group` a produit : c'est le `HAVING` du SQL.

</div>

<!--
(1 min)

Le besoin : on ne veut plus que les pièces dont la moyenne atteint 20 °C. Le réflexe : un $match, placé comme d'habitude en tête, avant le $group. Il ne renvoie rien : avant le $group, les documents sont des mesures, et aucun n'a de champ moyenne. Le filtre doit venir après l'étape qui produit le champ. La Chambre (17.5) est écartée.

Sorties obtenues sur MongoDB 9.0.4 (étapes $match { type: "temperature" } et $unwind en tête, non recopiées ; ordre des groupes quelconque).

C'est le WHERE et le HAVING du SQL : même étape $match, deux places, deux sens. Cette variante ne fait pas partie du pipeline final : la question des capteurs porte sur toutes les pièces.

Renvoi : ex. 43 (« le seuil porte sur les groupes »). Ne pas en dire plus.
-->

---

## Afficher l'étage : un champ de `$group` est un accumulateur

<div class="cols" style="grid-template-columns: 1fr 1fr; align-items: start;">
<div class="dense">

**Le réflexe d'une projection**

<div class="err">

```text
{ $group: { _id: "$piece", etage: "$etage", … } }
MongoServerError: The field 'etage' must be an
accumulator object
```

</div>

</div>
<div class="dense">

**Un accumulateur : `$first`**

```js
  { $group: { _id: "$piece",
      etage: { $first: "$etage" },
      moyenne: { $avg: "$mesures.v" },
      nb: { $sum: 1 } } }
// [ { _id: 'Chambre', etage: 1,
//     moyenne: 17.5, nb: 3 },
//   { _id: 'Salon', etage: 0,
//     moyenne: 20.75, nb: 4 },
//   { _id: 'Cuisine', etage: 0,
//     moyenne: 20.5, nb: 2 } ]
```

</div>
</div>

<p class="petit centre" style="margin-top: 0.6rem;">Hors de <code>_id</code>, chaque champ de <code>&#36;group</code> est calculé sur <b>tout le groupe</b>. Tous les capteurs d'une pièce ont le même étage : le premier suffit.</p>

<!--
(45 s)

Le besoin : afficher aussi l'étage de chaque pièce. Le réflexe, écrire etage: "$etage" comme dans une projection, échoue : dans $group, tout champ autre que _id doit être un accumulateur (erreur obtenue sur MongoDB 9.0.4). $first prend la valeur du premier document du groupe. En SQL, on écrirait GROUP BY piece, etage.

Sortie obtenue sur MongoDB 9.0.4, après $match et $unwind (ordre des groupes quelconque).

Renvoi : ex. 43 (« gardez son nom avec un accumulateur »). Ne pas en dire plus.
-->

---

## Le résultat s'appelle `_id` : renommer et arrondir

<p class="petit" style="margin: 0 0 0.2rem;">Après <code>&#36;group</code>, la pièce s'appelle <code>_id</code> et la moyenne du Salon vaut 20.75 : on veut <code>piece</code>, et une décimale.</p>

<div class="dense">

```js
  { $project: {
      _id: 0,                                 // retire _id
      piece: "$_id",                          // renomme : la valeur de _id
      etage: "$etage",                        // recopie
      moyenne: { $round: ["$moyenne", 1] },   // calcule : arrondi à 1 décimale
      nb: "$nb"
  } }
// [ { piece: 'Chambre', etage: 1, moyenne: 17.5, nb: 3 },
//   { piece: 'Salon', etage: 0, moyenne: 20.8, nb: 4 }, … ]
```

</div>

<img src="assets/schemas/s2-project.svg" alt="$project sur le document du Salon. En entrée : _id Salon, etage 0, moyenne 20.75, nb 4. En sortie : piece Salon, renommé depuis _id ; etage 0, recopié ; moyenne 20.8, calculée par $round ; nb 4, recopié. Le champ _id, exclu, disparaît." style="display: block; width: 100%; margin: 0.4em auto 0;">

<p class="petit centre" style="margin-top: 0.3rem;"><code>&#36;project</code>, c'est le <code>SELECT</code> : le nombre de documents ne change pas, leur <b>forme</b> si. Un champ non cité disparaît.</p>

<!--
(45 s)

Après les étapes $match, $unwind et $group (avec $first). "$_id" désigne la valeur du champ _id produit par $group, ici le nom de la pièce : piece: "$_id" la recopie sous un nom parlant ; _id: 0 retire le champ d'origine, sinon la pièce apparaîtrait deux fois.

$round arrondit 20.75 à 20.8. Les moyennes de $group restent exactes ; l'arrondi ne sert qu'à l'affichage, d'où sa place en fin de pipeline.

Sortie obtenue sur MongoDB 9.0.4 (trois documents, dans un ordre quelconque ; le troisième est { piece: 'Cuisine', etage: 0, moyenne: 20.5, nb: 2 }). Détail : avec etage: 1 et nb: 1 (inclusion) au lieu de "$etage" et "$nb", le résultat est le même, mais les champs inclus sortent en tête : { etage: 1, nb: 3, piece: 'Chambre', moyenne: 17.5 } (vérifié sur 9.0.4).
-->

---

## Par document ou par groupe ?

<div class="cols" style="grid-template-columns: 1.3fr 1fr;">
<div class="dense">

**Dans `$project` : sur le tableau d'un document**

```js
db.capteurs.aggregate([
  { $match: { type: "temperature" } },
  { $project: { piece: 1,
      nb: { $size: "$mesures" },
      moyenne: { $avg: "$mesures.v" } } }
])
// [ { _id: 'C1', piece: 'Salon', nb: 3, moyenne: 21 },
//   { _id: 'C3', piece: 'Cuisine', nb: 2, moyenne: 20.5 },
//   { _id: 'C4', piece: 'Salon', nb: 1, moyenne: 20 },
//   { _id: 'C5', piece: 'Chambre', nb: 3, moyenne: 17.5 } ]
```

</div>
<div>

<div class="carte vert" style="font-size: 0.78em;">
<b class="t">Une moyenne par capteur</b>
Sans <code>&#36;unwind</code> ni <code>&#36;group</code> : <code>&#36;avg</code> et <code>&#36;size</code> sont des <b>expressions</b>, calculées sur le tableau de chaque document.
</div>

<div class="carte orange" style="font-size: 0.78em; margin-top: 0.7rem;">
<b class="t">Une moyenne par pièce</b>
Dans <code>&#36;group</code>, <code>&#36;avg</code> est un <b>accumulateur</b>, calculé sur les documents du groupe : il faut d'abord <code>&#36;unwind</code>.
</div>

</div>
</div>

<!--
(1 min 15)

Le même mot, $avg, deux rôles. La question à se poser avant d'écrire un pipeline : la statistique porte-t-elle sur un document (ses éléments de tableau) ou sur plusieurs documents ? Le Salon le montre : 21 pour C1, 20 pour C4, mais 20.75 pour la pièce, la moyenne de ses 4 mesures, pas celle des deux capteurs.

Sortie obtenue sur MongoDB 9.0.4.

$size exige un tableau : sur un document sans champ mesures, le pipeline s'arrête (« The argument to $size must be an array, but was of type: missing », vérifié en ajoutant un capteur sans mesures). Écarter d'abord ces documents avec un $match. $size en requête (dans find) et en expression : voir l'annexe.

Renvoi : ex. 40 et 41 (« Ici, pas besoin de $group : chaque livre porte ses avis »). Ne pas en dire plus.
-->

---

## `$sort` et `$limit` : l'ordre des étapes compte

<div class="cols">
<div class="dense">

**Séance 1 : `find` trie toujours, puis limite**

```js
db.films.find({}, { _id: 0, titre: 1, duree: 1 })
  .limit(2).sort({ duree: -1 })
// [ { titre: 'Le Voyage de Chihiro', duree: 125 },
//   { titre: 'Amélie Poulain', duree: 122 } ]
```

**Pipeline : `$limit` avant `$sort`**

```js
db.films.aggregate([ { $limit: 2 },
  { $sort: { duree: -1 } },
  { $project: { _id: 0, titre: 1, duree: 1 } } ])
// [ { titre: 'Le Voyage de Chihiro', duree: 125 },
//   { titre: 'Mon voisin Totoro', duree: 86 } ]
```

</div>
<div class="petit">

- Sans `$sort`, l'ordre des documents **n'est pas garanti** : un résultat trié demande un `$sort` explicite.
- `$limit: n` coupe le flux **dans l'ordre où il le reçoit** : il se place **après** `$sort`.

</div>
</div>

<div class="warn" style="margin-top: 0.8rem;">

`find` trie toujours avant de limiter ; un pipeline exécute ses étapes **dans l'ordre écrit**.

</div>

<!--
(1 min 15)

Le contraste avec la séance 1, sur les films (rechargés) : dans find, l'ordre d'appel de .limit() et .sort() ne compte pas, le serveur trie toujours avant de limiter. Dans un pipeline, chaque étape traite ce qu'elle reçoit : $limit: 2 garde les deux premiers films de la collection (Chihiro, Totoro), puis $sort ne trie que ces deux-là. Amélie Poulain (122 min) manque. Sorties obtenues sur MongoDB 9.0.4 ; avec $sort puis $limit, le pipeline rend bien Chihiro et Amélie Poulain.

Sur les capteurs : l'ordre des groupes de $group a changé d'une exécution à l'autre ; { $sort: { moyenne: -1 } } le fixe : Salon, Cuisine, Chambre. Même convention 1 / -1 que sort() dans find : ORDER BY … ASC, DESC ; plusieurs clés départagent les ex aequo ({ moyenne: -1, piece: 1 }).

Lien avec le TP : un exercice qui impose un tri et qui reçoit les bons documents dans le mauvais ordre ne rapporte que la moitié des points (🟡 dans npm run check). Renvoi : ex. 41 (« Les 3 plus gros emprunteurs »).
-->

---

## Le pipeline complet, et son équivalent SQL

<div class="cols-62" style="align-items: center;">
<div class="dense">

```js
db.capteurs.aggregate([
  { $match: { type: "temperature" } },     // WHERE
  { $unwind: "$mesures" },                 // JOIN mesures
  { $group: { _id: "$piece",               // GROUP BY
      etage: { $first: "$etage" },
      moyenne: { $avg: "$mesures.v" },
      nb: { $sum: 1 } } },
  { $project: { _id: 0, piece: "$_id",     // SELECT
      etage: "$etage", nb: "$nb",
      moyenne: { $round: ["$moyenne", 1] } } },
  { $sort: { moyenne: -1 } }               // ORDER BY
])
// [ { piece: 'Salon', etage: 0, nb: 4, moyenne: 20.8 },
//   { piece: 'Cuisine', etage: 0, nb: 2, moyenne: 20.5 },
//   { piece: 'Chambre', etage: 1, nb: 3, moyenne: 17.5 } ]
```

</div>
<div style="font-size: 0.85em;">

| SQL | Étape |
|---|---|
| `WHERE` | `$match` |
| une ligne par mesure | `$unwind` |
| `GROUP BY` | `$group` |
| `HAVING` | `$match` après |
| `SELECT` | `$project` |
| `ORDER BY` | `$sort` |
| `LIMIT` | `$limit` |

</div>
</div>

<p class="centre" style="margin-top: 0.4rem;">Nombre de documents, de la collection au résultat : <b>5 → 4 → 9 → 3 → 3 → 3</b>.</p>

<!--
(45 s)

La synthèse arrive à la fin, une fois chaque étape construite : c'est le pipeline qui répond à la question de la diapo « Cinq capteurs ». Lire le code avec la colonne SQL : c'est le repère des étudiants qui viennent du relationnel. L'analogie casse à deux endroits : $unwind n'a pas d'équivalent direct (dans un schéma relationnel, les mesures seraient dans une table à part, et la jointure donnerait une ligne par mesure) ; et l'ordre des étapes est celui qu'on écrit, alors qu'en SQL l'ordre des clauses est fixé. $first n'a pas d'équivalent non plus : en SQL, on écrirait GROUP BY piece, etage.

Résultat obtenu sur MongoDB 9.0.4, recopié sous le pipeline. La ligne du bas se lit avec les étapes : la collection a 5 documents, $match en retire (4), $unwind en crée (9, un par mesure), $group les rassemble (3, un par pièce), $project et $sort changent leur forme et leur ordre, pas leur nombre. C'est la question à se poser avant chaque étape : combien de documents entrent, et de quelle forme ? Le schéma « document par document » est en annexe.

Pour la pagination d'une API (projet), $skip: n saute les n premiers documents : $sort, puis $skip, puis $limit.
-->

---

## Écrire un pipeline sans se tromper

<style scoped>
table { width: 100%; font-size: 0.72em; }
td:nth-child(1) code, td:nth-child(2) code { white-space: nowrap; }
</style>

<div class="box" style="font-size: 0.85em; margin-top: 0;">

**Une étape à la fois.** On ajoute une étape, on exécute (sélection + `Ctrl+Alt+S`), on **regarde la forme** de ce qui sort, puis on écrit la suivante.

</div>

| Au lieu de | Écrire | Pourquoi |
|---|---|---|
| `aggregate({ $match: … })` | `aggregate([ { $match: … } ])` | le pipeline est un **tableau**, même d'une seule étape |
| `{ $projection: … }` | `{ $project: … }` | `$projection` n'existe pas |
| `{ $project: { $piece: 1 } }` | `{ $project: { piece: 1 } }` | le `$` va dans la **valeur** (`"$piece"`), jamais dans la clé |
| `{ $match: { piece: "$piece" } }` | un filtre, comme dans `find` | dans `$match`, `"$piece"` est une simple chaîne |

<div class="warn" style="margin-top: 0.8rem;">

🤖 **Pour le correcteur automatique** : la réponse se **termine** par <code style="white-space: nowrap">db.&lt;collection&gt;.aggregate([...])</code> (ou `.toArray()`). Un `find` ou un calcul placé après vaut 0.

</div>

<!--
(1 min)

Les messages d'erreur ont été obtenus sur MongoDB 9.0.4 :
- $projection : « Unrecognized pipeline stage name: '$projection' » ;
- $piece en clé : « Invalid $project :: caused by :: Consider using $getField or $setField for a field path with '.' or '$'. :: caused by :: FieldPath field names may not start with '$', given '$piece'. » ;
- { $match: { piece: "$piece" } } ne lève aucune erreur : il compare piece à la chaîne "$piece" et ne renvoie aucun document. Comparer deux champs d'un même document demande $expr, vu au TP2.

La méthode « une étape à la fois » répond à l'erreur la plus fréquente, celle de la diapo « moyenne: null » : se tromper sur la forme du document qui entre dans l'étape.

Le playground propose pour chaque exercice de la partie 7 un squelette commenté, à compléter étape par étape. Un squelette aggregate([]) resté vide sous la réponse est ignoré par le correcteur automatique (il note la dernière instruction utile). En revanche, une réponse qui se termine par un find ou par un calcul en JavaScript après le pipeline vaut 0, avec l'un de ces messages : « Cet exercice demande un pipeline d'agrégation (aggregate) » ou « Terminez la réponse par le pipeline lui-même, db.….aggregate([...]) : un calcul en JavaScript après le pipeline vaut 0 ».
-->

---

<!-- header: Séance 2 · second temps -->

## À retenir : tirer des statistiques

<div class="g2" style="font-size: 0.8em; align-items: stretch;">
<div class="carte vert">
<b class="t">Le pipeline</b>

- Une suite d'étapes ; chacune reçoit les documents de la précédente.
- Avant chaque étape : **quelle forme** a le document qui entre ?
- `$unwind` : un document par élément, avant un `$group` sur les éléments.
- L'ordre des étapes est celui qu'on écrit : `$match` tôt, `$sort` avant `$limit`.

</div>
<div class="carte">
<b class="t">Par document ou par groupe</b>

- `$group` : un document par valeur de `_id` ; les autres champs sont des accumulateurs (`$sum`, `$avg`, `$first`).
- `$match` après `$group` : `HAVING`.
- Dans `$project`, `$size` et `$avg` calculent sur le tableau **d'un** document.

</div>
</div>

<div class="bandeau" style="margin-top: 1rem; font-size: 0.85em;">

Tout un livre tient dans un document : on l'interroge par **chemins**, on le modifie **élément par élément**, on en tire des statistiques **étape par étape**.

</div>

<!--
(30 s)

Fin de la réponse à la question directrice. Les pipelines reviennent au TP2 ($lookup, fenêtres, index), et le Bucket des capteurs au TP3.
-->

---

<!-- header: "" -->

<!-- _class: lead -->

# Des questions ?

**Sébastien Nedjar** (GA1) · **Leïla Sakli Miled** (GA2)
IUT d'Aix-Marseille, département Informatique

<div style="margin-top: 1.2rem; font-size: 0.85em;">

[iutinfoaix-r510.github.io/tp1](https://iutinfoaix-r510.github.io/tp1/)
sebastien.nedjar@univ-amu.fr · leila.SAKLI@univ-amu.fr

</div>

<div class="bandeau" style="margin-top: 1.6rem; text-align: left; font-size: 0.95em;">

🎯 **Dès maintenant, et d'ici le dimanche 6 décembre, 23&nbsp;h&nbsp;59** : terminez les exercices manquants, faites le quiz de chaque partie, puis le rendu final avec <code style="white-space: nowrap;">r510-rendre</code>.

</div>

<!--
(10 s)

Les adresses sont celles du syllabus. Questions sur le cours : en séance, ou par courriel à l'enseignant de son groupe ; entre les séances, une issue sur le dépôt syllabus.
-->

---

## Crédits

<div class="petit">

**Contenus repris** de MongoDB for Academia, sous licence [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/deed.fr) :

- contenus reformulés : *MongoDB 101: Non-Relational for Beginners*, diapos 38 à 47 (les relations 1-1, 1-N et N-N et le choix courant, diapo « Embarquer ou référencer »)

Détail des reprises : `ATTRIBUTION.md` du dépôt [IUTInfoAix-R510/cours](https://github.com/IUTInfoAix-R510/cours).

**Ce support** : R5.Real.10, IUT d'Aix-Marseille, sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Exemples (films, capteurs) écrits pour ce cours et exécutés sur MongoDB 9.0.4.

**Pour aller plus loin** : [requêtes sur les documents imbriqués](https://www.mongodb.com/docs/manual/tutorial/query-embedded-documents/) · [sur les tableaux](https://www.mongodb.com/docs/manual/tutorial/query-arrays/) · [opérateur positionnel](https://www.mongodb.com/docs/manual/reference/operator/update/positional/) · [`$[<identifiant>]` et `arrayFilters`](https://www.mongodb.com/docs/manual/reference/operator/update/positional-filtered/) · [pipeline d'agrégation](https://www.mongodb.com/docs/manual/core/aggregation-pipeline/) · [embarquer ou référencer](https://www.mongodb.com/docs/manual/data-modeling/concepts/embedding-vs-references/)

</div>

<!--
(Hors minutage : diapo de référence, laissée en fin de support.)

Les présentations d'origine sont en anglais et pensées pour Atlas et l'ancien shell. Les liens sont dans le README du dépôt cours.

Si des étudiants consultent les présentations officielles, voici les passages qui touchent cette séance, avec leurs écarts par rapport au TP (numéros de page de l'export PDF) :
- MongoDB 101, diapos 31 à 34 : le schéma part des besoins de l'application. Diapo 46 : l'exemple N-N des livres et des auteurs répond à la question de modélisation 2, à ne pas montrer avant la mise en commun.
- Querying Complex Data with MQL, diapo 38 : { dim_cm.1: { $gt: 25 } } sans guillemets, qui provoque la SyntaxError de la diapo « La notation pointée ». La diapo 36 est cassée. Les tableaux sont traités aux diapos 30-31, 33, 35, 38 et 40, $elemMatch aux diapos 49 à 54, sur une collection inventory.
- The MongoDB Query Language, diapo 53 : « toutes les écritures sont atomiques » ne vaut que pour un document (Inserting and Updating Data in MongoDB, diapo 43, le dit correctement). Diapo 67 : elle mélange le sens requête et le sens projection de $elemMatch.
- Aucune présentation ne traite l'opérateur positionnel $ dans une mise à jour.
- Querying Data with the MongoDB Aggregation Framework, diapos 5 à 9 : aggregate({ $match: ... }) avec une étape seule, sans tableau. Diapos 25 à 28 : { $project: { $field: <expr> } }, refusé par le serveur.
- The MongoDB Aggregation Framework, diapos 12 à 14 : correspondance avec find, à lire avec $project et non $projection, countDocuments() et non count(). Diapos 34 à 38 : $group sur une collection cow remplie au hasard, résultats non reproductibles ; les diapos 33 et 38 affichent des résultats sans $sort. Diapos 83 à 86 : constructeur de pipeline Compass ou Atlas, absent du codespace.
- Ne pas rejouer leurs démos (drop() sur inventory ou cow) dans la base tp1.
-->

---

<!-- header: Annexe -->

<!-- _class: lead -->
<!-- _header: "" -->

# Annexe

Référence, non projetée : opérateurs de tableaux, `$size`, `preserveNullAndEmptyArrays`, le pipeline document par document

<!--
(Hors minutage : l'annexe n'est pas projetée. Elle reste dans le PDF et en ligne, pour le TP.)
-->

---

## Les opérateurs sur les tableaux : interroger et projeter

<div class="recap">
<div class="carte"><b class="t">Interroger : filtre de find</b>
<table>
<tr><td><code>{ tab: v }</code></td><td>contient la valeur v</td></tr>
<tr><td><code>{ tab: [v1, v2] }</code></td><td>égal à ce tableau, ordre compris</td></tr>
<tr><td><code>&#36;all</code> · <code>&#36;in</code> · <code>&#36;nin</code></td><td>toutes ces valeurs · au moins une · aucune</td></tr>
<tr><td><code>&#36;size: n</code></td><td>exactement n éléments</td></tr>
<tr><td><code>&#36;elemMatch</code></td><td>un même élément vérifie toutes les conditions</td></tr>
<tr><td><code>"tab.champ"</code> · <code>"tab.0"</code></td><td>un élément quelconque · l'élément d'indice 0</td></tr>
</table></div>
<div class="carte vert"><b class="t">Projeter : second argument de find</b>
<table>
<tr><td><code>{ "tab.champ": 1 }</code></td><td>ce champ dans chaque élément</td></tr>
<tr><td><code>&#36;slice: n</code></td><td>les n premiers éléments (n négatif : les n derniers)</td></tr>
<tr><td><code>"tab.&#36;": 1</code> · <code>&#36;elemMatch</code></td><td>le premier élément qui correspond</td></tr>
</table></div>
</div>

<p class="legende">Vérifiés sur MongoDB 9.0.4. Manuel : <a href="https://www.mongodb.com/docs/manual/reference/operator/query-array/">opérateurs de requête</a> et <a href="https://www.mongodb.com/docs/manual/reference/operator/projection/">de projection</a> sur les tableaux.</p>

<!--
Diapo de référence : les étudiants la retrouvent en ligne pendant le TP.

Rappeler les deux pièges : un tableau écrit dans le filtre demande une égalité exacte, ordre compris ; deux conditions sur un tableau de documents peuvent être satisfaites par deux éléments différents, d'où $elemMatch.
-->

---

## Les opérateurs sur les tableaux : modifier et agréger

<div class="recap">
<div class="carte orange"><b class="t">Modifier : updateOne, updateMany</b>
<table>
<tr><td><code>&#36;push</code> (avec <code>&#36;each</code>)</td><td>ajoute à la fin (plusieurs valeurs)</td></tr>
<tr><td><code>&#36;addToSet</code></td><td>ajoute si la valeur n'y est pas déjà</td></tr>
<tr><td><code>&#36;pull</code> · <code>&#36;pullAll</code></td><td>retire selon une condition · retire ces valeurs</td></tr>
<tr><td><code>&#36;pop: 1</code> · <code>&#36;pop: -1</code></td><td>retire le dernier · le premier élément</td></tr>
<tr><td><code>"tab.&#36;"</code> · <code>"tab.1"</code></td><td>l'élément trouvé par le filtre · l'élément d'indice 1</td></tr>
<tr><td><code>"tab.&#36;[]"</code> · <code>"tab.&#36;[x]"</code></td><td>tous les éléments · ceux retenus par <code>arrayFilters</code> (bonus 4)</td></tr>
</table></div>
<div class="carte violet"><b class="t">Agréger : dans un pipeline</b>
<table>
<tr><td><code>&#36;unwind</code></td><td>un document par élément</td></tr>
<tr><td><code>&#36;size</code> · <code>&#36;avg</code> (expressions)</td><td>la longueur · la moyenne des éléments d'un tableau</td></tr>
<tr><td><code>&#36;arrayElemAt</code> · <code>&#36;filter</code></td><td>l'élément d'indice n · les éléments qui vérifient une condition</td></tr>
</table></div>
</div>

<p class="legende">Vérifiés sur MongoDB 9.0.4. Manuel : <a href="https://www.mongodb.com/docs/manual/reference/operator/update-array/">opérateurs de mise à jour</a> sur les tableaux.</p>

<!--
Diapo de référence.

$push ajoute même si la valeur est déjà là ; $addToSet non. $pull retire selon une condition écrite comme un filtre ; $pullAll retire une liste de valeurs exactes. "tab.$" modifie l'élément trouvé par le filtre ; "tab.$[]" tous les éléments ; "tab.$[x]" ceux qui vérifient la condition de arrayFilters (bonus 4 du TP1).
-->

---

## `$size` : filtrer dans `find`, calculer dans un pipeline

<div class="cols">
<div class="dense">

**Dans `find`, `$size` filtre : exactement n**

```js
db.films.find({ seances: { $size: 2 } },
              { _id: 0, titre: 1 })
// [ { titre: 'Mon voisin Totoro' },
//   { titre: 'Amélie Poulain' } ]
```

<div class="err">

```text
db.films.find({ seances: { $size: { $gt: 1 } } })
MongoServerError: Failed to parse $size. Expected a
number in: $size: { $gt: 1 }
```

</div>

**« Au moins 3 » : l'élément d'indice 2 existe**

```js
db.films.find({ "seances.2": { $exists: true } },
              { _id: 0, titre: 1 })
// [ { titre: 'Le Voyage de Chihiro' } ]
```

</div>
<div class="dense">

**Dans un pipeline, `$size` calcule**

```js
{ $project: { nb: { $size: "$mesures" } } }
```

<p class="petit">Il exige un tableau : sur un document <b>sans</b> le champ, le pipeline s'arrête.</p>

<div class="err">

```text
MongoServerError: Executor error during aggregate
command on namespace: demo.capteurs :: caused by ::
The argument to $size must be an array, but was of
type: missing
```

</div>

<p class="petit">Écarter d'abord ces documents avec un <code>&#36;match</code>.</p>

</div>
</div>

<!--
Exécuté sur MongoDB 9.0.4, sur les films et les capteurs rechargés ; l'erreur de droite a été obtenue après avoir ajouté un capteur sans champ mesures : db.capteurs.insertOne({ _id: "C6", piece: "Garage", etage: 0, type: "temperature" }).

L'expression $size se combine avec une comparaison dans un $match avec $expr : { $expr: { $gt: [ { $size: "$mesures" }, 2 ] } }, vu au TP2.
-->

---

## `$unwind` et les tableaux vides

<div class="cols">
<div class="dense">

**Par défaut, le document disparaît**

```js
db.films.aggregate([
  { $match: { _id: "F04" } },     // seances: []
  { $unwind: "$seances" }
])
// []
```

</div>
<div class="dense">

**Avec l'option, il reste, sans le champ**

```js
db.films.aggregate([
  { $match: { _id: "F04" } },
  { $unwind: { path: "$seances",
               preserveNullAndEmptyArrays: true } },
  { $project: { titre: 1, seances: 1 } }
])
// [ { _id: 'F04',
//     titre: 'Les Glaneurs et la Glaneuse' } ]
```

</div>
</div>

<div class="warn" style="margin-top: 1rem;">

Un document dont le tableau est **vide ou absent** ne sort pas de `$unwind` : après un `$group`, il manque au résultat (un film sans séance, une pièce sans mesure). Le TP2 y revient.

</div>

<!--
Exécuté sur MongoDB 9.0.4, sur les films rechargés. Le même comportement vaut pour un champ absent ou à null.

Piège classique dans un tableau de bord : une pièce sans mesure, un film sans séance n'apparaissent pas dans le résultat, au lieu d'apparaître avec 0.
-->

---

## Le pipeline, document par document

<img src="assets/schemas/s2-pipeline.svg" alt="Pipeline d'agrégation de gauche à droite. La collection capteurs contient 5 documents : C1 Salon, C2 Salon, C3 Cuisine, C4 Salon et C5 Chambre ; C2, encadré en rouge, est un capteur d'humidité, les autres mesurent la température. L'étape $match filtre sur le type (WHERE) : C2 est écarté, il reste 4 documents. L'étape $unwind crée un document par mesure (JOIN) : 3 pour C1, 2 pour C3, 1 pour C4 et 3 pour C5, soit 9 documents. L'étape $group crée un document par pièce (GROUP BY), 3 documents dans un ordre quelconque : Cuisine étage 0, moyenne 20.5, nb 2 ; Salon étage 0, moyenne 20.75, nb 4 ; Chambre étage 1, moyenne 17.5, nb 3. L'étape $sort trie par moyenne décroissante (ORDER BY) : le résultat contient toujours 3 documents, dans l'ordre Salon, Cuisine, Chambre." style="display:block; width:100%; margin:0.2em auto 0;">

<p class="petit centre" style="margin-top: 0.5rem;">Le nombre de documents change à chaque étape : <b>5 → 4 → 9 → 3 → 3</b>. <code>&#36;project</code> est omis : il change la forme, pas le nombre.</p>

<!--
Diapo de référence (hors minutage).

Lire le schéma de gauche à droite, par les nombres en haut des colonnes : $match en retire (5 puis 4), $unwind en crée (9, un par mesure), $group les rassemble (3, un par pièce), $sort ne fait que les réordonner (toujours 3).

Le schéma omet $project, qui change la forme des documents, pas leur nombre ; ses moyennes ne sont donc pas arrondies. C2, encadré en rouge, est le capteur d'humidité que $match écarte.
-->
