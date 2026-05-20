from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import time
import json
import pg8000
import urllib.parse
import httpx
from typing import List, Optional, Any
from contextlib import asynccontextmanager
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

PORT = int(os.environ.get("PORT", 8081))
DATABASE_URL = os.environ.get("DATABASE_URL")
SHOPIFY_ACCESS_TOKEN = os.environ.get("SHOPIFY_ACCESS_TOKEN")
SHOPIFY_STORE_URL = os.environ.get("SHOPIFY_STORE_URL", "https://raftermhatco.myshopify.com")
SHOPIFY_CACHE_TTL_SECONDS = int(os.environ.get("SHOPIFY_CACHE_TTL_SECONDS", "300"))

_http_client: httpx.AsyncClient | None = None
_shopify_cache: dict[str, tuple[float, Any]] = {}
_validation_cache: tuple[float, Any] | None = None

_PRODUCT_FIELDS = """
            id
            title
            onlineStoreUrl
            featuredImage {
              url
            }
            crownShape: metafield(namespace: "custom", key: "crown_shape") { value }
            brimShape: metafield(namespace: "custom", key: "brim_shape") { value }
            crownHeight: metafield(namespace: "custom", key: "crown_height") { value }
            brimWidth: metafield(namespace: "custom", key: "brim_width") { value }
            material: metafield(namespace: "custom", key: "material") { value }
            feltStrawOrBallcap: metafield(namespace: "custom", key: "felt_straw_or_ballcap") { value }
            backstrap: metafield(namespace: "custom", key: "backstrap") { value }
            stetsonProfile: metafield(namespace: "custom", key: "stetson_profile") { value }
            outdoors: metafield(namespace: "custom", key: "outdoors") { value }
            city: metafield(namespace: "custom", key: "city") { value }
            color: metafield(namespace: "custom", key: "color") { value }
            options {
              name
              values
            }
"""

def _cache_get(cache: dict[str, tuple[float, Any]], key: str) -> Any | None:
    entry = cache.get(key)
    if not entry:
        return None
    expires_at, payload = entry
    if time.time() >= expires_at:
        cache.pop(key, None)
        return None
    return payload

def _cache_set(cache: dict[str, tuple[float, Any]], key: str, payload: Any) -> None:
    cache[key] = (time.time() + SHOPIFY_CACHE_TTL_SECONDS, payload)

async def _shopify_graphql(query: str) -> dict:
    if not SHOPIFY_ACCESS_TOKEN:
        raise HTTPException(status_code=500, detail="SHOPIFY_ACCESS_TOKEN not set in backend")
    if _http_client is None:
        raise HTTPException(status_code=500, detail="HTTP client not initialized")

    url = f"{SHOPIFY_STORE_URL}/admin/api/2024-01/graphql.json"
    headers = {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": SHOPIFY_ACCESS_TOKEN,
    }
    response = await _http_client.post(url, json={"query": query}, headers=headers)
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=f"Shopify error: {response.text}")
    return response.json()

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
    global _http_client
    init_db()
    _http_client = httpx.AsyncClient(timeout=30.0)
    yield
    await _http_client.aclose()
    _http_client = None

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
async def get_shopify_products(lite: bool = Query(False)):
    """lite=true returns a smaller payload for the input wizard; full includes variant inventory."""
    cache_key = "lite" if lite else "full"
    cached = _cache_get(_shopify_cache, cache_key)
    if cached is not None:
        return cached

    if lite:
        variants_block = """
            variants(first: 1) {
              edges {
                node {
                  id
                  price
                }
              }
            }"""
    else:
        variants_block = """
            variants(first: 250) {
              edges {
                node {
                  id
                  price
                  inventoryQuantity
                  availableForSale
                  selectedOptions {
                    name
                    value
                  }
                }
              }
            }"""

    query = f"""
    query {{
      products(first: 250) {{
        edges {{
          node {{
            {_PRODUCT_FIELDS}
            {variants_block}
          }}
        }}
      }}
    }}
    """

    try:
        payload = await _shopify_graphql(query)
        _cache_set(_shopify_cache, cache_key, payload)
        return payload
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class ChatRequest(BaseModel):
    query: str

@app.post("/api/chat")
async def chat_with_agent(request: ChatRequest):
    from agents import router_agent
    try:
        response = await router_agent(request.query)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/validation_choices")
async def get_validation_choices():
    global _validation_cache
    if _validation_cache is not None:
        expires_at, payload = _validation_cache
        if time.time() < expires_at:
            return payload

    query = """
    query {
      metafieldDefinitions(first: 100, ownerType: PRODUCT) {
        edges {
          node {
            key
            namespace
            validations {
              name
              value
            }
          }
        }
      }
    }
    """

    try:
        res_json = await _shopify_graphql(query)
        if "errors" in res_json:
            raise HTTPException(status_code=500, detail=f"GraphQL errors: {res_json['errors']}")

        definitions = res_json.get("data", {}).get("metafieldDefinitions", {}).get("edges", [])

        crown_choices = []
        brim_choices = []

        for edge in definitions:
            node = edge["node"]
            namespace = node.get("namespace")
            key = node.get("key")
            validations = node.get("validations", [])

            if namespace == "custom":
                choices = []
                for val in validations:
                    if val.get("name") == "choices":
                        try:
                            choices = json.loads(val.get("value", "[]"))
                        except Exception:
                            choices = []

                if key == "crown_shape":
                    crown_choices = choices
                elif key == "brim_shape":
                    brim_choices = choices

        payload = {
            "crown_shapes": crown_choices,
            "brim_shapes": brim_choices,
        }
        _validation_cache = (time.time() + SHOPIFY_CACHE_TTL_SECONDS, payload)
        return payload
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)

