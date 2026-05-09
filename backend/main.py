from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import pg8000
import urllib.parse
from typing import List, Optional
from contextlib import asynccontextmanager
import httpx

PORT = int(os.environ.get("PORT", 8080))
DATABASE_URL = os.environ.get("DATABASE_URL")
SHOPIFY_ACCESS_TOKEN = os.environ.get("SHOPIFY_ACCESS_TOKEN")
SHOPIFY_STORE_URL = "https://raftermhatco.myshopify.com"

def get_db_connection():
    if not DATABASE_URL:
        print("❌ DATABASE_URL not set!")
        return None
    try:
        # Parse connection string
        result = urllib.parse.urlparse(DATABASE_URL)
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port or 5432

        conn = pg8000.connect(
            user=username,
            password=password,
            host=hostname,
            port=port,
            database=database
        )
        return conn
    except Exception as e:
        print(f"❌ Failed to connect to DB: {e}")
        return None

def init_db():
    conn = get_db_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS found_hats (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                brand TEXT,
                price TEXT,
                size TEXT,
                url TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        print("✅ Database initialized (table found_hats checked/created).")
    except Exception as e:
        print(f"❌ Failed to init DB: {e}")
    finally:
        conn.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Run database initialization on startup
    init_db()
    yield

app = FastAPI(lifespan=lifespan)

# Enable CORS for all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Hat(BaseModel):
    name: str
    brand: Optional[str] = None
    price: Optional[str] = None
    size: Optional[str] = None
    url: Optional[str] = None

@app.post("/api/save_hat")
def save_hat(hat: Hat):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO found_hats (name, brand, price, size, url) VALUES (%s, %s, %s, %s, %s)",
            (hat.name, hat.brand, hat.price, hat.size, hat.url)
        )
        conn.commit()
        return {"status": "success", "message": "Hat saved successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@app.get("/api/hats")
def get_hats():
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id, name, brand, price, size, url, created_at FROM found_hats ORDER BY created_at DESC")
        rows = cursor.fetchall()
        results = []
        for row in rows:
            results.append({
                "id": row[0],
                "name": row[1],
                "brand": row[2],
                "price": row[3],
                "size": row[4],
                "url": row[5],
                "created_at": str(row[6])
            })
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@app.get("/api/shopify_products")
async def get_shopify_products():
    if not SHOPIFY_ACCESS_TOKEN:
        raise HTTPException(status_code=500, detail="SHOPIFY_ACCESS_TOKEN not set in backend")
    
    url = f"{SHOPIFY_STORE_URL}/admin/api/2024-01/graphql.json"
    
    query = """
    query {
      products(first: 250) {
        edges {
          node {
            id
            title
            description
            onlineStoreUrl
            featuredImage {
              url
            }
            variants(first: 1) {
              edges {
                node {
                  price {
                    amount
                    currencyCode
                  }
                }
              }
            }
            crownShape: metafield(namespace: "custom", key: "crown_shape") { value }
            brimShape: metafield(namespace: "custom", key: "brim_shape") { value }
            crownHeight: metafield(namespace: "custom", key: "crown_height") { value }
            brimWidth: metafield(namespace: "custom", key: "brim_width") { value }
            material: metafield(namespace: "custom", key: "material") { value }
            feltStrawOrBallcap: metafield(namespace: "custom", key: "felt_straw_or_ballcap") { value }
            backstrap: metafield(namespace: "custom", key: "backstrap") { value }
            stetsonProfile: metafield(namespace: "custom", key: "stetson_profile") { value }
          }
        }
      }
    }
    """
    
    headers = {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": SHOPIFY_ACCESS_TOKEN
    }
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, json={"query": query}, headers=headers)
            if response.status_code == 200:
                return response.json()
            else:
                raise HTTPException(status_code=response.status_code, detail=f"Shopify error: {response.text}")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
