# Licences et attributions

## Licences du dépôt

| Fichiers | Licence |
|---|---|
| Supports des points cours : `s*.md`, leurs versions HTML et PDF, schémas de `assets/` créés pour ces supports | [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr) |
| Éléments repris de MongoDB for Academia : `assets/mongodb-academia/` | [CC BY-NC-SA 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/deed.fr), leur licence d'origine |
| Chaîne de publication : `scripts/`, `.github/`, `package.json`, `marp.config.js` | [GPL-3.0](LICENSE) |
| Logo d'Aix-Marseille Université : `assets/logo.png`, `assets/logo-amu.png` | aucune de ces licences : propriété de l'université |

Pour réutiliser les supports : citer « R5.Real.10, IUT d'Aix-Marseille, https://github.com/IUTInfoAix-R510/cours » avec le lien vers la licence et l'indication des modifications, ne pas en faire un usage commercial, et diffuser les adaptations sous la même licence.

Les supports adaptent des présentations sous CC BY-NC-SA 3.0, dont la clause « partage dans les mêmes conditions » encadre leur licence. La section 4(b) de la [licence 3.0](https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode) autorise une version ultérieure qui garde les mêmes éléments (BY, NC, SA) : d'où la 4.0. Le matériau repris, lui, reste sous sa licence d'origine, 3.0.

## Sources

Les supports reprennent des éléments, surtout des schémas, des présentations du programme **MongoDB for Academia** de MongoDB. Cette partie liste ces présentations, la règle de citation suivie sur les diapositives et chaque élément repris.

### Les présentations

Elles sont en anglais et diffusées sous licence [Creative Commons Attribution - Pas d'utilisation commerciale - Partage dans les mêmes conditions 3.0 non transposée (CC BY-NC-SA 3.0)](https://creativecommons.org/licenses/by-nc-sa/3.0/), indiquée sur leurs deux premières diapositives. Aucun auteur n'y est nommé : l'attribution se fait à « MongoDB for Academia ».

| Présentation | Lien |
|---|---|
| MongoDB 101: Non-Relational for Beginners | [Google Slides](https://docs.google.com/presentation/d/1b_4GoeSsdtL-B4Qvm6Bo1Ml9G4IIEkRxbZq4Wa6f7O4/edit?usp=sharing) |
| Querying in Relational and Non-Relational Databases | [Google Slides](https://docs.google.com/presentation/d/1G9WdYIkQzSCszzrHqhlHbSjYxjY7qwrIfJVhaz9GTNA/edit?usp=sharing) |
| The MongoDB Query Language (MQL) | [Google Slides](https://docs.google.com/presentation/d/1Clw2TMYSVAXLKJO35y_n4OTkHyZ34f91hXzhrLYHSpM/edit?usp=sharing) |
| Querying Complex Data in MongoDB with MQL | [Google Slides](https://docs.google.com/presentation/d/16rfnVscMzr8PLD9nRDvm-1zDQaYeBRKk1NrJeVj2Wrs/edit?usp=sharing) |
| Querying Data with Operators and Compound Conditions | [Google Slides](https://docs.google.com/presentation/d/1sW52E0YZ4DhGhEQQa29yEBuWNqZBHzzaaRuix7jZFmY/edit?usp=sharing) |
| Inserting and Updating Data in MongoDB | [Google Slides](https://docs.google.com/presentation/d/19BrnUsVLjZmk-rR3n0EtKHGKszFkaGmA9xY2aCrUlnU/edit?usp=sharing) |
| Deleting Data in MongoDB | [Google Slides](https://docs.google.com/presentation/d/1SUuvsPBjzcxPnPJlzaUjdXNTHA0CkBobN0shralGBN4/edit?usp=sharing) |
| The MongoDB Aggregation Framework | [Google Slides](https://docs.google.com/presentation/d/1skcbXmW62Mk_fkq99h1K2RPErmYT1flZ2b36DChFGy0/edit?usp=sharing) |
| Querying Data with the MongoDB Aggregation Framework | [Google Slides](https://docs.google.com/presentation/d/13RojmrfLRe6WLVxQjB9eC1g_kDPeCKpS18DCUawE07g/edit?usp=sharing) |
| Data Modeling and Schema Design Patterns | [Google Slides](https://docs.google.com/presentation/d/1gmU38CZRgmVOYs66E16wvDO_ystf8jKJN2QEoBM2oX4/edit?usp=sharing) |

Chaque présentation s'exporte en PDF sans connexion à l'adresse `https://docs.google.com/presentation/d/<identifiant>/export/pdf`, l'identifiant étant la partie du lien qui suit `/d/`.

### Règle de citation

1. Un élément repris est enregistré dans `assets/mongodb-academia/`, sous un nom qui dit ce qu'il montre (par exemple `pipeline-unwind-group-schema.png`).
2. La diapositive qui l'affiche porte une légende de la forme :

   > Schéma : MongoDB for Academia, *<titre de la présentation>*, diapo N, CC BY-NC-SA 3.0

   Si l'élément a été modifié (recadrage, traduction, correction), la légende ajoute « adapté ».
3. L'élément est ajouté au tableau ci-dessous, avec la modification apportée.
4. Les supports qui contiennent ces éléments sont diffusés sous CC BY-NC-SA 4.0 ; les éléments repris restent sous leur licence d'origine, CC BY-NC-SA 3.0 (voir « Licences du dépôt »).

### Éléments repris

Une ligne par fichier de `assets/mongodb-academia/`. La colonne « Modification » vaut « aucune » pour une diapositive exportée telle quelle.

| Fichier | Présentation source | Diapositive | Modification |
|---|---|---|---|
| `embarquer-ou-referencer-blog.png` | MongoDB 101: Non-Relational for Beginners | 35 | aucune (diapositive entière, exportée à 110 ppp) ; utilisée dans `s2-imbrication-tableaux-agregation.md` |
| `pipeline-unwind-group-schema.png` | Querying Data with the MongoDB Aggregation Framework | 54 (page 54 de l'export PDF) | recadrée : schéma seul, des deux `$unwind` au `$group` (sans le code, ni la flèche de la collection `sales` en haut), exporté à 220 ppp ; utilisée dans `s2-imbrication-tableaux-agregation.md` |

### Contenus reformulés

Une ligne par passage de texte repris en français sans fichier image. La diapositive qui l'affiche porte une légende « D'après MongoDB for Academia, *<titre>*, diapos N, CC BY-NC-SA 3.0 (adapté) ».

| Support | Diapositive | Présentation source | Diapositives d'origine | Reprise |
|---|---|---|---|---|
| `s2-imbrication-tableaux-agregation.md` | 4 (« Trois sortes de relations ») | MongoDB 101: Non-Relational for Beginners | 38 à 47 | tableau des relations 1-1, 1-N et N-N et choix courant, reformulé, exemples changés |
| `s2-imbrication-tableaux-agregation.md` | 4 (ligne « Pour trancher ») | MongoDB 101: Non-Relational for Beginners | 36 (« Link or Embed? Cont. ») | quatre questions pour choisir entre embarquer et référencer, reformulées |

## Outils

Les supports sont construits avec [Marp](https://marp.app/) (licence MIT).
