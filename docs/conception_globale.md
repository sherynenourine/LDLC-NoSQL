
## 8. Conclusion et perspectives

### 8.1. Bilan du projet

Ce projet a permis de concevoir et de mettre en œuvre un prototype d'architecture NoSQL pour une plateforme e-commerce inspirée de LDLC.

Quatre technologies complémentaires ont été utilisées :

- **MongoDB** pour le stockage du catalogue produits et des avis clients, avec une modélisation combinant documents intégrés et références.
- **Redis** pour la gestion des paniers et des sessions utilisateurs, en exploitant les Hash et les mécanismes d'expiration TTL.
- **Cassandra** pour le stockage des événements, le suivi des consultations et l'historique des commandes, avec une modélisation orientée requêtes.
- **Neo4j** pour représenter les relations entre produits et construire un système de recommandations pondérées.

Chaque lot a été implémenté et testé séparément dans un environnement Docker.

Les schémas, les requêtes et les choix de modélisation ont été documentés dans le dépôt GitHub.

### 8.2. Limites de la solution

Le prototype présente plusieurs limites.

Tout d'abord, les jeux de données utilisés sont réduits et essentiellement destinés à la démonstration. Ils ne permettent pas d'évaluer les performances de l'architecture à grande échelle.

Ensuite, les quatre bases de données fonctionnent indépendamment. Aucune API centrale ni synchronisation automatique entre les technologies n'a été développée.

Enfin, les mécanismes avancés de haute disponibilité, de réplication distribuée, de surveillance et de reprise après incident n'ont pas été testés dans des conditions de production.

Les recommandations Neo4j reposent sur des relations et des pondérations définies pour la démonstration, et non sur un modèle prédictif entraîné sur un historique réel.

### 8.3. Perspectives d'amélioration

Plusieurs évolutions pourraient être envisagées :

1. Développer une API permettant de centraliser l'accès aux quatre bases.
2. Mettre en place une synchronisation des produits entre MongoDB et Neo4j.
3. Étendre les jeux de données pour réaliser des tests de performance.
4. Étudier la réplication et la tolérance aux pannes sur des clusters distribués.
5. Améliorer les recommandations avec des données de navigation et d'achats réels.
6. Ajouter des mécanismes de supervision, de sauvegarde et de restauration.

### 8.4. Conclusion générale

La persistance polyglotte constitue une approche pertinente lorsque les besoins métiers nécessitent des modèles de données différents.

Dans le contexte LDLC, MongoDB, Redis, Cassandra et Neo4j répondent chacun à des usages spécifiques : catalogue, données temporaires, analytics et recommandations.

Le projet illustre ainsi l'intérêt de sélectionner une technologie selon les caractéristiques des données et les requêtes attendues, tout en soulignant les compromis liés à la cohérence, à l'exploitation et à la complexité d'une architecture multi-bases.
