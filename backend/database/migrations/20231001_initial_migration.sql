-- ユーザーテーブル
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    age INT NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 診断質問テーブル
CREATE TABLE diagnosis_questions (
    id SERIAL PRIMARY KEY,
    question_text TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    weight FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 相性診断結果テーブル
CREATE TABLE compatibility_results (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    partner_id INT REFERENCES users(id),
    score FLOAT NOT NULL,
    advice TEXT NOT NULL,
    topics TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_diagnosis_questions_category ON diagnosis_questions(category);
CREATE INDEX idx_compatibility_results_user_id ON compatibility_results(user_id);