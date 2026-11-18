# Document de conception — Refonte NoSQL LDLC

## 1. Introduction et contexte

Ce projet propose une architecture NoSQL pour une plateforme e-commerce inspirée de LDLC. Quatre besoins sont étudiés : le **catalogue de produits**, les **paniers et sessions**, les **logs et statistiques**, et les **recommandations**. L'objectif est de concevoir, alimenter et interroger des bases adaptées à ces usages, puis de justifier les compromis techniques.

Le prototype repose sur **MongoDB, Redis, Cassandra et Neo4j**, exécutés séparément dans Docker. Il ne comprend ni interface e-commerce ni API opérationnelle.

## 2. Architecture globale

L'approche retenue est la **persistance polyglotte** : plusieurs bases spécialisées coexistent plutôt qu'un stockage unique.

| Technologie | Modèle | Responsabilité | Atout principal |
|---|---|---|---|
| MongoDB | Documents | Produits et avis | Schéma flexible |
| Redis | Clé-valeur | Paniers et sessions | Accès rapide et TTL |
| Cassandra | Wide-column | Événements et analytics | Écritures et lectures ciblées |
| Neo4j | Graphe | Relations et recommandations | Parcours de liens |

Dans l'**architecture cible**, un utilisateur passe par une application et un backend/API qui sollicite la base correspondant à l'opération métier. Cette couche applicative est **conceptuelle** : les quatre bases ont été testées indépendamment. Le schéma global figure dans `docs/architecture.md`.

Les identifiants communs (`PROD001`, `PROD003`, etc.) permettent de rapprocher les données. En revanche, la synchronisation entre bases ne serait pas automatique : elle devrait être prise en charge par l'application ou par des événements. Il n'existe pas de transaction globale garantie entre les quatre moteurs.

## 3. Lot 1 — MongoDB : catalogue produits

### Modèle et choix de conception

La base `ldlc_nosql` comporte les collections **`produits`** et **`avis`**. Chaque produit possède un identifiant, un nom, une catégorie, une marque, un prix, un stock, des `tags` et des `specifications`. Ces dernières sont **intégrées (Embedded)** au produit : elles changent selon sa catégorie (socket et cœurs pour un processeur, résolution pour un écran).

Les **avis sont séparés (References)**, reliés par `produit_id` afin de ne pas faire grossir le document produit à chaque commentaire. Les compatibilités sont également référencées par identifiants dans `produits_compatibles`.

Exemple issu du catalogue :

```json
{
  "_id": "PROD001",
  "nom": "AMD Ryzen 7 7800X3D",
  "categorie": "Processeur",
  "marque": "AMD",
  "prix": 399.99,
  "stock": 25,
  "specifications": { "socket": "AM5", "coeurs": 8, "threads": 16 },
  "tags": ["Gaming", "AMD", "Ryzen"],
  "produits_compatibles": ["PROD003"]
}
```

### Requêtes et compromis

```javascript
db.produits.find({ categorie: "Processeur", marque: "AMD" });
db.produits.find({ "specifications.socket": "AM5" });
db.produits.aggregate([
  { $lookup: {
      from: "avis", localField: "_id",
      foreignField: "produit_id", as: "avis_clients"
  }}
]);
```

Un index sur `avis.produit_id` accélère les recherches. **Avantages :** souplesse et lecture directe des caractéristiques. **Limites :** les références peuvent nécessiter `$lookup` et leur intégrité doit être contrôlée par l'application. Quatre produits de démonstration ont été enregistrés. Fichiers : `mongodb/produits.json`, `mongodb/avis.json` et `mongodb/requetes.js`.

## 4. Lot 2 — Redis : paniers et sessions

Redis répond aux besoins de données **temporaires et fréquemment modifiées**. Les paniers et sessions sont représentés par des **Hash**, identifiés par des clés préfixées.

Le panier `panier:USER001` associe chaque identifiant produit à une quantité (`PROD001 → 2`, `PROD002 → 1`). Les principales commandes testées sont :

```text
HSET panier:USER001 PROD001 2 PROD002 1
HGETALL panier:USER001
HINCRBY panier:USER001 PROD001 1
EXPIRE panier:USER001 86400
```

`HINCRBY` modifie atomiquement une quantité. Le **TTL de 86 400 secondes** correspond à 24 heures. Une session est gérée selon le même principe :

```text
HSET session:SESSION001 user_id USER001 statut connecte role client
EXPIRE session:SESSION001 1800
DEL session:SESSION001
```

Le TTL de session est fixé à **30 minutes** ; `DEL` permet sa suppression lors de la déconnexion. **Avantages :** faible latence, incréments simples, expiration automatique. **Limites :** mémoire consommée et persistance à configurer en fonction des risques de perte. Les commandes validées devraient être stockées durablement ailleurs que dans le panier. Fichiers : `redis/commandes.redis` et `docs/lot2_redis.md`.

## 5. Lot 3 — Cassandra : logs et analytics

Cassandra privilégie la **modélisation orientée requêtes**. Le keyspace `ldlc_analytics` regroupe quatre tables conçues pour des accès précis :

| Table | Accès recherché | Organisation |
|---|---|---|
| `logs_par_produit` | Événements par produit/jour | Partition `(produit_id, jour)` ; `event_id` timeuuid décroissant |
| `vues_par_produit` | Compteur de consultations | Produit et jour |
| `top_produits_semaine` | Classement hebdomadaire | Partition `semaine` ; classement par `rang` |
| `commandes_par_client` | Historique d'achat | Partition `client_id` ; `date_commande` décroissante |

Une **clé de partition** répartit les données ; les **colonnes de clustering** fixent leur ordre dans une partition. Ce découpage évite des parcours globaux mais oblige à anticiper les requêtes.

```sql
SELECT * FROM ldlc_analytics.logs_par_produit
WHERE produit_id = 'PROD001' AND jour = '2026-11-18';

SELECT * FROM ldlc_analytics.commandes_par_client
WHERE client_id = 'USER001';

UPDATE ldlc_analytics.vues_par_produit
SET nb_vues = nb_vues + 1
WHERE produit_id = 'PROD001' AND jour = '2026-11-18';
```

La table des vues utilise un **counter** : une opération répétée peut compter deux fois. Le classement hebdomadaire est une table alimentée par des résultats calculés, **pas une agrégation automatique** de Cassandra. **Avantages :** écriture et distribution à grande échelle. **Limites :** duplication des données et nouvelles tables possibles pour de nouveaux besoins. Le prototype utilise **un seul conteneur**, sans test de cluster ni de panne réseau. Fichiers : `cassandra/requetes.cql` et `docs/lot3_cassandra.md`.

## 6. Lot 4 — Neo4j : recommandations

Neo4j représente les produits par des nœuds `Produit` et leurs liens par des relations. Quatre nœuds (`PROD001` à `PROD004`) ont été créés. Trois types de relations ont été testés :

- `PROD001 -[:COMPATIBLE_AVEC]-> PROD003` : compatibilité processeur/carte mère ;
- `PROD001 -[:SIMILAIRE_A]-> PROD004` : processeurs similaires ;
- `PROD001 -[:ACHETE_AVEC {nombre_achats: 150}]-> PROD003` : achats conjoints fictifs.

Exemples Cypher :

```cypher
MATCH (:Produit {id: "PROD001"})-[:COMPATIBLE_AVEC]->(p:Produit)
RETURN p;

MATCH (:Produit {id: "PROD001"})-[r:ACHETE_AVEC]->(p:Produit)
RETURN p, r.nombre_achats;
```

Un **classement pondéré** donne, dans le scénario de démonstration, **8 points à PROD003** et **2 points à PROD004**. Il s'agit de règles métier, **pas d'un modèle d'apprentissage automatique**. **Avantages :** exploration naturelle des compatibilités et similarités. **Limites :** qualité des relations et synchronisation nécessaire avec MongoDB. Fichiers : `neo4j/requetes.cypher` et `docs/lot4_neo4j.md`.

## 7. Analyse transversale — CAP et compromis

Le **théorème CAP** décrit une contrainte des systèmes distribués : lors d'une partition réseau, ils ne peuvent garantir simultanément une cohérence forte et une disponibilité complète. Il serait imprécis d'attribuer une étiquette CAP fixe à chaque technologie sans préciser son déploiement.

- **MongoDB** : les élections et les niveaux de lecture/écriture d'un replica set influencent les garanties et la disponibilité.
- **Redis** : CAP est peu pertinent pour notre instance unique ; les compromis apparaissent avec réplication ou cluster.
- **Cassandra** : la cohérence est paramétrable ; des exigences plus fortes peuvent réduire la disponibilité durant une panne.
- **Neo4j** : en cluster, le quorum et les mécanismes de consensus conditionnent notamment la disponibilité des écritures.

La cohérence **inter-bases** est un sujet distinct : MongoDB détient les produits, Neo4j leurs relations et Redis des identifiants présents dans les paniers. Une modification ou suppression de produit peut imposer une mise à jour coordonnée. Celle-ci n'a **pas été implémentée**.

Sur les performances, MongoDB bénéficie des index, Redis des opérations en mémoire, Cassandra du partitionnement orienté requêtes et Neo4j des parcours de graphe. Aucun **benchmark de charge** n'a été mené. La persistance polyglotte améliore l'adéquation aux usages, mais accroît les coûts d'exploitation, de supervision, de sauvegarde et de synchronisation.

## 8. Conclusion et perspectives

Le projet a permis de créer un prototype de quatre familles NoSQL adaptées à des besoins distincts : **documents** pour le catalogue, **clé-valeur** pour les données temporaires, **wide-column** pour les événements et **graphe** pour les recommandations. Les structures, requêtes et choix de conception sont conservés dans le dépôt GitHub.

Ses principales limites sont les **faibles volumes de démonstration**, l'absence d'API commune, de synchronisation automatique et de tests en cluster distribué. Les recommandations reposent sur des relations fictives, non sur des comportements utilisateurs réels.

Les évolutions prioritaires seraient de développer une API, de synchroniser MongoDB et Neo4j, d'étendre les jeux de données et de tester la charge, la réplication et la reprise après incident. Ce travail démontre surtout qu'une solution NoSQL se choisit **en fonction des accès métier et des compromis**, plutôt que par préférence pour une technologie unique.
