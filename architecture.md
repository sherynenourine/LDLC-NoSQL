flowchart TD
    U["Utilisateur LDLC"] --> APP["Application e-commerce LDLC"]

    APP --> API["Backend / API"]

    API --> M[("MongoDB")]
    API --> R[("Redis")]
    API --> C[("Cassandra")]
    API --> N[("Neo4j")]

    M --> MC["Catalogue produits et avis"]
    R --> RC["Paniers et sessions"]
    C --> CC["Logs et analytics"]
    N --> NC["Recommandations produits"]
