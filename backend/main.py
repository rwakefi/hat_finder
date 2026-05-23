from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import os
import time
import json
import asyncio
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
SHOPIFY_DB_CACHE_TTL_SECONDS = int(os.environ.get("SHOPIFY_DB_CACHE_TTL_SECONDS", "3600"))
CACHE_REFRESH_TOKEN = os.environ.get("CACHE_REFRESH_TOKEN")
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get(
        "ALLOWED_ORIGINS",
        "https://moonridgecompany.com,https://www.moonridgecompany.com",
    ).split(",")
    if origin.strip()
]

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


def _db_cache_get(cache_key: str) -> Any | None:
    """Read catalog payload from Railway Postgres when still fresh."""
    if not DATABASE_URL or SHOPIFY_DB_CACHE_TTL_SECONDS <= 0:
        return None
    conn = get_db_connection()
    if not conn:
        return None
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT payload, EXTRACT(EPOCH FROM updated_at) AS updated_epoch
            FROM shopify_catalog_cache
            WHERE cache_key = %s
            """,
            (cache_key,),
        )
        row = cursor.fetchone()
        if not row:
            return None
        payload_raw, updated_epoch = row[0], float(row[1])
        if time.time() - updated_epoch >= SHOPIFY_DB_CACHE_TTL_SECONDS:
            return None
        if isinstance(payload_raw, str):
            return json.loads(payload_raw)
        return payload_raw
    except Exception as e:
        print(f"⚠️ DB cache read failed ({cache_key}): {e}")
        return None
    finally:
        conn.close()


def _db_cache_set(cache_key: str, payload: Any) -> None:
    if not DATABASE_URL:
        return
    conn = get_db_connection()
    if not conn:
        return
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO shopify_catalog_cache (cache_key, payload, updated_at)
            VALUES (%s, %s::jsonb, NOW())
            ON CONFLICT (cache_key)
            DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW()
            """,
            (cache_key, json.dumps(payload)),
        )
        conn.commit()
    except Exception as e:
        print(f"⚠️ DB cache write failed ({cache_key}): {e}")
    finally:
        conn.close()


async def _db_cache_get_async(cache_key: str) -> Any | None:
    return await asyncio.to_thread(_db_cache_get, cache_key)


async def _db_cache_set_async(cache_key: str, payload: Any) -> None:
    await asyncio.to_thread(_db_cache_set, cache_key, payload)


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
        print(f"⚠️ Shopify request failed ({response.status_code}): {response.text[:500]}")
        raise HTTPException(status_code=502, detail="Shopify request failed")
    return response.json()


def _ensure_refresh_allowed(request: Request, refresh: bool) -> None:
    if not refresh:
        return
    provided = request.headers.get("X-Cache-Refresh-Token")
    if not CACHE_REFRESH_TOKEN or provided != CACHE_REFRESH_TOKEN:
        raise HTTPException(status_code=403, detail="Cache refresh is restricted")

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
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS shopify_catalog_cache (
                cache_key TEXT PRIMARY KEY,
                payload JSONB NOT NULL,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        print("✅ Database initialized (found_hats + shopify_catalog_cache).")
    except Exception as e:
        print(f"❌ Failed to init DB: {e}")
    finally:
        conn.close()

async def _build_products_payload(lite: bool) -> dict:
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
    return await _shopify_graphql(query)


async def _build_validation_payload() -> dict:
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
    res_json = await _shopify_graphql(query)
    if "errors" in res_json:
        raise HTTPException(status_code=500, detail=f"GraphQL errors: {res_json['errors']}")

    definitions = res_json.get("data", {}).get("metafieldDefinitions", {}).get("edges", [])

    crown_choices = []
    brim_choices = []
    material_choices = []

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
            elif key == "felt_straw_or_ballcap":
                material_choices = choices

    return {
        "crown_shapes": crown_choices,
        "brim_shapes": brim_choices,
        "material_types": material_choices,
    }


async def _resolve_products(lite: bool, *, force_refresh: bool = False) -> dict:
    cache_key = "lite" if lite else "full"
    if not force_refresh:
        cached = _cache_get(_shopify_cache, cache_key)
        if cached is not None:
            return cached
        db_cached = await _db_cache_get_async(f"products_{cache_key}")
        if db_cached is not None:
            _cache_set(_shopify_cache, cache_key, db_cached)
            return db_cached

    payload = await _build_products_payload(lite)
    _cache_set(_shopify_cache, cache_key, payload)
    await _db_cache_set_async(f"products_{cache_key}", payload)
    return payload


async def _resolve_validation(*, force_refresh: bool = False) -> dict:
    global _validation_cache
    if not force_refresh:
        if _validation_cache is not None:
            expires_at, payload = _validation_cache
            if time.time() < expires_at:
                return payload
        db_cached = await _db_cache_get_async("validation_choices")
        if db_cached is not None:
            _validation_cache = (time.time() + SHOPIFY_CACHE_TTL_SECONDS, db_cached)
            return db_cached

    payload = await _build_validation_payload()
    _validation_cache = (time.time() + SHOPIFY_CACHE_TTL_SECONDS, payload)
    await _db_cache_set_async("validation_choices", payload)
    return payload


async def _warm_shopify_caches() -> None:
    """Populate memory + Railway DB caches so first app request is fast."""
    tasks = [
        _resolve_products(lite=True),
        _resolve_validation(),
        _resolve_products(lite=False),
    ]
    for coro in tasks:
        try:
            await coro
        except Exception as e:
            print(f"⚠️ Shopify cache warm failed: {e}")
    print("✅ Shopify catalog caches warmed.")


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _http_client
    init_db()
    _http_client = httpx.AsyncClient(timeout=30.0)
    asyncio.create_task(_warm_shopify_caches())
    yield
    await _http_client.aclose()
    _http_client = None

app = FastAPI(lifespan=lifespan)

if ALLOWED_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=ALLOWED_ORIGINS,
        allow_credentials=False,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["Content-Type", "X-Cache-Refresh-Token"],
    )

class Hat(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    brand: Optional[str] = Field(default=None, max_length=120)
    price: Optional[str] = Field(default=None, max_length=80)
    size: Optional[str] = Field(default=None, max_length=80)
    url: Optional[str] = Field(default=None, max_length=2000)

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
        print(f"⚠️ Failed to save hat: {e}")
        raise HTTPException(status_code=500, detail="Failed to save hat")
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
        print(f"⚠️ Failed to fetch saved hats: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch saved hats")
    finally:
        conn.close()

@app.get("/api/shopify_products")
async def get_shopify_products(
    request: Request,
    lite: bool = Query(False),
    refresh: bool = Query(False),
):
    """lite=true returns a smaller payload for the input wizard; full includes variant inventory."""
    _ensure_refresh_allowed(request, refresh)
    try:
        return await _resolve_products(lite, force_refresh=refresh)
    except HTTPException:
        raise
    except Exception as e:
        print(f"⚠️ Failed to resolve Shopify products: {e}")
        raise HTTPException(status_code=500, detail="Unable to load catalog")

class ChatRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=1000)

@app.post("/api/chat")
async def chat_with_agent(request: ChatRequest):
    from agents import router_agent
    try:
        response = await router_agent(request.query)
        return {"response": response}
    except Exception as e:
        print(f"⚠️ Chat agent failed: {e}")
        raise HTTPException(status_code=500, detail="Unable to complete chat request")

@app.get("/api/validation_choices")
async def get_validation_choices(
    request: Request,
    refresh: bool = False,
):
    global _validation_cache
    _ensure_refresh_allowed(request, refresh)
    if refresh:
        _validation_cache = None
    try:
        return await _resolve_validation(force_refresh=refresh)
    except HTTPException:
        raise
    except Exception as e:
        print(f"⚠️ Failed to resolve validation choices: {e}")
        raise HTTPException(status_code=500, detail="Unable to load validation choices")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
