import http.server
import json
import os
import pg8000
import urllib.parse

PORT = int(os.environ.get("PORT", 8080))
DATABASE_URL = os.environ.get("DATABASE_URL")

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

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        payload = json.loads(post_data) if post_data else {}

        if self.path == '/api/save_hat':
            res = self.save_hat(payload)
            self.send_success(res)
        else:
            self.send_error(404, "Not Found")

    def do_GET(self):
        if self.path == '/api/hats':
            res = self.get_hats()
            self.send_success(res)
        else:
            super().do_GET()

    def send_success(self, data):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def save_hat(self, data):
        conn = get_db_connection()
        if not conn:
            return {"status": "error", "message": "DB connection failed"}
        try:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO found_hats (name, brand, price, size, url) VALUES (%s, %s, %s, %s, %s)",
                (data.get('name'), data.get('brand'), data.get('price'), data.get('size'), data.get('url'))
            )
            conn.commit()
            return {"status": "success", "message": "Hat saved successfully"}
        except Exception as e:
            return {"status": "error", "message": str(e)}
        finally:
            conn.close()

    def get_hats(self):
        conn = get_db_connection()
        if not conn:
            return []
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
            print(f"❌ Error fetching hats: {e}")
            return []
        finally:
            conn.close()

def run():
    init_db()
    server_address = ('', PORT)
    httpd = http.server.HTTPServer(server_address, Handler)
    print(f"Starting backend on port {PORT}...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()
