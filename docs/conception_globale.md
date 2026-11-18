
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
