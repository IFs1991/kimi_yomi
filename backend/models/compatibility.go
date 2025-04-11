package models

import (
	"time"

	"gorm.io/gorm"
)

// Compatibility 相性診断結果モデル
type Compatibility struct {
	gorm.Model
	User1ID     uint                 `gorm:"not null"`
	User2ID     uint                 `gorm:"not null"`
	Score       float64              `gorm:"type:decimal(5,2);not null"` // 総合相性スコア（0-100）
	Description string               `gorm:"type:text"`
	Details     CompatibilityDetails `gorm:"embedded"`
	ExpiresAt   time.Time            // 相性診断の有効期限
}

// CompatibilityDetails 相性の詳細スコア
type CompatibilityDetails struct {
	ValueScore     float64 `gorm:"type:decimal(5,2)"` // 価値観の一致度
	InterestScore  float64 `gorm:"type:decimal(5,2)"` // 興味関心の一致度
	LifestyleScore float64 `gorm:"type:decimal(5,2)"` // 生活習慣の一致度
	EmotionScore   float64 `gorm:"type:decimal(5,2)"` // 感情的な相性
}

// CalculateCompatibility Big5結果に基づく相性計算
func CalculateCompatibility(user1 *User, user2 *User) *Compatibility {
	compatibility := &Compatibility{
		User1ID: user1.ID,
		User2ID: user2.ID,
		Details: CompatibilityDetails{},
	}

	// 価値観の一致度計算（開放性と誠実性の比較）
	compatibility.Details.ValueScore = calculateValueScore(user1.Big5Results, user2.Big5Results)

	// 興味関心の一致度計算（外向性の比較）
	compatibility.Details.InterestScore = calculateInterestScore(user1.Big5Results, user2.Big5Results)

	// 生活習慣の一致度計算（誠実性の比較）
	compatibility.Details.LifestyleScore = calculateLifestyleScore(user1.Big5Results, user2.Big5Results)

	// 感情的な相性計算（協調性と神経症的傾向の比較）
	compatibility.Details.EmotionScore = calculateEmotionScore(user1.Big5Results, user2.Big5Results)

	// 総合スコアの計算
	compatibility.Score = (compatibility.Details.ValueScore +
		compatibility.Details.InterestScore +
		compatibility.Details.LifestyleScore +
		compatibility.Details.EmotionScore) / 4.0

	// 有効期限の設定（1週間）
	compatibility.ExpiresAt = time.Now().AddDate(0, 0, 7)

	return compatibility
}

// 各スコア計算用のヘルパー関数
func calculateValueScore(b1, b2 Big5Results) float64 {
	return (100 - abs(b1.Openness-b2.Openness)*10 - abs(b1.Conscientiousness-b2.Conscientiousness)*10)
}

func calculateInterestScore(b1, b2 Big5Results) float64 {
	return (100 - abs(b1.Extraversion-b2.Extraversion)*20)
}

func calculateLifestyleScore(b1, b2 Big5Results) float64 {
	return (100 - abs(b1.Conscientiousness-b2.Conscientiousness)*20)
}

func calculateEmotionScore(b1, b2 Big5Results) float64 {
	return (100 - abs(b1.Agreeableness-b2.Agreeableness)*10 - abs(b1.Neuroticism-b2.Neuroticism)*10)
}

// abs 絶対値を返すヘルパー関数
func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}
