package models

import (
	"gorm.io/gorm"
)

// Question 診断質問モデル
type Question struct {
	gorm.Model
	Category   string `gorm:"not null"`      // O, C, E, A, N のいずれか
	Content    string `gorm:"not null"`      // 質問内容
	OrderIndex int    `gorm:"not null"`      // 質問順序
	IsReversed bool   `gorm:"default:false"` // 逆転項目かどうか
}

// Answer ユーザーの回答モデル
type Answer struct {
	gorm.Model
	UserID     uint `gorm:"not null"`
	QuestionID uint `gorm:"not null"`
	Score      int  `gorm:"not null"` // 1-5の値
}

// DiagnosisSession 診断セッション
type DiagnosisSession struct {
	gorm.Model
	UserID       uint     `gorm:"not null"`
	IsComplete   bool     `gorm:"default:false"`
	CurrentIndex int      `gorm:"default:0"`
	Answers      []Answer `gorm:"foreignKey:UserID"`
}

// ValidateScore 回答スコアの検証
func (a *Answer) ValidateScore() bool {
	return a.Score >= 1 && a.Score <= 5
}

// GetCategoryQuestions カテゴリー別の質問取得
func GetCategoryQuestions(category string) []Question {
	return []Question{
		{Category: "O", Content: "新しいアイデアを考えることが好きだ", OrderIndex: 1},
		{Category: "C", Content: "計画を立てて物事を進めることが得意だ", OrderIndex: 2},
		{Category: "E", Content: "人と話すことが好きだ", OrderIndex: 3},
		{Category: "A", Content: "他人の気持ちを理解するように努めている", OrderIndex: 4},
		{Category: "N", Content: "心配性な方だ", OrderIndex: 5},
		// 他の質問も同様に追加
	}
}
