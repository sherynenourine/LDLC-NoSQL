
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
```
