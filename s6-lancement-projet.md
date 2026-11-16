---
marp: true
theme: r510
paginate: true
lang: fr
title: "Séance 6 : lancement du projet"
description: "R5.Real.10, point cours de la séance 6 (lancement du projet, sceaux P1 à P3)"
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
p.clin { font-size: 0.66em; color: #9a6400; margin-top: 0.4em; }
</style>

# Lancer le projet

**R5.Real.10 - Nouveaux paradigmes de base de données**

Séance 6 · le projet · semaine du 7 décembre 2026

<p class="question">Une même réponse pour le navigateur, le test et l'agent IA : où écrire le calcul pour qu'elle soit partout la même, et comment savoir qu'elle est juste ?</p>

<p class="clin">« La Greffe ne juge pas un prénom : elle l'enregistre. »</p>

<!--
(20 s)

Question directrice de la séance : « Une même réponse pour le navigateur, le test et l'agent IA : où écrire le calcul pour qu'elle soit partout la même, et comment savoir qu'elle est juste ? » Réponse dans « À retenir » (diapo 22) : dans un seul service, appelé par la route et par l'outil ; elle est juste quand le test d'acceptation est vert, sans valeur écrite en dur, puisque le correcteur automatique rejoue tout sur le jeu privé E′.

La ligne orange est le seul clin d'œil à l'univers du projet (la règle de la Greffe, issue 00) : ne pas raconter le récit, les équipes le liront dans l'issue.

Un seul temps, en début de séance, 15 min 55 (somme des durées notées en tête de chaque diapo) :
- titre, objectifs, données (diapos 1 à 3) : 1 min 40 ;
- partie A, une vérité, quatre fenêtres (diapos 4 à 8) : 3 min 35, prédiction diapo 5 ;
- partie B, lire un contrat (diapos 9 à 13) : 3 min 15, prédiction diapo 11 ;
- partie C, le pilote (diapos 14 à 17) : 2 min 50, prédiction diapo 16 ;
- partie D, le contrat exécutable (diapos 18 à 21) : 2 min 30, prédiction diapo 20 ;
- « À retenir » (22), « À vous » (23), les guides (24), « Des questions ? » (25) : 2 min 05.

Version courte, environ 15 min 10 : passer la diapo 13 (l'ordre des contrôles est déjà dans la réponse de la diapo 12) et la diapo 24 (les guides sont cités diapo par diapo).

Pas d'annexe : ce qui ne tient pas ici est dans les douze guides du projet (docs/guides/ du dépôt de chaque équipe), cités diapo par diapo.

L'exemple est inventé : le ciné-club de S1 à S3 (collection films, avec ses notes) et une petite API écrite pour le cours (trois routes, un outil MCP, un mode seed qui construit sa collection précalculée), jamais les prénoms ni un sceau sous un autre nom. Aucun chiffre du projet n'est cité : les données sont en cours de recalcul.

Tout a été exécuté le 16/11/2026 : mongosh sur mongo:9.0.4 ; le Java avec le pilote mongodb-driver-sync 5.14.0, Javalin 7.2.4 et le SDK MCP 2.1.0 (les versions du pom.xml du projet), compilé et lancé avec ./mvnw sur Java 25, contre la même base ; les lignes curl -i sur cette API ; le message d'échec par une copie de Rapport et de ComparateurJson (classes du gabarit, src/test/java/…/acceptation/) dans un test JUnit joué par ./mvnw test. Le gestionnaire d'erreurs de l'API d'exemple est celui de Serveur, recopié. Les résultats affichés sont ceux obtenus. Le script des films est dans les notes de la diapo 3.
-->

---

<!-- header: Séance 6 · objectifs -->

## Une réponse, trois clients : ce que la séance construit

<div class="bandeau" style="font-size: 0.82em; text-align: left;">
❓ Où écrire le calcul pour que la réponse soit partout la même, et comment savoir qu'elle est juste ?
</div>

<div class="g2" style="margin-top: 0.8rem; font-size: 0.74em; align-items: stretch;">
<div class="carte vert">
<b class="t">🎯 À la fin de la séance, vous saurez</b>

1. **situer** chaque morceau de code : pipeline, service, route, outil ;
2. **lire** une ligne de contrat et dire **qui** produit chaque statut ;
3. **passer** du playground au service Java, et **précalculer** sans doublon ;
4. **faire passer** un test d'acceptation du rouge au vert.

</div>
<div class="carte">
<b class="t">🧠 Déjà vu</b>

- **S1, S3** : les films (S1), leurs notes (S3)
- **S3** : classes d'aide `Filters`, `Aggregates` ; `find(…)` prépare, `into(…)` envoie ; une route Javalin, le 404 décidé par la route
- **S4** : `$merge` et `$out` ; `first()` qui rend `null`

</div>
</div>

<!--
(50 s)

Lire la question directrice : les quatre parties y répondent. A : où écrire le calcul ; B : ce que le contrat promet, et qui le tient ; C : comment le pilote envoie le pipeline ; D : comment savoir que c'est juste.

Les objectifs suivent les couches de l'issue 00 (« Ce qui est fourni, ce que vous construisez ») : modèle et pipeline, service, route, vue, outil MCP. Ce qui est neuf : le service lève l'erreur et la route la traduit (en S3, la route décidait du 404) ; les statuts 422 et 501 ; Document.parse ; toCollection() ; les tests d'acceptation.

« Déjà vu » : les films sont ceux de S1, avec les notes (source, note, date) qu'ils ont reçues en S3 ; find(…) prépare, into(…) envoie, et "$champ" lit une valeur (S3, partie 6, et TP2, exercices 15 à 18) ; la route avec pathParam et queryParam, le 404 posé par ctx.status(404) (S3) ; explain("executionStats") et la règle ESR (S3, partie 4) : la suite est dans le guide regulateur-et-explain.md, pas ici ; $merge et $out (S4, prédiction « resumes ») ; find(…).first() qui rend null, getList avec une valeur par défaut (TP3, exercice 12) et la route du bonus 8 avec son 404 ; les routes et méthodes Java du TP2 et du TP3 étaient notées par le correcteur automatique. Le bonus 12 du TP4 (paramètres du pilote Neo4j) ne sert qu'au trésor : ne pas le citer à l'écran.

Ce qu'on ne remontre pas : l'aller-retour navigateur, Javalin, pilote, MongoDB (S3) ; la table des options de $merge (S4) ; la correspondance mongosh vers Java (annexe de S3).
-->

---

<!-- header: Séance 6 · les données -->

## Le projet, et le ciné-club du cours

<style scoped>
table { display: table; width: 100%; font-size: 0.92em; }
td, th { padding: 0.2em 0.5em; }
</style>

<div class="cols" style="grid-template-columns: 0.85fr 1.15fr; align-items: stretch; font-size: 0.8em;">
<div class="carte orange">
<b class="t">📜 Le projet</b>

Les **prénoms** donnés en France depuis 1900, d'après le fichier de l'INSEE ; en équipe, dans un codespace.

- **7 sceaux**, P1 à P7 : P1 à P3 dès aujourd'hui
- puis des **quêtes secondaires**, au choix
- Java 25, Javalin, le pilote, MongoDB 9.0 et un serveur **MCP**

</div>
<div>

| titre | annee | duree | realisateur | notes |
|---|---|---|---|---|
| Le Voyage de Chihiro | 2001 | 125 | Miyazaki | 5, 4 |
| Les Glaneurs et la Glaneuse | 2000 | 82 | Varda | 4 |
| La Haine | 1995 | 98 | Kassovitz | 5, 2 |
| Amélie Poulain | 2001 | 122 | Jeunet | *aucune* |

<div class="box" style="margin-top: 0.5rem;">🧪 Les films de S3, et une <b>petite API</b> inventée pour le cours : trois routes, un outil MCP.</div>

</div>
</div>

<!--
(30 s)

Le projet en une carte, sans chiffre : les données sont celles du fichier des prénoms de l'INSEE (édition 2025, de 1900 à 2025), croisé avec un catalogue d'influences ; le détail est dans l'issue 00, que les équipes lisent en premier. Le récit (la Greffe, l'Almanach, les sceaux) habille les issues ; les contrats, eux, sont écrits sans métaphore. Vocabulaire du cours : « le sceau P1 » pour une mission de la quête principale (P1 à P7), « mission » pour un sceau ou une quête secondaire.

Les exemples ne portent jamais sur les prénoms. Ce sont les films de S3 (même état : le réalisateur en chaîne, les notes en tableau de documents, source, note, date), dans une base cineclub, servis par une petite API écrite pour le cours : GET /api/films?annee=&limite=, GET /api/films/{titre}/note, GET /api/realisateurs/stats (qui lit stats_realisateurs, construite par le mode seed de l'API), et l'outil MCP note_film. Elle n'existe pas dans le dépôt du projet.

Script, dans un playground (il vide d'abord la collection) :

use('cineclub');
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
db.stats_realisateurs.drop();
-->

---

<!-- header: Partie A · situer -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie A - 🧱 Une vérité, quatre fenêtres

Où écrire un calcul pour qu'il soit le même partout ?

<!--
(10 s)

La règle « une vérité, quatre fenêtres » de l'issue 00, et la Definition of Done commune : une seule implémentation par calcul, partagée par la route et l'outil.
-->

---

## ❓ Une même note, calculée deux fois

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
.g4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.8em; align-items: stretch; }
.g4 .carte { font-size: 0.76em; text-align: center; }
</style>

<p class="petit" style="margin: 0 0 0.3rem;">La route sert déjà la note d'un film. On ajoute l'outil MCP <code>note_film</code>, écrit à part :</p>

<div class="dense">

```java
// l'outil note_film, écrit à part : il recalcule en Java
Document f = films.find(Filters.eq("titre", titre)).first();
List<Document> notes = f.getList("notes", Document.class);
double somme = 0;
for (Document n : notes) somme += n.getInteger("note");
long moyenne = Math.round(somme / notes.size());
```

</div>

| Film | la route `GET /api/films/{titre}/note` | l'outil `note_film` |
|---|---|---|
| La Haine | `3.5` | **?** |
| Amélie Poulain, sans note | `null` | **?** |

<p style="font-size: 0.78em; margin: 0.4rem 0 0.3rem;">Que répond l'outil pour La Haine ? Pour Amélie, sans note ?</p>

<div class="g4">
<div class="carte"><b class="t">A</b><code>null</code></div>
<div class="carte"><b class="t">B</b><code>0</code></div>
<div class="carte"><b class="t">C</b><code>NaN</code></div>
<div class="carte"><b class="t">D</b><code>ArithmeticException</code></div>
</div>

<!--
(35 s)

Le besoin, tenté avec ce qu'on sait : en S3, la route appelait une méthode qui faisait la requête. Ici, un second client (l'agent IA, par l'outil MCP) pose la même question, et quelqu'un réécrit le calcul « à sa façon ». La colonne de la route est remplie (exécuté : {"titre":"La Haine","moyenne":3.5,"nombre":2} et {"titre":"Amélie Poulain","moyenne":null,"nombre":0}, le $avg de MongoDB sur un tableau vide donne null).

Faire voter : d'abord La Haine (3.5 ou 4 ?), puis Amélie, à main levée, parmi les quatre choix. Réponse sur la diapo suivante.
-->

---

## Réponse : 4 et 0. Deux calculs, deux réponses

<style scoped>
table { display: table; width: 100%; font-size: 0.74em; }
</style>

| Film | la route `GET /api/films/{titre}/note` | l'outil `note_film` |
|---|---|---|
| La Haine | `3.5` | `4` |
| Amélie Poulain, sans note | `null` | `0` |

<div class="g2" style="margin-top: 0.6rem; font-size: 0.92em; align-items: stretch;">
<div class="box">

`Math.round(3.5)` donne **4**. Sans note, `0.0 / 0` donne `NaN`, **sans exception** (elle n'existe que pour les entiers), et `Math.round(NaN)` donne **0**.

</div>
<div class="warn">

Le test de **parité** est rouge, et chaque correction est à faire **deux fois**. Le calcul se fait dans MongoDB, **une** fois.

</div>
</div>

<!--
(45 s)

Exécuté (Java 25) : le code de l'outil donne 4 pour La Haine et 0 pour Amélie ; pas à pas, System.out.println(0.0 / 0) affiche NaN, Math.round(Double.NaN) donne 0, Math.round(3.5) donne 4 ; une division entière par zéro, elle, lève java.lang.ArithmeticException: / by zero (somme est un double, d'où NaN).

Deux défauts à la fois : deux résultats pour une même question (le test de parité du projet compare donnees de l'outil à la réponse de la route : rouge), et un calcul fait par une boucle Java, ce que la Definition of Done interdit. Un bug corrigé dans l'un reste dans l'autre.

Pont avec le Codex (D16) : null, jamais NaN ni Infinity ; une division par zéro s'intercepte dans le pipeline.
-->

---

## Un calcul, quatre fenêtres

<img src="assets/schemas/s6-une-verite.svg" alt="Un calcul, quatre fenêtres, sur la petite API du ciné-club. MongoDB fait le calcul dans un pipeline. Le service Java note(titre) l'exécute : il reçoit du texte, rend un Document, ou lève une ErreurMetier. Le service est appelé par deux portes : 1, la route GET /api/films/{titre}/note, fournie, qui fait seulement ctx.json(note(…)) ; 2, l'outil MCP note_film, qui fait seulement Enveloppe.resultat(note(…), …). Entre les deux, le même Json.MAPPER donne le même JSON. La route sert 3, la vue (la fiche du film dans le navigateur) ; l'outil sert l'agent IA (Copilot en mode agent). 4, le test d'acceptation appelle la route et l'outil : la route doit donner l'attendu, l'outil la même chose que la route (parité)." style="display:block; width:100%; margin:0.1rem auto 0;">

<div class="box" style="margin-top: 0.4rem; font-size: 0.74em;">

**Une seule implémentation** : le pipeline, appelé par **un** service. La route et l'outil n'ajoutent ni requête ni calcul : ils **traduisent**. 📜 Issue 00 ; `docs/guides/architecture.md`.

</div>

<!--
(1 min)

Suivre le schéma de gauche à droite. Le calcul vit dans MongoDB (le pipeline). Le service Java l'exécute : il reçoit ses paramètres en texte, tels qu'ils arrivent dans l'URL ou dans les arguments de l'outil, et rend un org.bson.Document, dont l'ordre des champs est celui du contrat. Deux portes l'appellent, la route et l'outil, et passent par le même convertisseur (Json.MAPPER, fourni par le gabarit) : le JSON est le même, la parité est automatique. La vue (le tableau de bord) appelle la route ; l'agent IA appelle l'outil. Le test d'acceptation regarde par les deux portes.

Dans le gabarit, chaque sceau a sa classe (p1/Forge.java, p2/Podium.java…), qui implémente l'interface Sceau : un service par route, la méthode routes, déjà écrite (le contrat est public), et la méthode outils. Les quatre fenêtres de l'issue 00 : la route, l'outil, la vue, le test.

Renvoi : issue 00 (« Ce qui est fourni, ce que vous construisez ») et le guide docs/guides/architecture.md ; Veillée V1 (ARCHITECTURE.md).
-->

---

## Le service lève, la route et l'outil traduisent

<p class="etiquette">le service : en S3, la route décidait du 404 ; ici, le service le lève</p>

<div class="dense">

```java
public Document note(String titre) {                                // texte en entrée
    Document note = films.aggregate(List.of(
            Aggregates.match(Filters.eq("titre", titre)),
            Aggregates.project(Projections.fields(Projections.excludeId(),
                    Projections.include("titre"),
                    Projections.computed("moyenne", new Document("$avg", "$notes.note")),
                    Projections.computed("nombre", new Document("$size", "$notes"))))))
            .first();
    if (note == null) {
        throw ErreurMetier.introuvable("Film inconnu : " + titre);  // 404, ou isError
    }
    return note;                                                     // un Document en sortie
}
```

</div>

<div class="cols" style="margin-top: 0.3rem; align-items: start;">
<div class="dense">

<p class="etiquette">la route, fournie</p>

```java
routes.get("/api/films/{titre}/note",
    ctx -> ctx.json(note(ctx.pathParam("titre"))));
// Titanic : 404 {"erreur":"Film inconnu : Titanic"}
```

</div>
<div class="dense">

<p class="etiquette">l'outil MCP</p>

```java
Oracle.outil(noteFilm, args -> Enveloppe.resultat(
    // arguments à contrôler comme l'URL
    note((String) args.get("titre")),
    List.of(), SOURCE, "Note du film"))
// Titanic : isError true, "donnees":null
```

</div>
</div>

<!--
(1 min 05)

Trois morceaux de la petite API, compilés et exécutés.

1. Le service : une agrégation, un Document ou une ErreurMetier. ErreurMetier.introuvable (404), invalide (400) et horsBornes (422) sont fournies par le gabarit. Le service ne connaît ni ctx ni HTTP.
2. La route, fournie dans chaque classe de sceau : une ligne, qui passe le texte au service. Le gestionnaire d'erreurs du gabarit (Serveur) transforme l'ErreurMetier en {"erreur": "..."} avec son statut. Exécuté : GET /api/films/La%20Haine/note répond 200 {"titre":"La Haine","moyenne":3.5,"nombre":2} ; Titanic, 404 {"erreur":"Film inconnu : Titanic"}.
3. L'outil : Oracle.outil (gabarit) appelle le même service et transforme l'ErreurMetier en isError: true. Exécuté : pour La Haine, structuredContent = {"donnees":{"titre":"La Haine","moyenne":3.5,"nombre":2},"avertissements":[],"source":"…"} ; pour Titanic, isError true et {"donnees":null,"avertissements":["Film inconnu : Titanic"],"source":"…"}. La description de l'outil et son schéma d'entrée (permissif) sont dans le guide mcp-et-agent.md ; le client JUnit d'abord, Copilot ensuite (crédits limités).

Le pont avec S3 (l'étiquette du haut) : là-bas, la route décidait du 404 (ctx.status(404)) et convertissait avec queryParamAsClass. Ici, les paramètres arrivent en texte jusqu'au service, pour que l'outil les valide exactement comme la route (le commentaire de l'outil : un argument MCP se contrôle comme un paramètre d'URL ; le cast (String) suffit pour l'exemple) : c'est la classe Parametres du gabarit, publique et livrée vide, à écrire une fois, en premier (sexe, entier, bornes). Ne pas en montrer le code.
-->

---

<!-- header: Partie B · lire -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie B - 📜 Lire un contrat

Qui choisit le statut d'une réponse ?

<!--
(10 s)

Les routes sont déjà écrites dans le gabarit : on n'apprend pas ici à écrire une route, mais à lire ce que le contrat promet et à savoir qui le tient.
-->

---

## Une ligne de contrat : verbe, chemin, paramètres, statut

<style scoped>
table { display: table; width: 100%; font-size: 0.66em; }
td code { white-space: nowrap; }
</style>

| Route | Paramètres | Réponse | Erreurs |
|---|---|---|---|
| `GET /api/films` | `annee` : entier de [1895, 2026], facultatif ; `limite` : de 1 à 10 (5 par défaut) | 200 `{"resultats": […]}`, triés par titre | 400, 422 |
| `GET /api/films/{titre}/note` | `titre`, dans le chemin | 200 `{titre, moyenne, nombre}` | 404 |
| `GET /api/realisateurs/stats` | aucun | 200 `{"resultats": […]}`, lu dans `stats_realisateurs`, construite par `seed` | |

<div class="cols-62" style="margin-top: 0.4rem; align-items: start;">
<div class="dense">

```text
$ curl -i 'http://localhost:7070/api/films/La%20Haine/note'
HTTP/1.1 200 OK
Date: Mon, 16 Nov 2026 09:41:14 GMT
Content-Type: application/json
Content-Length: 45

{"titre":"La Haine","moyenne":3.5,"nombre":2}
```

</div>
<div class="box" style="font-size: 0.7em;">Le <b>chemin</b> désigne la ressource ; la <b>requête</b> (<code>?annee=</code>) précise, et peut manquer. Toujours un <b>objet</b> au premier niveau. <code>-i</code> montre le statut.</div>
</div>

<!--
(1 min 05)

Le contrat de notre petite API, écrit comme ceux des issues P1 à P3 : verbe, chemin, paramètres avec leurs bornes et leur valeur par défaut, forme de la réponse, erreurs. La troisième route lit une collection précalculée : stats_realisateurs, construite par le mode seed de l'API (exécuté : « seed : stats_realisateurs construite, 3 documents »), comme le socle du projet est construit par java -jar target/app.jar seed. Elle sert à la partie C. Un paramètre de chemin ({titre}) désigne la ressource ; un paramètre de requête (?annee=) précise la demande et peut manquer. Règles communes du Codex : JSON en UTF-8, toujours un objet au premier niveau (un tableau va dans un champ : {"resultats": [...]}), noms des routes et des champs exactement ceux du contrat.

La ligne curl a été lancée sur l'API d'exemple, servie sur le port 7070 : ce sont la réponse et les en-têtes obtenus. L'espace du titre s'encode %20 dans l'URL (un accent : %C3%A9). Autre réponse exécutée : curl -i 'http://localhost:7070/api/films?annee=2001&limite=5' donne 200 et {"resultats":[{"titre":"Amélie Poulain","annee":2001,"duree":122},{"titre":"Le Voyage de Chihiro","annee":2001,"duree":125}]}.

Le mémo curl complet (méthodes, -d, en-têtes, encodage), les statuts 201 et 204, l'en-tête Location et un identifiant ObjectId dans le chemin : guide docs/guides/api-http.md (P6, en S7).

Renvoi : les contrats des issues P1 à P3, sections « Contrat » et « Routes » ; le Codex, « Règles communes aux réponses ».
-->

---

## ❓ Quel statut pour chacune de ces URL ?

<style scoped>
.g4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.8em; align-items: stretch; }
.carte { font-size: 0.8em; text-align: center; }
</style>

```text
GET /api/films?annee=2001&limite=0
GET /api/films?annee=1850
GET /api/films?annee=2024
GET /api/films/Titanic/note
```

<p style="font-size: 0.8em;">À choisir pour chaque URL (un statut peut servir deux fois) :</p>

<div class="g4" style="margin-top: 0.3rem;">
<div class="carte"><b class="t">200</b>tout va bien</div>
<div class="carte"><b class="t">400</b>refusé par le contrat</div>
<div class="carte"><b class="t">404</b>inconnu</div>
<div class="carte"><b class="t">422</b>valide, mais hors de ce que les données couvrent</div>
</div>

<!--
(35 s)

Faire voter URL par URL, à main levée, sans commenter. Rappel du contrat (diapo précédente) : annee dans [1895, 2026], la période que couvre le catalogue ; limite de 1 à 10, le domaine que fixe le contrat ; aucun film de 2024 dans la collection (diapo 3). Réponse sur la diapo suivante.
-->

---

## Réponse : le contrat, puis les données, puis l'existence

<style scoped>
table { display: table; width: 100%; font-size: 0.66em; }
td code { white-space: nowrap; }
</style>

| URL | Statut | Corps |
|---|---|---|
| `?annee=2001&limite=0` | **400** | `{"erreur":"« limite » doit être un entier de 1 à 10 : 0"}` |
| `?annee=1850` | **422** | `{"erreur":"« annee » doit être dans [1895, 2026] : 1850"}` |
| `?annee=2024` | **200** | `{"resultats":[]}` |
| `/api/films/Titanic/note` | **404** | `{"erreur":"Film inconnu : Titanic"}` |
| `?annee=1850&limite=0` | **400** | le contrat d'abord : le message de `limite` |

<div class="g2" style="margin-top: 0.5rem; font-size: 0.88em; align-items: stretch;">
<div class="warn">

**Jamais ramené en silence** : `limite=0` n'est pas « corrigé » en 1. Une liste **vide** n'est pas un 404.

</div>
<div class="box">

**400** : le contrat refuse la valeur (`limite` de 1 à 10). **422** : la valeur est valide, mais les données ne la couvrent pas (1895 à 2026).

</div>
</div>

<!--
(55 s)

Les cinq réponses ont été exécutées sur l'API d'exemple (curl -s) : statuts et corps obtenus. La cinquième ligne n'était pas dans la prédiction : elle montre l'ordre des contrôles, ce que le contrat refuse (400) avant ce que les données ne couvrent pas (422).

Réponses fréquentes à corriger : 200 pour limite=0 (la limite ramenée à 1 en silence : le contrat l'interdit, c'est écrit dans P1) ; 404 pour 2024 (une recherche sans résultat est une réponse normale, 200 avec une liste vide, comme en S3 ; le 404 est pour une ressource désignée par le chemin et inconnue) ; 400 pour 1850 (c'est un entier valide pour le contrat : seules les données ne couvrent pas cette année, d'où 422).

Le Codex, D17 (version du 16/11) : 400 {"erreur": "..."} pour un paramètre que le contrat refuse (absent, mal formé, hors d'une énumération ou hors du domaine fixé par la fiche, par exemple limite) ; 422 pour une valeur valide mais hors de ce que les données ou un précalcul couvrent (une année hors de [1900, 2025] dans le projet) ; 404 pour un prénom ou un identifiant inconnu. Ordre : 400, puis 422, puis la cohérence entre paramètres (400), puis 404 ; un appel qui cumule deux erreurs reçoit le statut de la première. Les messages sont libres (les tests ne comparent pas le texte de l'erreur, seulement le statut et la présence du champ erreur), sobres et en français.

Sans contrôle, ce qui casse donne un 500 : par exemple Integer.parseInt("deux-mille") lève une exception (S3, annexe). L'API d'exemple répond 400 {"erreur":"« annee » n'est pas un entier : deux-mille"}.
-->

---

## Qui produit chaque statut ?

<img src="assets/schemas/s6-statuts.svg" alt="Qui produit chaque statut d'une réponse, dans l'ordre des contrôles du Codex (D17). Le service lève une ErreurMetier, dans cet ordre : 1, le contrat accepte-t-il la valeur (un entier de 1 à 10 pour limite) ? sinon 400, par exemple limite=0 ; 2, les données la couvrent-elles (le catalogue va de 1895 à 2026) ? sinon 422, par exemple annee=1850 ; 3, les paramètres sont-ils cohérents entre eux (debut avant fin) ? sinon 400 ; 4, la ressource existe-t-elle (le film est-il connu) ? sinon 404, par exemple Titanic. Enfin le service rend le calcul, un Document : 200, même pour une liste vide ; 201 et 204 sont posés par la route, fournie. En bas, ce que le gabarit répond sans que vous l'écriviez : 404 avec routeAbsente pour une route non déclarée, 501 quand le service n'est pas encore écrit (Sceau.aFaire), 500 pour une exception non prévue, 503 quand MongoDB refuse la requête." style="display:block; width:100%; margin:0.1rem auto 0;">

<p class="petit" style="margin-top: 0.4rem;">📜 La section « Erreurs » de chaque contrat ; <code>docs/guides/api-http.md</code>.</p>

<!--
(30 s)

L'ordre des contrôles est le même partout dans le projet, et il est écrit dans le Codex (D17) : ce que le contrat refuse (400), ce que les données ne couvrent pas (422), la cohérence entre paramètres (400, par exemple un debut après la fin d'une période), l'existence (404). La troisième case n'a pas d'exemple dans notre API (un seul paramètre de période) : « debut > fin » est l'exemple type.

Qui produit quoi : le service lève une ErreurMetier, la route (fournie) ne fait que ctx.json, le gestionnaire de Serveur répond {"erreur": "..."} avec le statut. Les routes du gabarit posent aussi 201 et l'en-tête Location (création), 204 (suppression) : ce sont des écritures, P6 en S7 (guide api-http.md).

En bas, ce que le gabarit répond sans vous : 501 {"erreur": "P1 : à faire"} tant que le service lève Sceau.aFaire("P1") (c'est l'état de départ de toutes les routes des sceaux) ; 500 pour une exception non prévue (la trace est dans le journal du serveur) ; 503 quand MongoDB refuse la requête (exécuté sur l'API d'exemple, qui recopie ce gestionnaire : un $group avec un opérateur mal écrit répond 503 {"erreur":"MongoDB ne répond pas ou a refusé la requête"}) ; 404 avec "routeAbsente": true pour une route qui n'existe pas (exécuté : GET /api/film donne {"erreur":"Route inconnue : GET /api/film","routeAbsente":true}), que le tableau de bord affiche « à brancher ».
-->

---

<!-- header: Partie C · coder -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie C - ☕ Le pilote

Comment passer du playground au service, sans rien perdre en route ?

<!--
(10 s)

S6 ne montre que des lectures et un précalcul (sceaux P1 à P3). Les écritures (insertOne, updateOne, getMatchedCount, replaceOne) sont dans le guide docs/guides/mongodb-java.md, pour P6 en S7.
-->

---

## Le pipeline du playground, en Java : deux écritures

<div class="cols" style="align-items: start;">
<div class="dense">

<p class="etiquette">le playground</p>

```js
db.films.aggregate([
  { $unwind: "$notes" },
  { $group: { _id: "$realisateur",
              moyenne: { $avg: "$notes.note" },
              nombre: { $sum: 1 } } },
  { $sort: { _id: 1 } }
])
// [ { _id: 'Kassovitz', moyenne: 3.5, nombre: 2 },
//   { _id: 'Miyazaki', moyenne: 4.5, nombre: 2 },
//   { _id: 'Varda', moyenne: 4, nombre: 1 } ]
```

</div>
<div class="dense">

<p class="etiquette">le même <code>&#36;group</code>, deux fois</p>

```java
Bson aide = Aggregates.group("$realisateur",
        Accumulators.avg("moyenne", "$notes.note"),
        Accumulators.sum("nombre", 1));
Bson texte = Document.parse("""
        {$group: {_id: '$realisateur',
                  moyenne: {$avg: '$notes.note'},
                  nombre: {$sum: 1}}}""");
aide.toBsonDocument().equals(texte.toBsonDocument())
// true
```

</div>
</div>

<div class="warn" style="margin-top: 0.4rem; font-size: 0.74em;">

`Document.parse` colle le playground tel quel, mais le compilateur ne le lit pas : `{$avrg: …}` compile, et MongoDB le refuse **à l'exécution** (erreur 15952, d'où un 503). `Accumulators.avrg`, lui, ne compile pas.

</div>

<!--
(1 min 15)

Deux écritures du même $group, toutes deux des Bson, que aggregate accepte dans la même List.of(…). À gauche de la diapo, le playground (exécuté sur mongo:9.0.4) ; à droite, le Java exécuté avec le pilote 5.14.0. Les deux Bson donnent le même document : {"$group": {"_id": "$realisateur", "moyenne": {"$avg": "$notes.note"}, "nombre": {"$sum": 1}}}, et le même résultat que le playground, précédés d'un Aggregates.unwind("$notes") et suivis d'un tri : [Document{{_id=Kassovitz, moyenne=3.5, nombre=2}}, Document{{_id=Miyazaki, moyenne=4.5, nombre=2}}, Document{{_id=Varda, moyenne=4.0, nombre=1}}] (mongosh affiche 4, Java 4.0 : un double dans les deux cas).

Les classes d'aide sont celles de S3 (Aggregates, Accumulators, Filters). Document.parse avec un bloc de texte """…""" (Java 15 et plus) recopie le playground : les clés sans guillemets et les chaînes entre apostrophes sont admises. Avantage : le pipeline mis au point dans le playground passe tel quel ; prix : une faute de frappe n'apparaît qu'à l'exécution. Exécuté : Document.parse("{$group: {_id: '$realisateur', moyenne: {$avg: '$notes.note'}}") (une accolade oubliée) lève org.bson.json.JsonParseException: JSON reader was expecting a name but found '<eof>'. ; {$avrg: …} lève com.mongodb.MongoCommandException … error 15952 (Location15952): 'unknown group operator '$avrg'', que le gestionnaire du gabarit traduit en 503.

Les deux se valent ; on peut les mélanger dans un même pipeline. Pour une expression sans classe d'aide ($sortArray, $cond…), new Document(…) ou Document.parse.
-->

---

## ❓ Le précalcul : que contient `stats_realisateurs` ?

<style scoped>
.g3 { gap: 0.8em; align-items: stretch; }
.carte { font-size: 0.78em; text-align: center; }
</style>

<div class="dense">

```java
films.aggregate(List.of(                          // stats_realisateurs n'existe pas encore
        Aggregates.unwind("$notes"),
        Aggregates.group("$realisateur",
                Accumulators.avg("moyenne", "$notes.note"), Accumulators.sum("nombre", 1)),
        Aggregates.merge("stats_realisateurs")));
System.out.println(base.getCollection("stats_realisateurs").countDocuments());
```

</div>

<p style="font-size: 0.8em;">Qu'affiche la dernière ligne ?</p>

<div class="g3" style="margin-top: 0.3rem;">
<div class="carte"><b class="t">A</b>3 : un document par réalisateur noté</div>
<div class="carte"><b class="t">B</b>0</div>
<div class="carte"><b class="t">C</b>une exception : il manque <code>into(…)</code></div>
</div>

<!--
(30 s)

Faire voter à main levée, sans commenter. Rappel de S4 : $merge, en dernière étape, écrit chaque document du résultat dans la collection into, et ne renvoie rien à lire. Réponse : B, sur la diapo suivante.
-->

---

## Réponse : 0. Rien n'est parti

<div class="dense">

```java
// sans .toCollection()
0
// avec .toCollection(), lancé deux fois de suite
3
3
```

</div>

<div class="cols" style="margin-top: 0.4rem; font-size: 0.74em; align-items: stretch;">
<div class="carte rouge"><b class="t"><code>aggregate(…)</code> prépare</b> Comme <code>find(…)</code> sans <code>into(…)</code> (S3) : rien n'est envoyé, et aucune erreur. <code>&#36;merge</code> n'a rien à rendre : <b><code>toCollection()</code></b> lance le pipeline.</div>
<div class="carte vert"><b class="t">Rejouable, sans doublon</b> Relancé, <code>&#36;merge</code> retrouve chaque <code>_id</code> et met à jour le document : toujours 3. <code>&#36;out</code> remplacerait la collection (S4).</div>
</div>

<p class="petit" style="margin-top: 0.5rem;">📜 P1 : <code>seed</code> construit le socle, rejouable. Les écritures (<code>insertOne</code>, <code>updateOne</code>, <code>getMatchedCount()</code>) : <code>docs/guides/mongodb-java.md</code>, pour P6.</p>

<!--
(55 s)

Exécuté avec le pilote 5.14.0, stats_realisateurs supprimée au départ : sans .toCollection(), countDocuments() affiche 0, et la base ne contient que films (listCollectionNames : [films]) : le pipeline n'est jamais parti. aggregate(…) renvoie un AggregateIterable, qui n'envoie rien tant qu'on ne le parcourt pas (into, first, une boucle) ou qu'on ne lance pas toCollection(). Le piège est silencieux : pas d'erreur, une collection vide, et des routes qui répondent des listes vides.

Avec .toCollection() (même code, l'appel ajouté à la fin), lancé deux fois de suite : 3, puis 3. $merge sur l'_id (le réalisateur, sortie du $group) met à jour le document qui existe déjà au lieu d'en créer un second : c'est ce qui rend seed rejouable « sans doublon » (Definition of Done de P1). $out remplace toute la collection (et garde ses index) : les deux conviennent pour un socle reconstruit en entier, le choix est celui de S4. Contenu, exécuté : Kassovitz 3.5 (2 notes), Miyazaki 4.5 (2), Varda 4.0 (1) ; Jeunet n'a aucune note, $unwind l'a écarté.

Ce que $merge ne fait pas : avec ses options par défaut (whenMatched: "merge", whenNotMatched: "insert"), il garde un document que le pipeline ne produit plus, comme E4 dans la prédiction « resumes » de S4. Exécuté : un document Truffaut ajouté à la main dans stats_realisateurs y reste après un nouveau seed (« seed : stats_realisateurs construite, 4 documents »). Pour un socle reconstruit en entier, $out (qui remplace la collection) ou un drop avant le $merge.

Pour un pipeline long sur de gros volumes, allowDiskUse(true) avant toCollection() : guide mongodb-java.md.

Dans le projet : la construction du socle commence dans Construction.construireSocle, appelée par java -jar target/app.jar seed. Ne pas en dire plus.
-->

---

<!-- header: Partie D · tester -->

<!-- _class: lead -->
<!-- _header: "" -->

# Partie D - 🚦 Le contrat exécutable

Comment savoir qu'une réponse est juste ?

<!--
(10 s)

Les tests d'acceptation de l'issue 00 : « le cahier des charges exécutable ».
-->

---

## Du rouge au vert : le test d'acceptation

<img src="assets/schemas/s6-rouge-vert.svg" alt="Du rouge au vert, avec un test d'acceptation. Une fois : 1, retirer @Disabled du test de la mission ; 2, construire le jar avec ./mvnw -q package -DskipTests ; 3, charger les données et construire les collections avec java -jar target/app.jar seed. Puis la boucle : 4, jouer le test avec ./mvnw test -Dgroups=P1 ; s'il est rouge, 5, lire le message et corriger le service, puis rejouer 4 si seul le service a changé. Si c'est un pipeline de construction qui a changé, repartir de 2 puis 3 avant de rejouer le test. Quand le test est vert : 6, une Pull Request relue, qui référence l'issue (Refs #N). En marge : le correcteur automatique rejoue sa propre copie des tests, sur le jeu public E et sur le jeu privé E′ : une valeur écrite en dur échoue." style="display:block; width:100%; margin:0.2rem auto 0;">

<div class="box" style="margin-top: 0.5rem; font-size: 0.74em;">

Un test par mission, livré `@Disabled` : il démarre l'application, appelle ses routes et ses outils, compare au contrat. **Le test fait foi.** 📜 `docs/guides/tests.md`.

</div>

<!--
(1 min)

Le cycle de l'issue 00 : retirer @Disabled, constater le rouge, construire jusqu'au vert, nettoyer. Les tests sont dans src/test/java/fr/univ_amu/iut/r510/projet/acceptation/, un par mission (P1ForgeAcceptationTest, @Tag("P1")…). Le test démarre l'application sur un port libre, dans le même processus : ./mvnw test recompile les services, il n'a pas besoin du jar. Le jar (②) ne sert qu'à seed (③).

Au départ, tout est rouge, et c'est normal : chaque service lève Sceau.aFaire, donc chaque route répond 501.

Le piège : si l'on modifie un pipeline de construction (le socle de P1, qui construit les collections que lisent P2 et P3), il faut reconstruire le jar et relancer seed avant de rejouer le test ; sinon, le test lit les collections d'avant. Exécuté sur l'API d'exemple, avec stats_realisateurs supprimée et sans relancer le précalcul : « Cas F-stats (GET /api/realisateurs/stats) : 1 écart : $.resultats : 3 éléments attendus, 0 obtenus ».

Le correcteur automatique et le Grand Tableau ne jouent jamais les tests du dépôt : ils jouent leur propre copie, sur le jeu public E et sur le jeu privé E′. Modifier un test n'apporte rien ; une réponse écrite en dur échoue sur E′. ./mvnw test -Dgroups=gabarit vérifie le gabarit seul (dont le client MCP de test) : c'est le premier test à jouer aujourd'hui.

Renvoi : issue 00, « Les tests d'acceptation » ; guide docs/guides/tests.md ; Veillée V7.
-->

---

## ❓ Le service n'a qu'une faute : laquelle ?

<style scoped>
.err pre { white-space: pre; }
.g3 > .carte { font-size: 0.76em; text-align: center; }
</style>

<div class="err dense">

```text
Cas F-2001 (GET /api/films?annee=2001) : 4 écarts, dont $.resultats[0].duree : attendu 122, obtenu 125
Critère de la fiche : les films de l'année, triés par titre (contrat de GET /api/films).
4 écarts (les nombres sont comparés à une tolérance relative de 1e-9, Codex D16) :
  - $.resultats[0].duree : attendu 122, obtenu 125
  - $.resultats[0].titre : attendu "Amélie Poulain", obtenu "Le Voyage de Chihiro"
  - $.resultats[1].duree : attendu 125, obtenu 122
  - $.resultats[1].titre : attendu "Le Voyage de Chihiro", obtenu "Amélie Poulain"
```

</div>

<div class="g3" style="margin-top: 0.5rem; align-items: stretch;">
<div class="carte"><b class="t">A</b>le filtre sur l'année</div>
<div class="carte"><b class="t">B</b>le tri</div>
<div class="carte"><b class="t">C</b>la projection des champs</div>
</div>

<!--
(35 s)

Un vrai message, de la forme exacte de Rapport.message du gabarit (classe recopiée telle quelle dans un test de l'API d'exemple, joué par ./mvnw test). Le message continue par l'attendu et l'obtenu en entier (lignes « Attendu : » et « Obtenu  : »), coupées ici. « Critère de la fiche » reprend le critère de l'issue de la mission ; la tolérance et le Codex D16 sont écrits par le gabarit dans tout message qui compare des valeurs.

Laisser lire le message, puis voter. Réponse : B, sur la diapo suivante.
-->

---

## Réponse : le tri. La première ligne dit presque tout

<style scoped>
.g3 > .carte { font-size: 0.82em; }
</style>

<div class="dense">

```java
.sort(Sorts.descending("duree"))    // la faute : les mêmes films, dans un autre ordre
.sort(Sorts.ascending("titre"))     // le contrat : triés par titre ; le test passe au vert
```

</div>

<div class="g3" style="margin-top: 0.5rem; align-items: stretch;">
<div class="carte"><b class="t">① La 1<sup>re</sup> ligne</b> Le <b>cas</b> et la <b>requête</b>, à rejouer avec <code>curl -i</code>.</div>
<div class="carte orange"><b class="t">② Le chemin</b> <code>&#36;.resultats[0]</code> dit <b>où</b>. Films <b>échangés</b> : c'est l'ordre.</div>
<div class="carte rouge"><b class="t">③ Le statut</b> Un 501 : « le service lève encore Sceau.aFaire(...) ». Un 500 : la trace, au-dessus.</div>
</div>

<!--
(45 s)

Le service de l'exemple avait trié par durée décroissante au lieu du titre : les deux appels ont été exécutés (même test, rouge avec le premier, vert avec le second : « Tests run: 3, Failures: 0 »). Les mêmes films sont là, avec les mêmes valeurs, mais échangés : le filtre et la projection sont justes.

Trois réflexes :
1. La première ligne nomme le cas et la requête : la rejouer avec curl -i, comparer au contrat.
2. Un chemin JSON ($.resultats[0].titre) dit où est l'écart. Les écarts se lisent ensemble : ici, les films 0 et 1 sont échangés, l'erreur est dans le tri, pas dans les valeurs. L'ordre d'un tableau compte toujours ; l'ordre des champs d'un objet, jamais.
3. Le statut donne une piste. Exécuté, sur un service pas encore écrit : « Cas F-stats (GET /api/realisateurs/stats) : Statut attendu 200, obtenu 501. La route répond 501 : le service lève encore Sceau.aFaire(...), il reste à l'écrire. » Pour un 500, le gabarit écrit : « Erreur interne (500) : lisez la trace dans la sortie du test, juste au-dessus. » Pour une route non déclarée : « La route n'est pas déclarée dans le serveur (404 « Route inconnue ») : vérifiez son chemin. »

Renvoi : ./mvnw test -Dgroups=P3, par exemple, ne joue que le test de P3.
-->

---

<!-- header: Séance 6 · à retenir -->

## À retenir : une vérité, un contrat, un test

<div class="g2" style="font-size: 0.74em; align-items: stretch;">
<div class="carte vert"><b class="t">Une vérité</b> Le calcul dans un pipeline, exécuté par <b>un</b> service : texte en entrée, <code>Document</code> en sortie. La route et l'outil traduisent.</div>
<div class="carte vert"><b class="t">Un contrat</b> Le service lève 400, 422, 400, 404 : forme, couverture, cohérence, existence. Le gabarit répond 501, 500, 503.</div>
<div class="carte orange"><b class="t">Le pilote</b> Classes d'aide ou <code>Document.parse</code> : le même <code>Bson</code>. <code>toCollection()</code> lance un <code>&#36;merge</code>, rejouable.</div>
<div class="carte orange"><b class="t">Un test</b> Retirer <code>@Disabled</code>, du rouge au vert ; <code>seed</code> d'abord ; lire la 1<sup>re</sup> ligne ; rien en dur.</div>
</div>

<div class="bandeau" style="margin-top: 0.7rem; font-size: 0.82em; text-align: left;">✔ Le calcul dans <b>un seul service</b>, appelé par la route et par l'outil. Juste quand le <b>test d'acceptation</b> est vert, sans rien en dur : le correcteur automatique rejoue tout sur E′.</div>

<!--
(45 s)

Réponse à la question directrice : où écrire le calcul (dans MongoDB, exécuté par un seul service), et comment savoir qu'il est juste (le test d'acceptation, rejoué par le correcteur automatique sur le jeu privé E′ ; un repère recopié en dur passe sur E et échoue sur E′).
-->

---

<!-- header: "" -->

## À vous : la séance 6

<style scoped>
.g2 > div { display: flex; flex-direction: column; gap: 0.5rem; }
.g2 > div > .orange { margin-top: auto; }
</style>

<div class="bandeau" style="font-size: 0.92em; padding: 0.45rem 1.2rem;">
<a href="https://iutinfoaix-r510.github.io/projet/">iutinfoaix-r510.github.io/projet</a> : accepter le devoir d'équipe, lire l'issue 00, le Codex et s0
</div>

<div class="g2" style="margin-top: 0.6rem; font-size: 0.68em; grid-template-columns: 1.15fr 1fr; align-items: stretch;">
<div>

1. Lire, répartir les sceaux : **30&nbsp;min**
2. Mise en place (`lancement.md`) : **15&nbsp;min**
3. Le socle de P1, `./mvnw -q package -DskipTests`, `seed` ; dès qu'il est en base, P1, P2 et P3 en parallèle : **2&nbsp;h&nbsp;45**
4. `r510-sauver` : **5&nbsp;min**

<div class="carte orange">
<b class="t">📅 Rendu final</b>
dimanche 3 janvier 2027, 23&nbsp;h&nbsp;59. Cinq rendus au plus.
</div>

</div>
<div>

<div class="carte vert">
<b class="t">Dès aujourd'hui</b>
<code>Parametres</code> d'abord ; pas de <code>COLLSCAN</code> ; <code>IA.md</code> à jour.
</div>

<div class="carte violet">
<b class="t">Questions individuelles (S8)</b>
Tout ce que vous avez écrit ou relu (historique arrêté le mer. 16/12 au soir) peut vous être demandé, sans assistant IA. Relisez pour de vrai.
</div>

</div>
</div>

<p class="petit" style="margin-top: 0.5rem;">Note individuelle = min(100, note d'équipe × (0,6 + 0,5 q)), avec q = 70 % questions individuelles + 30 % contributions. Le détecteur d'IA peut déclencher un entretien, jamais une pénalité automatique. 📜 Issue 00, « Comment le projet est noté ».</p>

<!--
(55 s)

Fin du point cours : diapos 1 à 22 en 14 min 35, plus cette diapo et les deux suivantes (55 s + 15 s + 10 s), soit 15 min 55.

Minutage de la séance (4 h) : point cours, 16 min ; lecture de l'issue 00, du Codex et de s0, puis répartition des sept sceaux (un auteur et un relecteur par sceau, notés dans le premier commentaire de chaque issue), 30 min ; mise en place (le codespace, ./mvnw -q package -DskipTests, java -jar target/app.jar seed, puis serve, /api/sante à 200, ./mvnw test -Dgroups=gabarit ; détail dans docs/guides/lancement.md), 15 min ; le socle de P1 (Construction.construireSocle), puis ./mvnw -q package -DskipTests et seed ; dès que prenoms et totaux sont en base, les services de P1 (autocomplétion, fiche, année, statistiques), de P2 et de P3 en parallèle, 2 h 45 ; r510-sauver, 5 min. Total : 3 h 51, un peu de marge. Jalon de l'issue 00 : « S6 · La Forge et les Courbes » (P1 à P3) ; S7 : P4 à P7.

Parametres est livrée vide : la lire en premier évite que chaque membre réécrive la lecture du sexe ou d'un entier, différemment dans la route et dans l'outil.

La Loi du Régulateur (issue Codex) : les routes ciblées de P1 (autocomplétion, fiche) et de P3 (série) ne doivent pas faire de COLLSCAN ; le correcteur automatique lit les plans exécutés. Méthode et pièges dans le guide regulateur-et-explain.md. IA.md : les outils utilisés, ce qui a été généré, ce qui a été vérifié et comment ; sans lui, un critère de la note technique et artistique est perdu.

Rendu, par r510-rendre (issue 00, « Sauvegarder et rendre ») : r510-rendre pose un tag submit/… ; seul compte le dernier tag poussé avant le dimanche 3 janvier 2027 à 23 h 59 (heure du push enregistrée par GitHub), parmi les cinq premiers. Conseil de l'issue 00 : un rendu à la fin de S7, un à la fin de S8, puis le rendu final. r510-sauver sauvegarde sans rendre.

Questions individuelles (S8, 6 minutes : expliquer, puis modifier son code, sans assistant IA ni autre aide) : n'importe quelle fonctionnalité qu'on a écrite ou relue, d'après l'historique arrêté le mercredi 16 décembre au soir, peut être demandée. D'où « relisez pour de vrai » : approuver une PR sans la comprendre se paie en S8.

La note (issue 00, « Comment le projet est noté ») : note individuelle = min(100, note d'équipe × c), c = 0,6 + 0,5 × q, donc entre 0,6 et 1,1 ; q vient pour 70 % des questions individuelles et pour 30 % des contributions (historique git, PR écrites et relues). Le détecteur d'IA ne modifie pas q : il peut déclencher un entretien, jamais une pénalité automatique. Le travail livré après S8 compte pleinement dans la note d'équipe.

À vérifier avant la séance : le lien de l'énoncé du projet (Pages de IUTInfoAix-R510/projet, supposé ici) et le lien « Accepter » du syllabus ; dans projet/main (régénérer depuis 1207dca), les douze guides de docs/guides/, quetes.yml et la classe Parametres publique : ces trois éléments n'y sont pas encore.
-->

---

## Nouveau dans le projet : douze guides

<style scoped>
.g3 > div { font-size: 0.74em; }
.g3 p { margin: 0.25em 0; }
</style>

<p class="petit" style="margin: 0 0 0.5rem;">Dans <code>docs/guides/</code> de votre dépôt : ce que ce point cours ne montre pas.</p>

<div class="g3" style="align-items: stretch;">
<div class="carte vert"><b class="t">Démarrer</b>

`lancement.md` : codespace, `seed`, `serve`

`architecture.md` : service, route, outil, vue

`equipe-et-rendu.md` : branches, PR, rendu

</div>
<div class="carte"><b class="t">Coder</b>

`api-http.md` : contrats, statuts, `curl`

`mongodb-java.md` : pilote, écritures

`tests.md` : tests d'acceptation

`front.md` : le tableau de bord

</div>
<div class="carte violet"><b class="t">Approfondir</b>

`mcp-et-agent.md` : l'outil, Copilot

`regulateur-et-explain.md` : index, `explain`

`statistiques.md` : parts, lissage, seuils

`unicode-et-cle.md` : accents, `Cle.de`

</div>
</div>

<p class="petit" style="margin-top: 0.5rem;">Et pour S8 : <code>questions-individuelles.md</code>.</p>

<!--
(15 s)

Les douze guides du projet, dans docs/guides/ du dépôt de chaque équipe. Ils remplacent l'annexe et la carte « Nouveau dans ce TP » des séances 1 à 5. Ce que ce support a laissé de côté y est : écritures, ObjectId dans le chemin, getMatchedCount et replaceOne (mongodb-java.md, api-http.md, pour P6 en S7) ; l'enveloppe des outils MCP, les schémas d'entrée permissifs, le client JUnit avant Copilot (mcp-et-agent.md, P7) ; explain sur les routes ciblées (regulateur-et-explain.md) ; parts et dénominateurs, lissage, secret statistique (statistiques.md) ; Cle.de et l'encodage des accents dans l'URL (unicode-et-cle.md).
-->

---

<!-- header: "" -->
<!-- _class: lead -->

# Des questions ?

**Sébastien Nedjar** (GA1) · **Leïla Sakli Miled** (GA2)
IUT d'Aix-Marseille, département Informatique

<div style="margin-top: 1.2rem; font-size: 0.85em;">

[iutinfoaix-r510.github.io/projet](https://iutinfoaix-r510.github.io/projet/)
sebastien.nedjar@univ-amu.fr · leila.SAKLI@univ-amu.fr

</div>

<div class="bandeau" style="margin-top: 1.6rem; text-align: left; font-size: 0.92em;">

🎯 **Dès maintenant** : `/api/sante` à 200 et <code style="white-space: nowrap;">-Dgroups=gabarit</code> vert dans la première heure ; en sortant, <code style="white-space: nowrap;">r510-sauver</code>.

</div>

<!--
(10 s)

Questions sur le projet : en séance ; après la séance, une issue sur le dépôt syllabus pour ce qui concerne tout le monde, l'enseignant de son groupe pour le reste. Une question sur un contrat se pose en commentaire de l'issue concernée : les errata arrivent en commentaires datés.
-->

---

## Crédits

<div class="petit">

**Ce support** : R5.Real.10, IUT d'Aix-Marseille, sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Exemples (le ciné-club, sa petite API) écrits pour ce cours ; tous exécutés sur MongoDB 9.0.4, le Java avec le pilote 5.14.0, Javalin 7.2.4 et le SDK MCP 2.1.0. Les classes `ErreurMetier`, `Json`, `Enveloppe`, `Rapport` et `ComparateurJson` et le gestionnaire d'erreurs de `Serveur` sont ceux du gabarit du projet.

**Données du projet** : fichier des prénoms de l'INSEE, édition 2025 (Licence Ouverte) ; le détail est dans le dépôt du projet.

**Pour aller plus loin** : [pilote Java, agrégation](https://www.mongodb.com/docs/drivers/java/sync/current/aggregation/) · [`$merge`](https://www.mongodb.com/docs/manual/reference/operator/aggregation/merge/) · [Javalin](https://javalin.io/documentation) · [codes de statut HTTP (MDN)](https://developer.mozilla.org/fr/docs/Web/HTTP/Status) · [Model Context Protocol](https://modelcontextprotocol.io/) · [JUnit](https://docs.junit.org/current/user-guide/)

</div>

<!--
(Hors minutage : diapo de référence, laissée en fin de support.)

Les exemples et les schémas (assets/schemas/s6-*.svg) sont faits pour ce cours. Le code d'exemple (API du ciné-club, test JUnit) n'est pas publié : il a servi à exécuter chaque diapo.
-->
