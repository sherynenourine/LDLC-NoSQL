
/*
 * PROJET LDLC - LOT 1 : CATALOGUE PRODUITS
 * Base : ldlc_nosql
 * Technologie : MongoDB
 */

// 1. Sélection de la base
db = db.getSiblingDB("ldlc_nosql");

// 2. Rechercher les processeurs
db.produits.find({
  categorie: "Processeur"
});

// 3. Produits disponibles à moins de 300 euros
db.produits.find(
  {
    prix: { $lt: 300 },
    stock: { $gt: 0 }
  },
  {
    nom: 1,
    categorie: 1,
    prix: 1,
    stock: 1
  }
);

// 4. Récupérer les références compatibles
db.produits.find(
  { _id: "PROD001" },
  {
    nom: 1,
    produits_compatibles: 1
  }
);

// 5. Récupérer les avis d'un produit
db.avis.find({
  produit_id: "PROD001"
});

// 6. Récupérer les informations des produits compatibles
db.produits.aggregate([
  {
    $match: {
      _id: "PROD001"
    }
  },
  {
    $lookup: {
      from: "produits",
      localField: "produits_compatibles",
      foreignField: "_id",
      as: "details_compatibles"
    }
  },
  {
    $project: {
      nom: 1,
      produits_compatibles: 1,
      "details_compatibles.nom": 1,
      "details_compatibles.prix": 1,
      "details_compatibles.specifications": 1
    }
  }
]);

// 7. Vérifier les index de la collection avis
db.avis.getIndexes();


 
// 8. Création de l'index pour optimiser
// la recherche des avis par produit

db.avis.createIndex(
  { produit_id: 1 },
  { name: "produit_id_1" }
);

