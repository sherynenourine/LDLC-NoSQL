# Lot 2 — Paniers et Sessions Utilisateurs LDLC

## 1. Contexte et besoins

Dans le cadre de la refonte de l'architecture LDLC, nous devons gérer les paniers et les sessions de navigation des utilisateurs.

Les principales contraintes sont :

- Une latence très faible pour les opérations de lecture et d'écriture.
- Une expiration automatique des paniers après une période d'inactivité.
- Le partage des sessions entre plusieurs serveurs web.
- La gestion de nombreuses connexions simultanées.

## 2. Choix technologique : Redis

Nous avons choisi Redis, une base NoSQL de type clé-valeur.

Redis stocke principalement les données en mémoire RAM, ce qui permet d'obtenir des temps d'accès très faibles.

Cette technologie convient aux paniers et aux sessions, qui sont fréquemment consultés et modifiés.

Redis propose également le TTL (*Time To Live*), permettant de supprimer automatiquement les données temporaires.

## 3. Modélisation des paniers

Chaque panier est identifié par une clé construite selon le modèle :

`panier:<identifiant_utilisateur>`

Exemple :

`panier:USER001`

Nous utilisons une structure Redis Hash :

| Champ | Valeur |
|---|---|
| PROD001 | 2 |
| PROD002 | 1 |

Chaque champ correspond à un produit et chaque valeur représente la quantité présente dans le panier.

### Opérations utilisées

- `HSET` : créer le panier ou modifier ses valeurs.
- `HGETALL` : consulter le panier.
- `HINCRBY` : augmenter ou diminuer une quantité.
- `EXPIRE` : définir une durée de vie.
- `TTL` : vérifier le temps restant.

### Gestion de l'expiration

Nous avons défini un TTL de 86 400 secondes, soit 24 heures.

Lorsqu'un utilisateur modifie son panier, le TTL est renouvelé pour simuler une expiration après inactivité.

Dans une application réelle, ce renouvellement serait déclenché par l'activité pertinente de l'utilisateur.

## 4. Modélisation des sessions

Chaque session possède une clé :

`session:<identifiant_session>`

Exemple pédagogique :

`session:SESSION001`

Les informations sont enregistrées dans un Hash :

| Champ | Valeur |
|---|---|
| user_id | USER001 |
| statut | connecte |
| role | client |

### Gestion du TTL

Nous avons défini un TTL de 1 800 secondes, soit 30 minutes.

Une session expirée est automatiquement supprimée par Redis.

Lorsqu'un utilisateur se déconnecte, la commande `DEL` supprime immédiatement sa session.

Dans un environnement de production, les identifiants de session doivent être générés de manière sécurisée et les sessions doivent être protégées contre les accès non autorisés.

## 5. Partage des sessions entre serveurs

Dans une architecture comprenant plusieurs serveurs web, les informations de session sont stockées dans Redis plutôt que dans la mémoire locale d'un serveur applicatif.

Ainsi, plusieurs serveurs peuvent consulter le même stockage de sessions, sous réserve de disposer des autorisations nécessaires.

Cela facilite la répartition des requêtes entre les différents serveurs web.

## 6. Compromis techniques et CAP

### Avantages

- Très faibles latences pour les opérations simples.
- Structures de données adaptées aux paniers.
- Gestion native de l'expiration grâce au TTL.
- Centralisation des sessions.
- Opérations atomiques sur les structures Redis.

### Limites

- Les données conservées en RAM nécessitent une capacité mémoire adaptée.
- La volatilité et la durabilité dépendent de la configuration de persistance.
- Une panne du serveur Redis peut affecter les paniers et les sessions.
- L'utilisation de réplicas peut introduire un décalage temporaire entre les copies.

### Théorème CAP

Dans une architecture Redis répliquée, le comportement lors d'une partition réseau dépend de la configuration du système.

Une réplication asynchrone peut entraîner une perte d'écritures récentes en cas de basculement.

Il n'est donc pas exact de considérer Redis comme systématiquement CP ou AP, indépendamment de son mode de déploiement.

Pour notre prototype pédagogique, nous utilisons une instance Redis unique dans Docker. Cette configuration ne permet pas, à elle seule, d'évaluer les compromis CAP d'un cluster distribué.

## 7. Conclusion

Redis répond aux besoins du Lot 2 grâce à ses performances, à ses structures Hash et à sa gestion native du TTL.

Notre prototype permet de créer et modifier des paniers, de renouveler leur expiration, de créer des sessions et de les supprimer lors de la déconnexion.

Les commandes utilisées sont enregistrées dans `redis/commandes.redis`.
