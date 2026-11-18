
//
// PROJET LDLC - LOT 4 : RECOMMANDATIONS PRODUITS
// Technologie : Neo4j
//

// 1. Contrainte d'unicite
CREATE CONSTRAINT produit_id_unique IF NOT EXISTS
FOR (p:Produit)
REQUIRE p.id IS UNIQUE;

// 2. Creation des produits
MERGE (p1:Produit {id: "PROD001"})
SET p1.nom = "AMD Ryzen 7 7800X3D",
    p1.categorie = "Processeur",
    p1.marque = "AMD",
    p1.prix = 399.99,
    p1.socket = "AM5";

MERGE (p2:Produit {id: "PROD002"})
SET p2.nom = "Samsung Odyssey G5 27 pouces",
    p2.categorie = "Ecran",
    p2.marque = "Samsung",
    p2.prix = 249.99;

MERGE (p3:Produit {id: "PROD003"})
SET p3.nom = "MSI B650 Gaming Plus WiFi",
    p3.categorie = "Carte mere",
    p3.marque = "MSI",
    p3.prix = 189.99,
    p3.socket = "AM5";

MERGE (p4:Produit {id: "PROD004"})
SET p4.nom = "AMD Ryzen 5 7600X",
    p4.categorie = "Processeur",
    p4.marque = "AMD",
    p4.prix = 229.99,
    p4.socket = "AM5";

// 3. Relation de compatibilite
MATCH (p1:Produit {id: "PROD001"})
MATCH (p2:Produit {id: "PROD003"})
MERGE (p1)-[:COMPATIBLE_AVEC]->(p2);

// 4. Relation de similarite
MATCH (p1:Produit {id: "PROD001"})
MATCH (p2:Produit {id: "PROD004"})
MERGE (p1)-[:SIMILAIRE_A]->(p2);

// 5. Relation d'achats communs
MATCH (p1:Produit {id: "PROD001"})
MATCH (p2:Produit {id: "PROD003"})
MERGE (p1)-[r:ACHETE_AVEC]->(p2)
SET r.nombre_achats = 150;

// 6. Afficher toutes les relations
MATCH (p:Produit)-[r]->(autre:Produit)
RETURN p, r, autre;

// 7. Recommandations d'un produit
MATCH (p:Produit {id: "PROD001"})-[r]->(rec:Produit)
RETURN
    p.nom AS produit_consulte,
    type(r) AS type_recommandation,
    rec.nom AS produit_recommande,
    rec.prix AS prix;

// 8. Recommandations avec score
MATCH (p:Produit {id: "PROD001"})-[r]->(rec:Produit)
WITH rec,
     sum(
       CASE type(r)
         WHEN "COMPATIBLE_AVEC" THEN 5
         WHEN "ACHETE_AVEC" THEN 3
         WHEN "SIMILAIRE_A" THEN 2
         ELSE 0
       END
     ) AS score
RETURN
    rec.id AS produit_id,
    rec.nom AS produit_recommande,
    rec.prix AS prix,
    score
ORDER BY score DESC;
