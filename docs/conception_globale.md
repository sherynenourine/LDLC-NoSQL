# Document de conception — Refonte NoSQL LDLC

## 1. Introduction et contexte

Le projet consiste à proposer une architecture NoSQL pour une plateforme de commerce électronique inspirée de LDLC.

L'objectif est de répondre à quatre besoins distincts :
- La gestion d'un catalogue de produits informatiques.
- La gestion des paniers et des sessions utilisateurs.
- Le stockage des événements et des données analytiques.
- La recommandation de produits à partir de leurs relations.

Pour répondre à ces besoins, une architecture de persistance polyglotte a été retenue. Elle repose sur quatre technologies complémentaires : MongoDB, Redis, Cassandra et Neo4j.

Cette approche permet de choisir le modèle de données le plus adapté à chaque usage, plutôt que d'imposer une base unique à l'ensemble du système.

Le périmètre du projet porte sur la modélisation, l'implémentation et l'interrogation des bases de données. Le développement d'une application e-commerce complète et de son backend n'est pas inclus.

## 2. Architecture globale

### 2.1. Principe de persistance polyglotte

L'architecture proposée repose sur la persistance polyglotte, qui consiste à utiliser plusieurs technologies de stockage spécialisées au sein d'un même système d'information.

Dans notre projet LDLC, quatre bases NoSQL ont été sélectionnées en fonction des besoins métier et des types de données manipulées.

| Technologie | Modèle NoSQL | Rôle dans le projet |
|---|---|---|
| MongoDB | Documents | Catalogue produits et avis clients |
| Redis | Clé-valeur | Paniers et sessions utilisateurs |
| Cassandra | Wide-column | Événements, logs et statistiques |
| Neo4j | Graphe | Relations et recommandations produits |

### 2.2. Organisation de l'architecture

L'architecture cible comprend trois niveaux :

1. **Interface utilisateur** : permet de consulter les produits, de gérer un panier et de visualiser des recommandations.
2. **Backend / API** : représente la couche applicative qui reçoit les demandes des utilisateurs et interroge les bases concernées.
3. **Bases de données NoSQL** : assurent le stockage et l'accès aux données selon leur spécialisation.

Le backend présenté dans cette architecture est conceptuel. Il n'a pas été développé dans le cadre du projet.

Le schéma détaillé est disponible dans le fichier `docs/architecture.md`.

### 2.3. Justification des choix technologiques

**MongoDB** a été retenu pour la flexibilité de son modèle documentaire. Les caractéristiques des produits informatiques peuvent varier selon leur catégorie : processeur, écran ou carte mère.

**Redis** permet un accès rapide aux données temporaires des paniers et sessions. Les mécanismes d'expiration TTL facilitent leur gestion.

**Cassandra** est adapté au stockage de nombreux événements et à leur consultation selon des critères connus à l'avance. Son modèle de données privilégie les requêtes métier et les écritures distribuées.

**Neo4j** permet de représenter les relations entre produits sous forme de graphe. Les liens de compatibilité, de similarité et d'achat conjoint peuvent être exploités pour produire des recommandations.

### 2.4. Échanges et limites

Dans l'architecture cible, chaque opération métier interroge la base correspondant à son besoin. Par exemple, la consultation d'un produit exploite MongoDB, tandis que la recherche de produits compatibles utilise Neo4j.

Les identifiants produits communs, tels que `PROD001` et `PROD003`, permettent de faire correspondre les données entre les différentes bases.

Cette organisation implique cependant des contraintes :
- La cohérence entre les bases doit être gérée par la couche applicative.
- Certaines informations peuvent être dupliquées pour optimiser les lectures.
- Il n'existe pas de transaction globale automatiquement garantie entre les quatre technologies.

Dans ce projet, les quatre bases ont été mises en place et testées séparément avec Docker. Leur intégration applicative complète reste une évolution possible.

## 3. Lot 1 — MongoDB : catalogue produits

### 3.1. Besoin métier et choix technologique

Le catalogue LDLC regroupe des produits informatiques aux caractéristiques hétérogènes. Un processeur possède un nombre de cœurs et un socket, tandis qu'un écran possède une résolution et une fréquence de rafraîchissement.

MongoDB est une base NoSQL orientée documents. Elle permet de stocker des objets JSON avec des structures flexibles, sans imposer les mêmes champs à tous les produits.

La base créée pour ce lot est `ldlc_nosql`. Elle comporte deux collections principales :
- `produits` : informations du catalogue.
- `avis` : évaluations et commentaires des clients.

### 3.2. Modélisation des données

Chaque produit possède un identifiant unique `_id`, un nom, une catégorie, une marque, un prix et un stock.

Le champ `specifications` est un sous-document dont les propriétés dépendent de la catégorie du produit. Le champ `tags` contient des mots-clés permettant de caractériser le produit.

Exemple de document :

```json
{
  "_id": "PROD001",
  "nom": "AMD Ryzen 7 7800X3D",
  "categorie": "Processeur",
  "marque": "AMD",
  "prix": 399.99,
  "stock": 25,
  "specifications": {
    "socket": "AM5",
    "coeurs": 8,
    "threads": 16,
    "frequence_ghz": 4.2,
    "cache_mb": 96
  },
  "tags": ["Gaming", "AMD", "Ryzen"],
  "produits_compatibles": ["PROD003"]
}
```

### 3.3. Choix Embedded et References

Deux stratégies de modélisation ont été utilisées.

**Embedded :** les caractéristiques techniques sont intégrées directement dans chaque document `produits`, grâce au champ `specifications`. Cette approche permet de récupérer les informations du produit en une seule lecture.

**References :** les avis sont conservés dans une collection distincte `avis`, avec un champ `produit_id` permettant de retrouver le produit concerné. Cela évite d'augmenter indéfiniment la taille des documents produits lorsque les clients publient de nouveaux avis.

Les compatibilités sont représentées par un tableau d'identifiants `produits_compatibles`. Par exemple, `PROD001` référence `PROD003`, une carte mère compatible.

### 3.4. Requêtes et index

Exemple de recherche de processeurs AMD :

```javascript
db.produits.find({
  categorie: "Processeur",
  marque: "AMD"
})
```

Exemple de filtrage sur une caractéristique technique :

```javascript
db.produits.find({
  "specifications.socket": "AM5"
})
```

Exemple de récupération des avis associés à un produit :

```javascript
db.produits.aggregate([
  {
    $lookup: {
      from: "avis",
      localField: "_id",
      foreignField: "produit_id",
      as: "avis_clients"
    }
  }
])
```

Un index sur `avis.produit_id` a été créé pour accélérer les recherches d'avis par produit.

Les données et les requêtes de ce lot sont disponibles dans le dossier `mongodb/` du dépôt GitHub.

### 3.5. Compromis techniques

Le modèle documentaire est adapté aux produits possédant des caractéristiques variables et facilite l'évolution du catalogue.

Cependant, les références entre collections nécessitent parfois des opérations de jointure avec `$lookup`. De plus, MongoDB ne garantit pas automatiquement l'intégrité des références entre documents : leur cohérence doit être contrôlée par l'application.

Pour ce projet, la séparation des avis et l'intégration des spécifications représentent un compromis entre simplicité de lecture, souplesse et évolutivité.

## 4. Lot 2 — Redis : paniers et sessions utilisateurs

### 4.1. Besoin métier et choix technologique

Une plateforme e-commerce doit permettre aux utilisateurs d'ajouter des produits à leur panier, de modifier leurs quantités et de conserver une session pendant leur navigation.

Ces données sont fréquemment consultées et modifiées. Elles nécessitent un accès rapide et peuvent avoir une durée de vie limitée.

Redis est une base NoSQL clé-valeur principalement utilisée en mémoire. Elle est adaptée à ce besoin grâce à ses faibles latences, ses structures de données et son mécanisme d'expiration automatique.

Dans ce projet, Redis est exécuté dans un conteneur Docker nommé `redis-ldlc`.

### 4.2. Modélisation des paniers

Les paniers sont stockés sous forme de Hash Redis.

Chaque panier possède une clé construite selon le modèle `panier:USER_ID`. Les champs correspondent aux identifiants des produits et les valeurs aux quantités sélectionnées.

Exemple :

```text
Clé : panier:USER001

PROD001 → 2
PROD002 → 1
```

Cette structure permet d'accéder directement au panier d'un utilisateur sans parcourir les paniers des autres clients.

### 4.3. Commandes utilisées

Création d'un panier :

```redis
HSET panier:USER001 PROD001 2 PROD002 1
```

Consultation du panier :

```redis
HGETALL panier:USER001
```

Augmentation de la quantité d'un produit :

```redis
HINCRBY panier:USER001 PROD001 1
```

Définition d'une expiration de 24 heures :

```redis
EXPIRE panier:USER001 86400
```

Redis permet ainsi de modifier les quantités de manière atomique à l'aide de `HINCRBY`.

### 4.4. Gestion des sessions

Les sessions sont également représentées par des Hash Redis.

Exemple de création :

```redis
HSET session:SESSION001 user_id USER001 statut connecte role client
```

Une durée de validité de 30 minutes est définie :

```redis
EXPIRE session:SESSION001 1800
```

Lorsqu'un utilisateur se déconnecte, la session peut être supprimée :

```redis
DEL session:SESSION001
```

Le mécanisme TTL (Time To Live) évite de conserver indéfiniment des sessions devenues inutiles.

### 4.5. Compromis techniques

Redis offre un accès très rapide aux paniers et sessions et facilite la gestion de données temporaires.

Cependant, son fonctionnement principalement en mémoire implique une attention particulière à la consommation de RAM.

La persistance doit également être configurée selon les besoins de disponibilité et de récupération des données. Sans stratégie de persistance adaptée, certaines données peuvent être perdues lors d'un incident.

Dans une architecture e-commerce réelle, les commandes validées devraient être enregistrées dans un stockage durable distinct du panier temporaire.

Dans ce projet, les commandes Redis et leur utilisation sont documentées dans `redis/commandes.redis` et `docs/lot2_redis.md`.

## 5. Lot 3 — Cassandra : logs et analytics

### 5.1. Besoin métier et choix technologique

Une plateforme e-commerce génère de nombreux événements : consultations de produits, interactions des utilisateurs et commandes.

Ces informations peuvent être utilisées pour analyser l'activité du site, identifier les produits populaires et consulter l'historique des achats.

Apache Cassandra est une base NoSQL de type wide-column, conçue pour gérer des volumes importants de données réparties sur plusieurs nœuds.

Elle privilégie les écritures distribuées, la disponibilité et une modélisation orientée requêtes.

Dans notre projet, Cassandra est exécuté dans Docker et le keyspace `ldlc_analytics` a été créé.

### 5.2. Modélisation orientée requêtes

Contrairement à une base relationnelle, Cassandra encourage la création de tables adaptées aux requêtes prévues.

Nous avons créé quatre tables :

| Table | Objectif |
|---|---|
| `logs_par_produit` | Consulter les événements associés à un produit et à une journée |
| `vues_par_produit` | Compter les consultations d'un produit par jour |
| `top_produits_semaine` | Consulter un classement hebdomadaire de produits |
| `commandes_par_client` | Retrouver les commandes d'un client |

Cette organisation permet de lire les données directement selon les besoins métier, sans multiplier les jointures.

### 5.3. Clés de partition et clustering

Les clés de partition déterminent la répartition des données entre les nœuds Cassandra.

Les colonnes de clustering organisent les lignes à l'intérieur d'une partition.

Dans `logs_par_produit`, la clé de partition est composée de `produit_id` et `jour`. Le champ `event_id`, de type `timeuuid`, sert à ordonner les événements dans chaque partition.

Dans `commandes_par_client`, les données sont partitionnées par `client_id`, puis ordonnées par `date_commande` décroissante afin de retrouver les commandes récentes.

Ces choix facilitent les lectures ciblées et limitent les recherches sur l'ensemble des données.

### 5.4. Requêtes CQL

Exemple de consultation des événements d'un produit sur une journée :

```sql
SELECT *
FROM ldlc_analytics.logs_par_produit
WHERE produit_id = 'PROD001'
  AND jour = '2026-11-18';
```

Exemple de consultation des vues d'un produit :

```sql
SELECT *
FROM ldlc_analytics.vues_par_produit
WHERE produit_id = 'PROD001';
```

Exemple de récupération du classement des produits d'une semaine :

```sql
SELECT *
FROM ldlc_analytics.top_produits_semaine
WHERE semaine = '2026-W47';
```

Exemple de consultation des commandes d'un client :

```sql
SELECT *
FROM ldlc_analytics.commandes_par_client
WHERE client_id = 'USER001';
```

Ces requêtes illustrent le principe de modélisation orientée accès : les tables sont conçues pour répondre à des besoins précis.

### 5.5. Compteurs et données analytiques

La table `vues_par_produit` utilise un compteur Cassandra pour représenter le nombre de consultations.

Exemple d'incrémentation :

```sql
UPDATE ldlc_analytics.vues_par_produit
SET nb_vues = nb_vues + 1
WHERE produit_id = 'PROD001'
  AND jour = '2026-11-18';
```

Les compteurs permettent d'accumuler les consultations, mais nécessitent une attention particulière : les répétitions d'opérations peuvent entraîner des comptages supplémentaires.

Le classement hebdomadaire est représenté par une table dédiée, alimentée avec des résultats de classement déjà calculés. Il ne correspond pas à une agrégation automatique réalisée par Cassandra.

### 5.6. Compromis techniques

Cassandra permet de distribuer les données et d'assurer des écritures efficaces à grande échelle.

Cependant, son modèle impose de connaître les requêtes principales à l'avance. Une nouvelle requête métier peut nécessiter la création d'une table supplémentaire.

La duplication de données est donc acceptée pour optimiser les accès.

Concernant le théorème CAP, Cassandra privilégie une architecture distribuée tolérante aux partitions réseau. Le compromis entre cohérence et disponibilité dépend notamment du niveau de cohérence configuré pour les opérations.

Dans notre projet, un seul conteneur Cassandra a été utilisé pour les tests. Les propriétés de distribution et de tolérance aux pannes d'un véritable cluster n'ont donc pas été évaluées.

Les scripts et explications complémentaires figurent dans `cassandra/requetes.cql` et `docs/lot3_cassandra.md`.

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

## 7. Analyse transversale — CAP, cohérence et compromis

### 7.1. Comparaison des quatre technologies

L'architecture LDLC repose sur quatre technologies NoSQL complémentaires, chacune répondant à un besoin métier spécifique.

| Critère | MongoDB | Redis | Cassandra | Neo4j |
|---|---|---|---|---|
| Modèle | Documents | Clé-valeur | Wide-column | Graphe |
| Usage principal | Catalogue | Paniers et sessions | Logs et analytics | Recommandations |
| Point fort | Flexibilité du schéma | Faible latence | Écritures distribuées | Parcours de relations |
| Limite principale | Gestion des références | Consommation mémoire | Modèle orienté requêtes | Synchronisation du graphe |

Cette spécialisation évite d'imposer un modèle de stockage unique à des données possédant des caractéristiques différentes.

### 7.2. Théorème CAP

Le théorème CAP indique qu'en présence d'une partition réseau, un système distribué ne peut pas garantir simultanément une cohérence forte et une disponibilité complète.

Les compromis dépendent de l'architecture et de la configuration des technologies.

**MongoDB :** dans un replica set, les mécanismes d'élection, les préférences de lecture et les niveaux de confirmation des écritures influencent la cohérence et la disponibilité. Une configuration privilégiant la cohérence peut refuser certaines opérations lorsqu'une majorité de nœuds n'est plus accessible.

**Redis :** le comportement dépend de son déploiement. Une instance unique ne permet pas d'illustrer directement un compromis CAP distribué. En configuration répliquée ou en cluster, les mécanismes de réplication et de basculement introduisent des compromis entre disponibilité et cohérence.

**Cassandra :** sa conception distribuée privilégie la tolérance aux partitions et propose des niveaux de cohérence configurables. Le choix d'un niveau de cohérence plus élevé peut réduire la disponibilité de certaines opérations lors d'une panne réseau.

**Neo4j :** en déploiement cluster, la gestion des écritures et de la réplication dépend du rôle des membres et des mécanismes de consensus. La disponibilité des écritures peut être affectée si le quorum nécessaire n'est plus accessible.

Dans ce projet, les bases ont été testées dans des conteneurs Docker indépendants. Aucun scénario de partition réseau sur un cluster distribué n'a été réalisé.

### 7.3. Cohérence entre les bases

Les quatre bases utilisent des modèles de données différents, mais certains identifiants sont partagés.

Par exemple, `PROD001` désigne le même processeur dans MongoDB et Neo4j.

Une modification du catalogue MongoDB pourrait nécessiter une actualisation des données correspondantes dans Neo4j.

De même, un panier Redis référence des produits dont les informations principales sont stockées dans MongoDB.

Dans une architecture de production, cette cohérence pourrait être assurée par une couche applicative ou par un mécanisme d'événements.

Cette synchronisation automatique n'a pas été implémentée dans le prototype.

### 7.4. Performance et évolutivité

Chaque technologie apporte un mécanisme d'optimisation différent :

- MongoDB utilise des index et des documents adaptés aux lectures du catalogue.
- Redis conserve les données temporaires en mémoire et utilise des opérations rapides sur les Hash.
- Cassandra organise ses données selon les clés de partition et les requêtes prévues.
- Neo4j exploite les relations du graphe pour retrouver des produits connectés.

Ces mécanismes sont adaptés aux besoins identifiés, mais le prototype utilise un jeu de données réduit.

Aucun benchmark de charge permettant de comparer quantitativement les performances des quatre solutions n'a été réalisé.

### 7.5. Bilan des compromis

Le principal avantage de la persistance polyglotte est d'employer une technologie adaptée à chaque domaine métier.

En contrepartie, l'architecture devient plus complexe à administrer : plusieurs bases doivent être surveillées, sauvegardées et maintenues.

Elle nécessite également de gérer la circulation des données et leur cohérence entre les systèmes.

Le choix de quatre technologies est donc pertinent pour illustrer les différentes familles NoSQL, mais devrait être justifié par des besoins réels de performance, de volumétrie et de maintenance avant un déploiement en production.

## 8. Conclusion et perspectives

### 8.1. Bilan du projet

Ce projet a permis de concevoir et de mettre en œuvre un prototype d'architecture NoSQL pour une plateforme e-commerce inspirée de LDLC.

Quatre technologies complémentaires ont été utilisées :

- **MongoDB** pour le stockage du catalogue produits et des avis clients, avec une modélisation combinant documents intégrés et références.
- **Redis** pour la gestion des paniers et des sessions utilisateurs, en exploitant les Hash et les mécanismes d'expiration TTL.
- **Cassandra** pour le stockage des événements, le suivi des consultations et l'historique des commandes, avec une modélisation orientée requêtes.
- **Neo4j** pour représenter les relations entre produits et construire un système de recommandations pondérées.

Chaque lot a été implémenté et testé séparément dans un environnement Docker.

Les schémas, les requêtes et les choix de modélisation ont été documentés dans le dépôt GitHub.

### 8.2. Limites de la solution

Le prototype présente plusieurs limites.

Tout d'abord, les jeux de données utilisés sont réduits et essentiellement destinés à la démonstration. Ils ne permettent pas d'évaluer les performances de l'architecture à grande échelle.

Ensuite, les quatre bases de données fonctionnent indépendamment. Aucune API centrale ni synchronisation automatique entre les technologies n'a été développée.

Enfin, les mécanismes avancés de haute disponibilité, de réplication distribuée, de surveillance et de reprise après incident n'ont pas été testés dans des conditions de production.

Les recommandations Neo4j reposent sur des relations et des pondérations définies pour la démonstration, et non sur un modèle prédictif entraîné sur un historique réel.

### 8.3. Perspectives d'amélioration

Plusieurs évolutions pourraient être envisagées :

1. Développer une API permettant de centraliser l'accès aux quatre bases.
2. Mettre en place une synchronisation des produits entre MongoDB et Neo4j.
3. Étendre les jeux de données pour réaliser des tests de performance.
4. Étudier la réplication et la tolérance aux pannes sur des clusters distribués.
5. Améliorer les recommandations avec des données de navigation et d'achats réels.
6. Ajouter des mécanismes de supervision, de sauvegarde et de restauration.

### 8.4. Conclusion générale

La persistance polyglotte constitue une approche pertinente lorsque les besoins métiers nécessitent des modèles de données différents.

Dans le contexte LDLC, MongoDB, Redis, Cassandra et Neo4j répondent chacun à des usages spécifiques : catalogue, données temporaires, analytics et recommandations.

Le projet illustre ainsi l'intérêt de sélectionner une technologie selon les caractéristiques des données et les requêtes attendues, tout en soulignant les compromis liés à la cohérence, à l'exploitation et à la complexité d'une architecture multi-bases.
