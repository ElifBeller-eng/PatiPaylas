from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import os
import pyodbc
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app) # Tüm erişimlere izin ver

# --- UPLOAD KLASÖR AYARLARI ---
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# --- VERİTABANI BAĞLANTISI ---
def get_db():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=DESKTOP-PC3NTDQ\\SQLEXPRESS04;" # Burası senin sunucun
        "DATABASE=PatiPaylasDB;"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )
    return conn

# --- RESİM SERVİSİ ---
@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

# ==========================================
# 1. KULLANICI İŞLEMLERİ (AUTH)
# ==========================================

@app.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    username = data.get("username")
    password = data.get("password")
    email = data.get("email") 

    if not username or not password or not email:
        return jsonify({"error": "Eksik bilgi: Kullanıcı adı, şifre ve email zorunlu"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Users WHERE username=?", (username,))
        if cursor.fetchone():
            return jsonify({"error": "Bu kullanıcı adı zaten alınmış"}), 409

        cursor.execute(
            "INSERT INTO Users (username, password, email) VALUES (?, ?, ?)",
            (username, password, email),
        )
        conn.commit()
        return jsonify({"message": "Kayıt başarılı"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    username = data.get("username")
    password = data.get("password")

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Users WHERE username=? AND password=?", (username, password))
        
        if cursor.fetchone():
            return jsonify({"message": "Giriş başarılı"}), 200
        else:
            return jsonify({"error": "Hatalı kullanıcı adı veya şifre"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ==========================================
# 2. GÖNDERİ İŞLEMLERİ (POSTS)
# ==========================================

@app.route("/posts", methods=["GET"])
def get_posts():
    try:
        conn = get_db()
        cursor = conn.cursor()
        # ⭐ category sütununu da çekiyoruz
        cursor.execute("SELECT id, title, content, image_url, username, category FROM Posts ORDER BY id DESC")
        rows = cursor.fetchall()

        posts = []
        for row in rows:
            posts.append({
                "id": row.id,
                "title": row.title,
                "content": row.content,
                "image_url": row.image_url,
                "username": row.username,
                "category": row.category if row.category else "Diğer"
            })
        return jsonify(posts), 200
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify([]), 500

@app.route("/add_post", methods=["POST"])
def add_post():
    try:
        title = request.form.get("title")
        content = request.form.get("content")
        username = request.form.get("username")
        category = request.form.get("category") # ⭐ Kategori
        image = request.files.get("image")

        if not title or not content or not username:
            return jsonify({"error": "Eksik bilgi"}), 400

        image_url = None
        if image:
            filename = secure_filename(image.filename)
            save_path = os.path.join(UPLOAD_FOLDER, filename)
            image.save(save_path)
            image_url = f"/uploads/{filename}"

        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO Posts (title, content, image_url, username, category) VALUES (?, ?, ?, ?, ?)",
            (title, content, image_url, username, category),
        )
        conn.commit()
        return jsonify({"message": "Gönderi eklendi"}), 201
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify({"error": str(e)}), 500

# ⭐ YENİ: GÖNDERİ SİLME
@app.route("/delete_post", methods=["POST"])
def delete_post():
    data = request.get_json() or {}
    post_id = data.get("post_id")
    username = data.get("username") 

    if not post_id or not username:
        return jsonify({"error": "Eksik bilgi"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()

        # 1. Gönderi bu kişiye mi ait?
        cursor.execute("SELECT * FROM Posts WHERE id=? AND username=?", (post_id, username))
        post = cursor.fetchone()
        if not post:
            return jsonify({"error": "Yetkisiz işlem veya gönderi yok"}), 403

        # 2. Bağlı verileri temizle
        cursor.execute("DELETE FROM Likes WHERE post_id=?", (post_id,))
        cursor.execute("DELETE FROM Comments WHERE post_id=?", (post_id,))

        # 3. Gönderiyi sil
        cursor.execute("DELETE FROM Posts WHERE id=?", (post_id,))
        
        conn.commit()
        return jsonify({"message": "Gönderi silindi"}), 200
    except Exception as e:
        print(f"Delete Error: {e}")
        return jsonify({"error": str(e)}), 500

# ==========================================
# 3. BEĞENİ VE YORUM İŞLEMLERİ
# ==========================================

@app.route("/toggle_like", methods=["POST"])
def toggle_like():
    data = request.get_json() or {}
    post_id = data.get("post_id")
    username = data.get("username")

    if not post_id or not username:
        return jsonify({"error": "Eksik bilgi"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM Likes WHERE post_id=? AND username=?", (post_id, username))
        existing_like = cursor.fetchone()

        if existing_like:
            cursor.execute("DELETE FROM Likes WHERE id=?", (existing_like.id,))
            conn.commit()
            return jsonify({"status": "unliked", "message": "Beğeni geri alındı"}), 200
        else:
            cursor.execute("INSERT INTO Likes (post_id, username) VALUES (?, ?)", (post_id, username))
            conn.commit()
            return jsonify({"status": "liked", "message": "Beğenildi"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/likes/<int:post_id>", methods=["GET"])
def get_likes(post_id):
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT username FROM Likes WHERE post_id=?", (post_id,))
        rows = cursor.fetchall()
        likers = [row.username for row in rows]
        return jsonify(likers), 200
    except Exception as e:
        return jsonify([]), 500

@app.route("/add_comment", methods=["POST"])
def add_comment():
    data = request.get_json() or {}
    post_id = data.get("post_id")
    username = data.get("username")
    comment_text = data.get("comment_text")

    if not post_id or not username or not comment_text:
        return jsonify({"error": "Eksik bilgi"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO Comments (post_id, username, comment_text) VALUES (?, ?, ?)",
            (post_id, username, comment_text)
        )
        conn.commit()
        return jsonify({"message": "Yorum eklendi"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/comments/<int:post_id>", methods=["GET"])
def get_comments(post_id):
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT username, comment_text, created_at FROM Comments WHERE post_id=? ORDER BY created_at ASC", (post_id,))
        rows = cursor.fetchall()

        comments = []
        for row in rows:
            comments.append({
                "username": row.username,
                "text": row.comment_text,
                "date": str(row.created_at)
            })
        return jsonify(comments), 200
    except Exception as e:
        return jsonify([]), 500

# ==========================================
# 5. PROFİL İŞLEMLERİ
# ==========================================

@app.route("/user_info/<username>", methods=["GET"])
def get_user_info(username):
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute("SELECT email FROM Users WHERE username=?", (username,))
        user_row = cursor.fetchone()
        email = user_row.email if user_row else "E-posta yok"

        cursor.execute("SELECT COUNT(*) FROM Posts WHERE username=?", (username,))
        count_row = cursor.fetchone()
        post_count = count_row[0] if count_row else 0

        return jsonify({
            "username": username,
            "email": email,
            "post_count": post_count
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/user_posts/<username>", methods=["GET"])
def get_user_posts(username):
    try:
        conn = get_db()
        cursor = conn.cursor()
        # ⭐ category BURAYA EKLENDİ (Profil sayfasındaki hata düzelecek)
        cursor.execute("SELECT id, title, content, image_url, category FROM Posts WHERE username=? ORDER BY id DESC", (username,))
        rows = cursor.fetchall()

        posts = []
        for row in rows:
            posts.append({
                "id": row.id,
                "title": row.title,
                "content": row.content,
                "image_url": row.image_url,
                "category": row.category if row.category else "Diğer"
            })
        return jsonify(posts), 200
    except Exception as e:
        return jsonify([]), 500

# --- RUN ---
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)