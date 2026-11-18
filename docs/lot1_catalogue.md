# Lot 1 — Catalogue Produits LDLC

## 1. Contexte et besoins

LDLC est une plateforme e-commerce spécialisée dans le matériel informatique. Son catalogue comprend de nombreuses catégories de produits : processeurs, cartes mères, écrans, périphériques et logiciels.

Les caractéristiques techniques varient selon les catégories. L'architecture doit permettre d'ajouter de nouveaux attributs sans migration systématique du schéma.

Les fiches produits sont consultées fréquemment, tandis que leurs informations sont modifiées moins souvent.

## 2. Choix technologique : MongoDB

Nous avons choisi MongoDB, une base de données NoSQL orientée document.

Ce choix répond à plusieurs besoins :

- **Flexibilité du schéma :** les caractéristiques varient selon les catégories de produits.
- **Lecture efficace :** les informations principales d'une fiche sont regroupées dans un même document.
- **Évolutivité :** de nouveaux attributs peuvent être ajoutés sans modifier tous les documents existants.
- **Structures imbriquées :** les spécifications techniques peuvent être représentées dans des sous-documents JSON/BSON.

## 3. Modélisation des données

Nous avons créé la base `ldlc_nosql`, composée de deux collections principales.

### Collection `produits`

Elle contient les informations générales des produits :

- `_id` : identifiant unique.
- `nom` : nom commercial.
- `categorie` : catégorie.
- `marque` : fabricant.
- `prix` : prix de vente.
- `stock` : quantité disponible.
- `specifications` : caractéristiques techniques.
- `tags` : mots-clés.
- `produits_compatibles` : références vers d'autres produits.

Nous avons testé trois produits : un processeur AMD, un écran Samsung et une carte mère MSI.

### Collection `avis`

Elle contient les avis clients :

- `_id` : identifiant de l'avis.
- `produit_id` : référence au produit.
- `utilisateur` : identifiant du client.
- `note` : évaluation.
- `commentaire` : texte de l'avis.
- `date` : date de publication.

## 4. Choix Embedded vs References

### Embedded — Spécifications techniques

Les spécifications sont intégrées directement dans les fiches produits.

**Justification :** elles appartiennent au produit et sont généralement consultées avec sa fiche. L'imbrication permet de récupérer ces informations en une seule lecture.

### References — Avis clients

Les avis sont stockés dans une collection indépendante et reliés aux produits grâce au champ `produit_id`.

**Justification :** leur nombre peut augmenter continuellement. Les références permettent d'éviter une croissance illimitée des documents produits et facilitent la pagination des avis.

### References — Produits compatibles

Les identifiants des produits compatibles sont conservés dans le tableau `produits_compatibles`.

**Justification :** cette approche évite de dupliquer les fiches complètes. Une modification du prix ou des spécifications d'un produit ne nécessite pas de mettre à jour ses références dans les autres documents.

La compatibilité technique complète sera également étudiée dans le Lot 4 avec Neo4j.

## 5. Optimisation des performances

Nous avons créé un index sur `produit_id` dans la collection `avis` pour accélérer la recherche des avis associés à un produit.

Les requêtes types permettent de :

- Rechercher des produits par catégorie.
- Filtrer les produits selon leur prix et leur disponibilité.
- Consulter les avis d'un produit.
- Récupérer les produits compatibles avec `$lookup`.

Les requêtes correspondantes sont disponibles dans `mongodb/requetes.js`.

## 6. Compromis techniques et CAP

MongoDB offre une flexibilité importante, mais le modèle documentaire présente plusieurs compromis.

Les données imbriquées simplifient certaines lectures, tandis que les références nécessitent parfois des requêtes supplémentaires.

Dans une architecture MongoDB distribuée avec replica set, la cohérence et la disponibilité dépendent notamment des configurations de lecture et d'écriture.

Pour les informations critiques du catalogue, comme les modifications de prix ou de stock, nous privilégions des écritures confirmées par une majorité de réplicas et des lectures adaptées aux exigences de cohérence.

En cas de partition réseau, la capacité d'effectuer certaines opérations peut être réduite afin de préserver les garanties de cohérence choisies.

Nous ne considérons donc pas MongoDB comme strictement CP ou AP dans toutes les configurations.

## 7. Conclusion

MongoDB est adapté au catalogue produits LDLC grâce à son modèle documentaire flexible.

Notre architecture combine Embedded pour les spécifications techniques et References pour les avis et les produits compatibles.

Cette combinaison permet d'optimiser les lectures courantes tout en limitant la duplication des données et la croissance des documents.
