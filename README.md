# Projet NoSQL — Refonte LDLC

## Membres du binôme
- Sheryne Nourine
- Basma Belarbi

## Contexte

Ce projet consiste à concevoir une nouvelle architecture de données NoSQL pour LDLC, une plateforme de commerce électronique spécialisée dans le matériel informatique.

L'objectif est de proposer une architecture capable de gérer la croissance du catalogue produits, les nombreuses connexions utilisateurs, les volumes importants de données et les recommandations de produits.

## Architecture proposée

Nous avons retenu une architecture fondée sur la persistance polyglotte, reposant sur quatre technologies :

- **MongoDB** : gestion du catalogue produits.
- **Redis** : gestion des paniers et des sessions utilisateurs.
- **Apache Cassandra** : stockage des logs et des historiques.
- **Neo4j** : gestion des relations et recommandations de produits.

## Organisation du projet

- `docs/` : document de conception et architecture globale.
- `schemas/` : schémas de modélisation.
- `mongodb/` : Lot 1 — Catalogue produits.
- `redis/` : Lot 2 — Paniers et sessions.
- `cassandra/` : Lot 3 — Logs et analytics.
- `neo4j/` : Lot 4 — Recommandations produits.

## Objectifs

- Justifier les choix technologiques.
- Concevoir les modèles de données.
- Présenter les requêtes types.
- Expliquer les compromis techniques et le théorème CAP.
- Proposer une architecture NoSQL adaptée aux besoins de LDLC.