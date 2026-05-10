import os
import json
import httpx
from openai import AsyncOpenAI
from dotenv import load_dotenv

load_dotenv()

client = AsyncOpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
SHOPIFY_ACCESS_TOKEN = os.environ.get("SHOPIFY_ACCESS_TOKEN")
SHOPIFY_STORE_URL = os.environ.get("SHOPIFY_STORE_URL", "https://raftermhatco.myshopify.com")

async def fetch_shopify_products():
    """Fetches products from Shopify via GraphQL."""
    if not SHOPIFY_ACCESS_TOKEN:
        return {"error": "SHOPIFY_ACCESS_TOKEN not set"}
        
    url = f"{SHOPIFY_STORE_URL}/admin/api/2024-01/graphql.json"
    query = """
    query {
      products(first: 250) {
        edges {
          node {
            id
            title
            onlineStoreUrl
            variants(first: 1) {
              edges {
                node {
                  price
                }
              }
            }
            material: metafield(namespace: "custom", key: "material") { value }
            feltStrawOrBallcap: metafield(namespace: "custom", key: "felt_straw_or_ballcap") { value }
            crownShape: metafield(namespace: "custom", key: "crown_shape") { value }
          }
        }
      }
    }
    """
    headers = {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": SHOPIFY_ACCESS_TOKEN
    }
    async with httpx.AsyncClient() as httpx_client:
        try:
            response = await httpx_client.post(url, json={"query": query}, headers=headers)
            if response.status_code == 200:
                return response.json()
            return {"error": f"Shopify error: {response.text}"}
        except Exception as e:
            return {"error": str(e)}

async def style_expert(user_query: str) -> str:
    prompt = f"You are the Style Expert. Advise on fashion/colors for query: {user_query}"
    response = await client.chat.completions.create(
        model="gpt-4o-mini", messages=[{"role": "system", "content": prompt}]
    )
    return f"👔 Style Expert: {response.choices[0].message.content}"

async def fit_expert(user_query: str) -> str:
    prompt = f"You are the Fit Expert. Advise on face shape/sizing for query: {user_query}"
    response = await client.chat.completions.create(
        model="gpt-4o-mini", messages=[{"role": "system", "content": prompt}]
    )
    return f"📏 Fit Expert: {response.choices[0].message.content}"

async def inventory_expert(user_query: str) -> dict:
    """Extracts search filters as JSON."""
    prompt = """You are the Inventory Expert. Extract search parameters from the query.
    Return a JSON object with these keys (use null if not mentioned):
    - material (e.g., "straw", "felt")
    - crown_shape (e.g., "cattleman", "teardrop")
    - max_price (as a number)
    
    Respond with ONLY the JSON object.
    """
    response = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": prompt},
            {"role": "user", "content": user_query}
        ],
        temperature=0.0
    )
    try:
        content = response.choices[0].message.content.strip()
        # Remove markdown code blocks if present
        if content.startswith("```json"):
            content = content[7:-3].strip()
        return json.loads(content)
    except:
        return {"material": None, "crown_shape": None, "max_price": None}

async def router_agent(user_query: str) -> str:
    prompt = """Classify the user's intent into EXACTLY ONE of these categories:
    - STYLE (fashion, color advice)
    - FIT (sizing, face shape)
    - INVENTORY (looking for a specific hat, checking stock)
    
    Respond with ONLY ONE word: STYLE, FIT, or INVENTORY.
    """
    response = await client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "system", "content": prompt}, {"role": "user", "content": user_query}],
        temperature=0.0
    )
    decision = response.choices[0].message.content.strip().upper()
    
    if "STYLE" in decision:
        return await style_expert(user_query)
    elif "FIT" in decision:
        return await fit_expert(user_query)
    elif "INVENTORY" in decision:
        filters = await inventory_expert(user_query)
        products_data = await fetch_shopify_products()
        
        if "error" in products_data:
            return f"📦 Inventory Expert: Failed to fetch products. ({products_data['error']})"
            
        try:
            edges = products_data['data']['products']['edges']
            matches = []
            for edge in edges:
                node = edge['node']
                
                # Filter by material
                if filters.get('material'):
                    mat = node.get('material') or node.get('feltStrawOrBallcap')
                    mat_val = mat['value'].lower() if mat and mat.get('value') else ""
                    if filters['material'].lower() not in mat_val:
                        continue
                        
                # Filter by crown shape
                if filters.get('crown_shape'):
                    cs = node.get('crownShape')
                    cs_val = cs['value'].lower() if cs and cs.get('value') else ""
                    if filters['crown_shape'].lower() not in cs_val:
                        continue
                        
                # Filter by max price
                if filters.get('max_price'):
                    try:
                        price = float(node['variants']['edges'][0]['node']['price'])
                        if price > float(filters['max_price']):
                            continue
                    except:
                        pass
                        
                matches.append(node['title'])
                
            if matches:
                return f"📦 Inventory Expert: I found these matches in stock:\n" + "\n".join([f"- {m}" for m in matches[:5]])
            else:
                return "📦 Inventory Expert: I couldn't find any exact matches in stock for those specific parameters."
        except Exception as e:
            return f"📦 Inventory Expert: Error processing inventory. ({str(e)})"
    else:
        return await style_expert(user_query)
