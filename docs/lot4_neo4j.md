# Lot 4 — Recommandations Produits LDLC

## 1. Contexte et besoins

Dans le cadre de la refonte de son architecture, LDLC souhaite proposer des recommandations pertinentes aux clients.

Le système doit notamment permettre de :

- Recommander des produits compatibles avec un composant informatique.
- Proposer des produits similaires.
- Identifier les produits fréquemment achetés ensemble.
- Explorer efficacement les relations entre différents produits.

Ces besoins nécessitent de représenter et d'exploiter des relations complexes entre les éléments du catalogue.

## 2. Choix technologique : Neo4j

Nous avons choisi Neo4j, une base de données NoSQL orientée graphe.

Contrairement à une base orientée document, Neo4j représente les données sous forme de nœuds reliés par des relations.

Cette approche est particulièrement adaptée aux systèmes de recommandation, car elle facilite les parcours entre produits et l'analyse de leurs connexions.

Neo4j utilise le langage Cypher pour interroger les graphes.

## 3. Modélisation des données

### 3.1. Nœuds

Nous avons créé des nœuds portant le label `Produit`.

Chaque nœud possède plusieurs propriétés :

- `id` : identifiant unique du produit.
- `nom` : nom commercial.
- `categorie` : catégorie du produit.
- `marque` : fabricant.
- `prix` : prix de vente.
- `socket` : caractéristique technique lorsque pertinente.

Notre prototype contient quatre produits :

| Identifiant | Produit |
|---|---|
| PROD001 | AMD Ryzen 7 7800X3D |
| PROD002 | Samsung Odyssey G5 27 pouces |
| PROD003 | MSI B650 Gaming Plus WiFi |
| PROD004 | AMD Ryzen 5 7600X |

Une contrainte d'unicité est appliquée sur la propriété `id`.

### 3.2. Relations

Nous avons défini trois types de relations.

**COMPATIBLE_AVEC**

Relie deux produits considérés comme techniquement compatibles.

Exemple : le processeur `PROD001` est relié à la carte mère `PROD003`, qui utilise également le socket AM5.

Cette relation représente une compatibilité simplifiée pour le prototype. Dans une application réelle, d'autres caractéristiques techniques devraient être vérifiées.

**SIMILAIRE_A**

Relie des produits présentant des caractéristiques communes.

Exemple : `PROD001` est relié à `PROD004`, car les deux produits sont des processeurs AMD utilisant le socket AM5.

**ACHETE_AVEC**

Représente des produits fréquemment achetés ensemble.

Exemple : `PROD001` est relié à `PROD003`, avec une propriété `nombre_achats` égale à 150.

Cette valeur est fictive et sert uniquement à illustrer le modèle.

## 4. Requêtes de recommandation

Nous avons développé des requêtes Cypher permettant de rechercher les produits liés à un produit consulté.

Exemple :

```cypher
MATCH (p:Produit {id: "PROD001"})-[r]->(rec:Produit)
RETURN
    rec.nom AS produit_recommande,
    type(r) AS type_recommandation,
    rec.prix AS prix;
```

Cette requête permet d'identifier les recommandations associées au processeur AMD.

## 5. Classement des recommandations

Nous avons également développé un système de scores afin de classer les produits.

Les pondérations fictives sont les suivantes :

| Type de relation | Score |
|---|---:|
| COMPATIBLE_AVEC | 5 |
| ACHETE_AVEC | 3 |
| SIMILAIRE_A | 2 |

Lorsqu'un produit possède plusieurs relations avec le produit consulté, ses scores sont additionnés.

La carte mère `PROD003` obtient ainsi 8 points, tandis que le processeur `PROD004` obtient 2 points.

Cette méthode permet de regrouper les recommandations et d'éviter l'affichage de doublons.

Dans un véritable système, ces pondérations seraient ajustées selon les besoins métier et les données d'utilisation.

## 6. Avantages et compromis

### Avantages

- Modélisation naturelle des relations entre produits.
- Requêtes adaptées aux parcours de graphe.
- Possibilité de combiner plusieurs critères de recommandation.
- Ajout de nouveaux types de relations sans refonte complète du modèle.
- Identification des connexions indirectes entre produits.

### Limites

- Nécessité de maintenir les données du graphe synchronisées avec le catalogue principal.
- Complexité supplémentaire liée à l'utilisation de plusieurs bases de données.
- Consommation de ressources pour les parcours complexes sur de grands graphes.
- Nécessité de définir des critères fiables pour les relations de compatibilité et de similarité.

## 7. Compromis CAP

Notre prototype Neo4j utilise une instance unique dans Docker. Le théorème CAP ne s'y applique donc pas directement comme à un cluster réparti sur plusieurs nœuds.

Dans une architecture Neo4j distribuée prenant en charge le clustering, les mécanismes de consensus et de réplication visent à préserver la cohérence des écritures.

Lorsqu'une partition réseau empêche un nœud d'obtenir les confirmations nécessaires, certaines opérations d'écriture peuvent devenir indisponibles.

Cette approche est cohérente avec la nécessité de conserver des relations fiables entre les produits.

## 8. Intégration dans l'architecture LDLC

MongoDB reste notre source principale pour les fiches produits.

Neo4j est utilisé pour gérer les relations de compatibilité, de similarité et d'achats communs.

Les identifiants `PROD001`, `PROD002`, `PROD003` et `PROD004` permettent d'associer les nœuds Neo4j aux produits du catalogue.

Un mécanisme de synchronisation devra maintenir les informations communes à jour entre MongoDB et Neo4j.

## 9. Conclusion

Neo4j est adapté au système de recommandations LDLC, car il permet de représenter et d'explorer efficacement les relations entre produits.

Notre prototype démontre trois types de relations ainsi qu'un mécanisme de classement des recommandations par score.

Les commandes et requêtes développées sont disponibles dans le fichier `neo4j/requetes.cypher`.
