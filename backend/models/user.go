package models

import (
	"time"

	"gorm.io/gorm"
)

// User ユーザーモデル
type User struct {
	gorm.Model
	Email         string `gorm:"uniqueIndex;not null"`
	Password      string `gorm:"not null"`
	Name          string `gorm:"not null"`
	DateOfBirth   time.Time
	Gender        string
	Big5Results   Big5Results `gorm:"embedded"`
	LastDiagnosis time.Time
}

// Big5Results Big5診断結果
type Big5Results struct {
	Openness          float64 `gorm:"type:decimal(3,2)"` // 開放性
	Conscientiousness float64 `gorm:"type:decimal(3,2)"` // 誠実性
	Extraversion      float64 `gorm:"type:decimal(3,2)"` // 外向性
	Agreeableness     float64 `gorm:"type:decimal(3,2)"` // 協調性
	Neuroticism       float64 `gorm:"type:decimal(3,2)"` // 神経症的傾向
	UpdatedAt         time.Time
}

// ValidateBig5Score Big5スコアの検証
func (b *Big5Results) ValidateBig5Score() bool {
	scores := []float64{
		b.Openness,
		b.Conscientiousness,
		b.Extraversion,
		b.Agreeableness,
		b.Neuroticism,
	}

	for _, score := range scores {
		if score < 1.0 || score > 5.0 {
			return false
		}
	}
	return true
}

type Profile struct {
	UserID      uint `gorm:"primaryKey"`
	Bio         string
	Interests   string
	Location    string
	Website     string
	SocialLinks string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type AuthToken struct {
	UserID    uint `gorm:"primaryKey"`
	Token     string
	ExpiresAt time.Time
	CreatedAt time.Time
}
