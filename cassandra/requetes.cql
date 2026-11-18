
-- PROJET LDLC - LOT 3 : LOGS ET ANALYTICS
-- Technologie : Apache Cassandra

-- 1. Creation du keyspace
CREATE KEYSPACE IF NOT EXISTS ldlc_analytics
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

USE ldlc_analytics;

-- 2. Logs de navigation par produit et jour
CREATE TABLE IF NOT EXISTS logs_par_produit (
    produit_id text,
    jour date,
    event_id timeuuid,
    utilisateur_id text,
    action text,
    PRIMARY KEY ((produit_id, jour), event_id)
) WITH CLUSTERING ORDER BY (event_id DESC);

-- 3. Compteurs de consultations
CREATE TABLE IF NOT EXISTS vues_par_produit (
    produit_id text,
    jour date,
    nombre_vues counter,
    PRIMARY KEY ((produit_id), jour)
);

-- 4. Classement hebdomadaire des produits
CREATE TABLE IF NOT EXISTS top_produits_semaine (
    semaine text,
    rang int,
    produit_id text,
    nombre_vues bigint,
    PRIMARY KEY ((semaine), rang)
) WITH CLUSTERING ORDER BY (rang ASC);

-- 5. Historique des commandes
CREATE TABLE IF NOT EXISTS commandes_par_client (
    client_id text,
    commande_id uuid,
    date_commande timestamp,
    montant_total decimal,
    statut text,
    produits list<text>,
    PRIMARY KEY (
        (client_id),
        date_commande,
        commande_id
    )
) WITH CLUSTERING ORDER BY (
    date_commande DESC,
    commande_id ASC
);

-- 6. Consultation des logs d'un produit
SELECT produit_id, jour, utilisateur_id, action
FROM logs_par_produit
WHERE produit_id = 'PROD001'
AND jour = '2026-11-18';

-- 7. Consultation du compteur de vues
SELECT *
FROM vues_par_produit
WHERE produit_id = 'PROD001'
AND jour = '2026-11-18';

-- 8. Consultation du top hebdomadaire
SELECT rang, produit_id, nombre_vues
FROM top_produits_semaine
WHERE semaine = '2026-W47';

-- 9. Historique des commandes d'un client
SELECT date_commande, montant_total, statut, produits
FROM commandes_par_client
WHERE client_id = 'USER001';
