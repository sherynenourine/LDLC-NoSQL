
## 6. Lot 4 — Neo4j : recommandations produits

### 6.1. Besoin métier et choix technologique

Une plateforme e-commerce doit pouvoir recommander des produits pertinents à ses clients. Ces recommandations peuvent reposer sur la compatibilité entre composants, la similarité des caractéristiques ou les achats fréquemment réalisés ensemble.

Neo4j est une base NoSQL orientée graphe qui permet de représenter les entités sous forme de nœuds et leurs relations sous forme de liens.

Cette approche facilite l'exploration des connexions entre produits sans multiplier les jointures complexes.

Dans notre projet, Neo4j est exécuté dans un conteneur Docker nommé `neo4j-ldlc`.

### 6.2. Modélisation du graphe

Le graphe contient quatre nœuds `Produit`, correspondant aux références du catalogue MongoDB :

| Identifiant | Produit |
|---|---|
| PROD001 | AMD Ryzen 7 7800X3D |
| PROD002 | Samsung Odyssey G5 27 pouces |
| PROD003 | MSI B650 Gaming Plus WiFi |
| PROD004 | AMD Ryzen 5 7600X |

Trois types de relations ont été modélisés :

- `COMPATIBLE_AVEC` : indique qu'un produit est compatible avec un autre.
- `SIMILAIRE_A` : représente une similarité entre deux produits.
- `ACHETE_AVEC` : indique que deux produits ont été achetés ensemble.

Exemples de relations créées :

```text
PROD001 --COMPATIBLE_AVEC--> PROD003
PROD001 --SIMILAIRE_A-----> PROD004
PROD001 --ACHETE_AVEC-----> PROD003
```

La relation `ACHETE_AVEC` possède une propriété `nombre_achats` fixée à 150 dans notre jeu de démonstration.

### 6.3. Requêtes Cypher

Neo4j utilise le langage Cypher pour créer et interroger les graphes.

Exemple de recherche des produits compatibles avec `PROD001` :

```cypher
MATCH (p:Produit {id: "PROD001"})-[:COMPATIBLE_AVEC]->(compatible:Produit)
RETURN compatible;
```

Exemple de recherche des produits similaires :

```cypher
MATCH (p:Produit {id: "PROD001"})-[:SIMILAIRE_A]->(similaire:Produit)
RETURN similaire;
```

Exemple de récupération des produits achetés ensemble :

```cypher
MATCH (p:Produit {id: "PROD001"})-[r:ACHETE_AVEC]->(autre:Produit)
RETURN autre, r.nombre_achats;
```

### 6.4. Recommandations pondérées

Un système de recommandation a été testé en attribuant un poids aux différents types de relations.

Dans notre jeu de données, le calcul donne les résultats suivants :

| Produit recommandé | Score |
|---|---|
| PROD003 — MSI B650 Gaming Plus WiFi | 8 |
| PROD004 — AMD Ryzen 5 7600X | 2 |

Le produit `PROD003` obtient le score le plus élevé car il est lié à `PROD001` par plusieurs relations pertinentes.

Cette méthode constitue un prototype de recommandation basé sur des règles métiers. Il ne s'agit pas d'un modèle de machine learning entraîné sur des données réelles.

### 6.5. Compromis techniques

Neo4j est particulièrement adapté aux recherches impliquant plusieurs relations entre entités.

Il offre une représentation intuitive des compatibilités et facilite l'ajout de nouveaux types de relations.

Cependant, le maintien d'une base graphe distincte implique une synchronisation avec le catalogue MongoDB. Les identifiants produits doivent notamment rester cohérents entre les deux bases.

De plus, la pertinence des recommandations dépend de la qualité des relations et des pondérations définies.

Dans ce projet, les relations et les scores ont été construits à partir d'un jeu de démonstration limité à quatre produits.

Les requêtes Cypher sont disponibles dans `neo4j/requetes.cypher`, avec les explications du lot dans `docs/lot4_neo4j.md`.
