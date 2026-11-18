
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
