-- 1. Kullanýcýlara E-Posta sütunu ekle
ALTER TABLE Users
ADD email NVARCHAR(100);
GO

-- 2. Beðenileri tutacak tabloyu oluþtur
CREATE TABLE Likes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    post_id INT NOT NULL,
    username NVARCHAR(50) NOT NULL -- Kim beðendi?
);
GO

-- 3. Yorumlarý tutacak tabloyu oluþtur
CREATE TABLE Comments (
    id INT IDENTITY(1,1) PRIMARY KEY,
    post_id INT NOT NULL,
    username NVARCHAR(50) NOT NULL, -- Kim yorum yaptý?
    comment_text NVARCHAR(MAX) NOT NULL,
    created_at DATETIME DEFAULT GETDATE() -- Ne zaman?
);
GO


ALTER TABLE Posts
ADD category NVARCHAR(50);
GO

UPDATE Posts
SET category = 'Kedi'
WHERE category IS NULL;
GO