---
marp: true
theme: r510
paginate: true
lang: fr
title: "Séance 7 : point d'étape du projet"
description: "R5.Real.10, point d'étape de la séance 7 (projet, sceaux P4 à P7)"
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

# Point d'étape

**R5.Real.10 - Nouveaux paradigmes de base de données**

Séance 7 · le projet · semaine du 14 décembre 2026

<p class="question">L'Almanach sera-t-il ouvert mercredi soir ?</p>

<!--
(15 s)

Pas de point cours en S7 : un point d'étape de 5 à 10 minutes, une seule diapo. Le fond (écritures en Java, validateur, MCP, explain, statistiques) est dans les guides du projet (docs/guides/ du dépôt de chaque équipe).

« L'Almanach est ouvert » quand les sept sceaux sont brisés : c'est le nom du jalon S7 (« S7 · L'Almanach ouvert », P4 à P7, échéance le mercredi 16/12 à 23 h 59, le même soir que l'arrêt de l'historique des questions individuelles).
-->

---

<!-- header: Séance 7 · point d'étape -->

## Où en êtes-vous ? Les sceaux d'abord

<div class="g3" style="font-size: 0.66em; align-items: stretch;">
<div class="carte vert"><b class="t">Où en êtes-vous ?</b>

- P1 à P3 : tests d'acceptation **verts** chez vous, `seed` relancé
- Jalon « L'Almanach ouvert » : **P4 à P7**, mer. 16/12 au soir
- Sous **24/40** sur les sceaux, les quêtes secondaires comptent moins : les sceaux d'abord

</div>
<div class="carte violet"><b class="t">Aujourd'hui</b>

- P6 : le validateur est **dans MongoDB** (guide `mongodb-java.md`)
- P7 : client JUnit ou inspecteur MCP d'abord, Copilot ensuite (crédits limités)
- `quetes.yml` : quêtes secondaires déclarées, avec leur porteur
- Veillées V1 et V2 commencées

</div>
<div class="carte orange"><b class="t">📅 Dates</b>

- Un **premier rendu** ce soir : `r510-rendre` (cinq au plus)
- Historique des questions individuelles arrêté le **mer. 16/12 au soir** : chacun auteur ou relecteur, avec des PR **relues pour de vrai**

</div>
</div>

<div class="bandeau" style="margin-top: 0.7rem; font-size: 0.8em; text-align: left;">Un sceau est brisé quand son test d'acceptation passe sans rien en dur : le correcteur automatique le rejoue sur le jeu privé E′.</div>

<!--
(5 à 8 min, avec les questions)

Faire lever la main : combien d'équipes ont P1, P2 et P3 verts en local ? Qui a déjà fait un rendu ? Si le Grand Tableau est en ligne, montrer qu'on y lit sa rangée (sceaux acquis, motif bloquant) ; sinon, s'appuyer sur les tests d'acceptation locaux. Le Grand Tableau ne donne jamais de note.

Les trois erreurs vues en S6 (à remplir le jour même, à la main) :
1. …
2. …
3. …

Rappels, sans les détailler (ils sont dans les issues et les guides) :
- P6 écrit dans la base : le validateur ($jsonSchema et $expr, validationAction "error") est déclaré dans MongoDB, pas seulement en Java ; écritures et getMatchedCount dans le guide mongodb-java.md.
- P7 : tester les outils avec le client JUnit fourni ou l'inspecteur MCP, et ne solliciter Copilot en mode agent qu'une fois les outils justes (ORACLE.md demande trois conversations réelles).
- Le lot B des quêtes secondaires paraît au plus tard le vendredi 11/12 ; seules les quêtes déclarées dans quetes.yml sont évaluées.
- Questions individuelles en S8 : tout ce que chacun a écrit ou relu, d'après l'historique arrêté le mercredi 16/12 au soir, peut lui être demandé, sans assistant IA. Une PR approuvée sans lecture se voit vite.
- Rendu final le dimanche 3 janvier 2027 à 23 h 59 : dernier tag submit/… poussé avant cette heure, cinq rendus au plus.
-->

---

<!-- header: "" -->

## Crédits

<div class="petit">

**Ce support** : R5.Real.10, IUT d'Aix-Marseille, sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr).

**Le projet** : issues, Codex et guides du dépôt de chaque équipe (`docs/guides/`) ; données du fichier des prénoms de l'INSEE (Licence Ouverte).

</div>

<!--
(Hors minutage.)
-->
