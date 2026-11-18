
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
