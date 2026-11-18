# Lot 3 — Logs et Analytics LDLC

## 1. Contexte et besoins

La plateforme e-commerce LDLC génère de nombreux événements : consultations de produits, clics, recherches et commandes clients.

Notre architecture doit répondre à plusieurs contraintes :

- Gérer des millions d'événements par jour.
- Supporter des écritures fréquentes.
- Conserver les historiques sur plusieurs mois ou années.
- Permettre la consultation des statistiques de navigation.
- Retrouver rapidement l'historique des commandes d'un client.

## 2. Choix technologique : Apache Cassandra

Nous avons choisi Apache Cassandra, une base NoSQL orientée colonnes larges (*Wide-Column Store*).

Cassandra est particulièrement adaptée aux volumes importants de données grâce à son architecture distribuée.

Elle permet de répartir les données entre plusieurs nœuds et de gérer de nombreuses écritures simultanées.

Contrairement à une approche relationnelle classique, notre modélisation Cassandra est principalement **Query-Driven** : les tables sont conçues en fonction des requêtes métier attendues.

## 3. Modélisation des données

Nous avons créé le keyspace `ldlc_analytics` et quatre tables.

### 3.1. Table `logs_par_produit`

Cette table conserve les événements de navigation associés à chaque produit.

**Partition Key :** `(produit_id, jour)`

**Clustering Column :** `event_id`, de type `timeuuid`, triée par ordre décroissant.

Ce choix permet de regrouper les événements d'un produit sur une journée et de les consulter du plus récent au plus ancien.

Exemple de requête :

```sql
SELECT *
FROM logs_par_produit
WHERE produit_id = 'PROD001'
AND jour = '2026-11-18';
```

### 3.2. Table `vues_par_produit`

Cette table contient les compteurs de consultations.

**Partition Key :** `produit_id`

**Clustering Column :** `jour`

Le champ `nombre_vues` utilise le type `counter` de Cassandra.

Les compteurs permettent de consulter directement le nombre de vues, sans recalculer l'ensemble des logs.

Exemple :

```sql
SELECT nombre_vues
FROM vues_par_produit
WHERE produit_id = 'PROD001'
AND jour = '2026-11-18';
```

### 3.3. Table `top_produits_semaine`

Cette table conserve un classement hebdomadaire précalculé des produits les plus consultés.

**Partition Key :** `semaine`

**Clustering Column :** `rang`, triée par ordre croissant.

Ce modèle permet de récupérer directement le classement d'une semaine.

Exemple :

```sql
SELECT rang, produit_id, nombre_vues
FROM top_produits_semaine
WHERE semaine = '2026-W47';
```

Le classement doit être produit et actualisé par un traitement analytique externe. Cassandra ne calcule pas automatiquement les rangs.

### 3.4. Table `commandes_par_client`

Cette table permet de consulter l'historique des commandes d'un utilisateur.

**Partition Key :** `client_id`

**Clustering Columns :** `date_commande` et `commande_id`.

La date est triée par ordre décroissant afin de présenter les commandes les plus récentes en premier.

Exemple :

```sql
SELECT date_commande, montant_total, statut, produits
FROM commandes_par_client
WHERE client_id = 'USER001';
```

## 4. Justification du partitionnement

Dans Cassandra, la Partition Key détermine la répartition des données entre les nœuds du cluster.

Les Clustering Columns déterminent l'organisation des lignes au sein d'une partition.

Nous avons choisi nos clés en fonction des accès attendus :

| Besoin | Partition Key | Clustering Columns |
|---|---|---|
| Logs d'un produit par jour | `(produit_id, jour)` | `event_id` |
| Compteur des vues | `produit_id` | `jour` |
| Classement hebdomadaire | `semaine` | `rang` |
| Commandes d'un client | `client_id` | `date_commande`, `commande_id` |

Cette organisation limite les lectures inutiles et évite de dépendre de `ALLOW FILTERING` pour les requêtes principales.

## 5. Compromis techniques

### Avantages

- Architecture distribuée adaptée à une montée en charge horizontale.
- Bonnes performances pour les écritures fréquentes.
- Tables conçues selon les requêtes métier.
- Données organisées par
