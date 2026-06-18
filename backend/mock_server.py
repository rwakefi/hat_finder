from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/validation_choices")
async def get_validation_choices():
    return {
        "crown_shapes": [
            "Cattleman's",
            "Pinch Front/Teardrop/Diamond",
            "Brick/Rounded Brick/Minnick/CHL",
            "Gus/Tom Mix",
            "Gambler/Telescope/Buckaroo",
            "The Walker/West Texas Punch",
            "Open Crown"
        ],
        "brim_shapes": [
            "J (George Strait, Medium Curved)",
            "Flat/Pencil Curl",
            "Snap Brim/Flanged Brim",
            "RD (Round)",
            "JB (Bullrider)",
            "CHL (Cool Hand Luke, Shovel, Reiner Low Sides)",
            "U (Reiner High Sides)",
            "WTP (West Texas Punch, Rancher)",
            "SC (Showmanship)"
        ],
        "material_types": [
            "Felt",
            "Straw",
            "Ballcap",
            "Beanie/Flat Cap"
        ]
    }

@app.get("/api/shopify_products")
async def get_shopify_products(lite: bool = False):
    # Mock product data
    return {
        "data": {
            "products": {
                "edges": [
                    {
                        "node": {
                            "id": "gid://shopify/Product/1",
                            "title": "Mock Felt Hat",
                            "vendor": "Moon Ridge",
                            "onlineStoreUrl": "https://example.com",
                            "featuredImage": {"url": "https://placehold.co/600x400?text=Mock+Felt+Hat"},
                            "crown_shape": {"value": "[\"Cattleman's\"]"},
                            "brim_shape": {"value": "[\"Flat/Pencil Curl\"]"},
                            "felt_straw_or_ballcap": {"value": "[\"Felt\"]"},
                            "variants": {"edges": [{"node": {"id": "1", "price": "150.00"}}]}
                        }
                    }
                ]
            }
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8081)
