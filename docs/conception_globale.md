
## 3. Lot 1 — MongoDB : catalogue produits

### 3.1. Besoin métier et choix technologique

Le catalogue LDLC regroupe des produits informatiques aux caractéristiques hétérogènes. Un processeur possède un nombre de cœurs et un socket, tandis qu'un écran possède une résolution et une fréquence de rafraîchissement.

MongoDB est une base NoSQL orientée documents. Elle permet de stocker des objets JSON avec des structures flexibles, sans imposer les mêmes champs à tous les produits.

La base créée pour ce lot est `ldlc_nosql`. Elle comporte deux collections principales :
- `produits` : informations du catalogue.
- `avis` : évaluations et commentaires des clients.

### 3.2. Modélisation des données

Chaque produit possède un identifiant unique `_id`, un nom, une catégorie, une marque, un prix et un stock.

Le champ `specifications` est un sous-document dont les propriétés dépendent de la catégorie du produit. Le champ `tags` contient des mots-clés permettant de caractériser le produit.

Exemple de document :

```json
{
  "_id": "PROD001",
  "nom": "AMD Ryzen 7 7800X3D",
  "categorie": "Processeur",
  "marque": "AMD",
  "prix": 399.99,
  "stock": 25,
  "specifications": {
    "socket": "AM5",
    "coeurs": 8,
    "threads": 16,
    "frequence_ghz": 4.2,
    "cache_mb": 96
  },
  "tags": ["Gaming", "AMD", "Ryzen"],
  "produits_compatibles": ["PROD003"]
}
```

### 3.3. Choix Embedded et References

Deux stratégies de modélisation ont été utilisées.

**Embedded :** les caractéristiques techniques sont intégrées directement dans chaque document `produits`, grâce au champ `specifications`. Cette approche permet de récupérer les informations du produit en une seule lecture.

**References :** les avis sont conservés dans une collection distincte `avis`, avec un champ `produit_id` permettant de retrouver le produit concerné. Cela évite d'augmenter indéfiniment la taille des documents produits lorsque les clients publient de nouveaux avis.

Les compatibilités sont représentées par un tableau d'identifiants `produits_compatibles`. Par exemple, `PROD001` référence `PROD003`, une carte mère compatible.

### 3.4. Requêtes et index

Exemple de recherche de processeurs AMD :

```javascript
db.produits.find({
  categorie: "Processeur",
  marque: "AMD"
})
```

Exemple de filtrage sur une caractéristique technique :

```javascript
db.produits.find({
  "specifications.socket": "AM5"
})
```

Exemple de récupération des avis associés à un produit :

```javascript
db.produits.aggregate([
  {
    $lookup: {
      from: "avis",
      localField: "_id",
      foreignField: "produit_id",
      as: "avis_clients"
    }
  }
])
```

Un index sur `avis.produit_id` a été créé pour accélérer les recherches d'avis par produit.

Les données et les requêtes de ce lot sont disponibles dans le dossier `mongodb/` du dépôt GitHub.

### 3.5. Compromis techniques

Le modèle documentaire est adapté aux produits possédant des caractéristiques variables et facilite l'évolution du catalogue.

Cependant, les références entre collections nécessitent parfois des opérations de jointure avec `$lookup`. De plus, MongoDB ne garantit pas automatiquement l'intégrité des références entre documents : leur cohérence doit être contrôlée par l'application.

Pour ce projet, la séparation des avis et l'intégration des spécifications représentent un compromis entre simplicité de lecture, souplesse et évolutivité.
```
