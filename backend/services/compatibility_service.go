package services

import (
	"errors"
	"time"
	"your-app/models"

	"gorm.io/gorm"
)

type CompatibilityService struct {
	db *gorm.DB
}

func NewCompatibilityService(db *gorm.DB) *CompatibilityService {
	return &CompatibilityService{db: db}
}

// CalculateCompatibility 2人のユーザー間の相性を計算
func (s *CompatibilityService) CalculateCompatibility(user1ID, user2ID uint) (*models.Compatibility, error) {
	// 既存の有効な相性診断結果を確認
	var existing models.Compatibility
	err := s.db.Where("(user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)",
		user1ID, user2ID, user2ID, user1ID).
		Where("expires_at > ?", time.Now()).
		First(&existing).Error

	if err == nil {
		return &existing, nil
	}

	// ユーザーの診断結果を取得
	var user1, user2 models.User
	if err := s.db.First(&user1, user1ID).Error; err != nil {
		return nil, errors.New("user1 not found")
	}
	if err := s.db.First(&user2, user2ID).Error; err != nil {
		return nil, errors.New("user2 not found")
	}

	// 診断結果が完了していない場合はエラー
	if user1.LastDiagnosis.IsZero() || user2.LastDiagnosis.IsZero() {
		return nil, errors.New("both users must complete diagnosis first")
	}

	// 相性を計算
	compatibility := models.CalculateCompatibility(&user1, &user2)

	// 相性の説明文を生成
	compatibility.Description = s.generateCompatibilityDescription(compatibility)

	// データベースに保存
	if err := s.db.Create(compatibility).Error; err != nil {
		return nil, err
	}

	return compatibility, nil
}

// GetDailyCompatibility 日替わり相性診断を取得
func (s *CompatibilityService) GetDailyCompatibility(userID uint) (*models.Compatibility, error) {
	// ランダムなユーザーを選択（自分以外）
	var randomUser models.User
	if err := s.db.Where("id != ?", userID).Order("RANDOM()").First(&randomUser).Error; err != nil {
		return nil, err
	}

	return s.CalculateCompatibility(userID, randomUser.ID)
}

// generateCompatibilityDescription 相性診断結果の説明文を生成
func (s *CompatibilityService) generateCompatibilityDescription(c *models.Compatibility) string {
	var description string

	// 総合評価
	if c.Score >= 80 {
		description = "とても相性が良いです！お互いの価値観や生活習慣が合致しており、良好な関係を築けるでしょう。"
	} else if c.Score >= 60 {
		description = "相性は良好です。お互いの違いを理解し合えば、より良い関係を築けるでしょう。"
	} else if c.Score >= 40 {
		description = "普通の相性です。お互いの違いを認め合い、コミュニケーションを大切にすることで関係を深められます。"
	} else {
		description = "少し相性に課題があります。お互いの違いを理解し、尊重し合うことが大切です。"
	}

	// 詳細スコアに基づくアドバイス
	if c.Details.ValueScore >= 70 {
		description += "\n価値観が非常に近く、お互いを理解しやすい関係です。"
	}
	if c.Details.InterestScore >= 70 {
		description += "\n共通の興味関心が多く、一緒に楽しめる活動が見つかりやすいでしょう。"
	}
	if c.Details.LifestyleScore >= 70 {
		description += "\n生活リズムが合っており、日常生活での摩擦が少ないでしょう。"
	}
	if c.Details.EmotionScore >= 70 {
		description += "\n感情面での理解が深く、心地よいコミュニケーションが期待できます。"
	}

	return description
}

// GetCompatibilityHistory ユーザーの相性診断履歴を取得
func (s *CompatibilityService) GetCompatibilityHistory(userID uint, limit int) ([]models.Compatibility, error) {
	var history []models.Compatibility
	err := s.db.Where("user1_id = ? OR user2_id = ?", userID, userID).
		Order("created_at DESC").
		Limit(limit).
		Find(&history).Error

	return history, err
}
