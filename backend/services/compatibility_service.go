package services

import (
	"context"
	"errors"
	"kimiyomi/models"
	"kimiyomi/repository"
)

// CompatibilityService defines the interface for compatibility logic
type CompatibilityService interface {
	CalculateCompatibility(ctx context.Context, user1ID string, user2ID string) (*models.Compatibility, error)
	GetDailyCompatibility(ctx context.Context, userID string) (*models.Compatibility, error)
	GetCompatibilityHistory(ctx context.Context, userID string, limit int) ([]models.Compatibility, error)
}

// compatibilityService implements CompatibilityService
type compatibilityService struct {
	compRepo repository.CompatibilityRepository
	userRepo repository.UserRepository
}

// NewCompatibilityService creates a new instance of CompatibilityService
func NewCompatibilityService(compRepo repository.CompatibilityRepository, userRepo repository.UserRepository) CompatibilityService {
	return &compatibilityService{
		compRepo: compRepo,
		userRepo: userRepo,
	}
}

// CalculateCompatibility calculates compatibility between two users
func (s *compatibilityService) CalculateCompatibility(ctx context.Context, user1ID string, user2ID string) (*models.Compatibility, error) {
	// TODO: Check for existing valid compatibility result using compRepo
	// existing, err := s.compRepo.FindValidCompatibility(ctx, user1ID, user2ID)
	// if err == nil {
	// 	 return existing, nil
	// } else if !errors.Is(err, gorm.ErrRecordNotFound) { // Handle other errors
	// 	 return nil, err
	// }

	// Get user diagnosis results using userRepo
	user1, err := s.userRepo.GetByID(ctx, user1ID)
	if err != nil {
		return nil, errors.New("user1 not found")
	}
	user2, err := s.userRepo.GetByID(ctx, user2ID)
	if err != nil {
		return nil, errors.New("user2 not found")
	}

	// Check if both users have completed diagnosis
	if user1.LastDiagnosis.IsZero() || user2.LastDiagnosis.IsZero() {
		return nil, errors.New("both users must complete diagnosis first")
	}

	// Calculate compatibility (assuming this logic stays in models or is moved to service)
	compatibility := models.CalculateCompatibility(user1, user2)

	// Generate description
	compatibility.Description = s.generateCompatibilityDescription(compatibility)

	// Save the result using compRepo
	if err := s.compRepo.CreateCompatibilityResult(ctx, compatibility); err != nil {
		return nil, err
	}

	return compatibility, nil
}

// GetDailyCompatibility gets a daily compatibility check with a random user
func (s *compatibilityService) GetDailyCompatibility(ctx context.Context, userID string) (*models.Compatibility, error) {
	// TODO: Get a random user ID (excluding userID) using userRepo
	// randomUserID, err := s.userRepo.GetRandomUserID(ctx, userID)
	// if err != nil {
	// 	 return nil, err
	// }
	var randomUserID string = "some_random_user_id" // Placeholder

	return s.CalculateCompatibility(ctx, userID, randomUserID)
}

// generateCompatibilityDescription generates the description text for a compatibility result
// (This method remains largely unchanged as it's pure logic)
func (s *compatibilityService) generateCompatibilityDescription(c *models.Compatibility) string {
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

	// 詳細スコアに基づくアドバイス (Assuming Details field exists)
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

// GetCompatibilityHistory retrieves compatibility history for a user
func (s *compatibilityService) GetCompatibilityHistory(ctx context.Context, userID string, limit int) ([]models.Compatibility, error) {
	// Use compRepo to get history
	// return s.compRepo.GetCompatibilityHistoryByUserID(ctx, userID, limit)
	return nil, errors.New("GetCompatibilityHistory not fully implemented") // Placeholder
}
