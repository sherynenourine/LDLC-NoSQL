
# Projet NoSQL — Refonte LDLC

## Membres du binôme

- Sheryne Nourine
- Basma Belarbi

## 1. Présentation du projet

Ce projet consiste à concevoir une architecture de données NoSQL pour une plateforme e-commerce inspirée de LDLC, spécialisée dans la vente de matériel informatique.

L'objectif est de répondre à quatre besoins métier :

- Gérer un catalogue de produits aux caractéristiques variées.
- Assurer une gestion rapide des paniers et des sessions.
- Stocker les événements, les statistiques et les historiques.
- Proposer des recommandations fondées sur les relations entre produits.

Pour répondre à ces besoins, nous avons retenu une architecture de **persistance polyglotte** reposant sur quatre technologies NoSQL.

## 2. Architecture proposée

| Technologie | Type de base | Fonction |
|---|---|---|
| MongoDB | Documents | Catalogue produits et avis clients |
| Redis | Clé-valeur | Paniers et sessions utilisateurs |
| Apache Cassandra | Wide-column | Logs, statistiques et historiques |
| Neo4j | Graphe | Compatibilités et recommandations |

Chaque technologie est spécialisée dans un domaine métier.

L'architecture globale est représentée dans le fichier [docs/architecture.md](docs/architecture.md).

Le backend/API figurant dans le schéma représente une architecture cible conceptuelle : il n'a pas été développé dans le cadre du prototype.

## 3. Organisation du dépôt

```text
LDLC-NoSQL/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── conception_globale.md
│   ├── lot1_catalogue.md
│   ├── lot2_redis.md
│   ├── lot3_cassandra.md
│   └── lot4_neo4j.md
├── mongodb/
│   ├── produits.json
│   ├── avis.json
│   └── requetes.js
├── redis/
│   └── commandes.redis
├── cassandra/
│   └── requetes.cql
├── neo4j/
│   └── requetes.cypher
└── schemas/
```

## 4. Présentation des lots

### Lot 1 — MongoDB : catalogue produits

Modélisation d'un catalogue de quatre produits informatiques.

- Utilisation de documents avec des caractéristiques techniques intégrées.
- Séparation des avis dans une collection dédiée.
- Références entre produits compatibles.
- Requêtes de recherche, de filtrage et d'agrégation.
- Indexation des avis par identifiant produit.

**Fichiers :**
- [Catalogue produits](mongodb/produits.json)
- [Avis clients](mongodb/avis.json)
- [Requêtes MongoDB](mongodb/requetes.js)

### Lot 2 — Redis : paniers et sessions

Utilisation des structures Hash Redis pour :

- Ajouter des produits à un panier.
- Modifier les quantités.
- Consulter le contenu d'un panier.
- Gérer les sessions utilisateurs.
- Définir des durées d'expiration avec TTL.

**Fichier :** [Commandes Redis](redis/commandes.redis)

### Lot 3 — Cassandra : logs et analytics

Création du keyspace `ldlc_analytics` et de quatre tables :

- `logs_par_produit`
- `vues_par_produit`
- `top_produits_semaine`
- `commandes_par_client`

La modélisation repose sur les requêtes métier, les clés de partition et les colonnes de clustering.

**Fichier :** [Requêtes CQL](cassandra/requetes.cql)

### Lot 4 — Neo4j : recommandations

Création d'un graphe de produits et de trois relations :

- `COMPATIBLE_AVEC`
- `SIMILAIRE_A`
- `ACHETE_AVEC`

Des requêtes Cypher permettent d'explorer les relations et de calculer des scores de recommandation.

**Fichier :** [Requêtes Cypher](neo4j/requetes.cypher)

## 5. Environnement technique

Les technologies ont été installées et testées séparément à l'aide de Docker.

| Technologie | Conteneur Docker | Outil utilisé |
|---|---|---|
| MongoDB | `mon-mongo` | mongosh |
| Redis | `redis-ldlc` | redis-cli |
| Cassandra | `cassandra` | cqlsh |
| Neo4j | `neo4j-ldlc` | Neo4j Browser |

Ces conteneurs correspondent à notre environnement local de développement.

Le dépôt contient les données d'exemple, les requêtes et les documents de conception. Il ne comprend pas de déploiement automatisé de l'ensemble des services.

## 6. Documentation

Les documents complémentaires sont disponibles dans le dossier `docs/` :

- [Architecture globale](docs/architecture.md)
- [Document de conception](docs/conception_globale.md)
- [Lot 1 — MongoDB](docs/lot1_catalogue.md)
- [Lot 2 — Redis](docs/lot2_redis.md)
- [Lot 3 — Cassandra](docs/lot3_cassandra.md)
- [Lot 4 — Neo4j](docs/lot4_neo4j.md)

Le document de conception présente les modèles de données, les choix technologiques, les requêtes, le théorème CAP et les compromis retenus.

## 7. Limites et perspectives

Ce projet constitue un prototype pédagogique.

Les bases ont été testées indépendamment avec des jeux de données réduits. Aucune API commune, synchronisation automatique entre les bases ou infrastructure distribuée complète n'a été implémentée.

Les principales perspectives sont l'intégration des bases dans une application e-commerce, l'automatisation de leur synchronisation et la réalisation de tests de performance à plus grande échelle.

## 8. Conclusion

Ce projet démontre l'intérêt de la persistance polyglotte pour répondre à des besoins métier différents.

MongoDB, Redis, Cassandra et Neo4j offrent des modèles de stockage complémentaires, adaptés respectivement au catalogue, aux données temporaires, aux événements analytiques et aux recommandations.
