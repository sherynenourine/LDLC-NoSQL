
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
