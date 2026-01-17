from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import os
import pyodbc
from werkzeug.utils import secure_filename

app = Flask(__name__)

# 1. CORS AYARI
CORS(app)

# 2. UPLOAD KLASÖRÜ AYARI
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# -----------------------------
# SQL SERVER BAĞLANTISI
# -----------------------------
def get_db():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=DESKTOP-PC3NTDQ\\SQLEXPRESS04;"
        "DATABASE=PatiPaylasDB;"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )
    return conn

# -----------------------------
# FOTOĞRAF SERVİSİ
# -----------------------------
@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

# -----------------------------
# REGISTER
# -----------------------------
@app.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Eksik bilgi"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM Users WHERE username=?", (username,))
        existing = cursor.fetchone()

        if existing:
            return jsonify({"error": "Kullanıcı zaten var"}), 409

        cursor.execute(
            "INSERT INTO Users (username, password) VALUES (?, ?)",
            (username, password),
        )
        conn.commit()
        return jsonify({"message": "Kayıt başarılı"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -----------------------------
# LOGIN
# -----------------------------
@app.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    username = data.get("username")
    password = data.get("password")

    try:
        conn = get_db()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT * FROM Users WHERE username=? AND password=?",
            (username, password)
        )
        user = cursor.fetchone()

        if user:
            return jsonify({"message": "Giriş başarılı"}), 200
        else:
            return jsonify({"error": "Hatalı bilgi"}), 401
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -----------------------------
# POSTS LİSTELEME (GÜNCELLENDİ: username EKLENDİ)
# -----------------------------
@app.route("/posts", methods=["GET"])
def get_posts():
    try:
        conn = get_db()
        cursor = conn.cursor()

        # ⭐ username sütununu da çekiyoruz
        cursor.execute("SELECT id, title, content, image_url, username FROM Posts ORDER BY id DESC")
        rows = cursor.fetchall()

        posts = [
            {
                "id": row.id,
                "title": row.title,
                "content": row.content,
                "image_url": row.image_url,
                "username": row.username  # ⭐ Listeye ekledik
            }
            for row in rows
        ]

        return jsonify(posts), 200
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify([]), 500

# -----------------------------
# FOTOĞRAFLI POST EKLEME (GÜNCELLENDİ: username EKLENDİ)
# -----------------------------
@app.route("/add_post", methods=["POST"])
def add_post():
    try:
        title = request.form.get("title")
        content = request.form.get("content")
        username = request.form.get("username") # ⭐ Username'i formdan alıyoruz
        image = request.files.get("image")

        if not title or not content:
            return jsonify({"error": "Eksik bilgi"}), 400

        image_url = None
        if image:
            filename = secure_filename(image.filename)
            save_path = os.path.join(UPLOAD_FOLDER, filename)
            image.save(save_path)
            image_url = f"/uploads/{filename}"

        conn = get_db()
        cursor = conn.cursor()

        # ⭐ Tabloya username ile kaydediyoruz
        cursor.execute(
            "INSERT INTO Posts (title, content, image_url, username) VALUES (?, ?, ?, ?)",
            (title, content, image_url, username),
        )
        conn.commit()

        return jsonify({"message": "Gönderi eklendi"}), 201
    except Exception as e:
        print(f"Hata: {e}")
        return jsonify({"error": str(e)}), 500

# -----------------------------
# RUN
# -----------------------------
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)