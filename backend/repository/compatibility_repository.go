package repository

import (
	"context"

	"kimiyomi/models"

	"gorm.io/gorm"
)

// CompatibilityRepository defines operations for compatibility data
type CompatibilityRepository interface {
	CreateCompatibilityResult(ctx context.Context, result *models.Compatibility) error
	GetCompatibilityResultByID(ctx context.Context, id string) (*models.Compatibility, error)
	GetCompatibilityResultsByUserID(ctx context.Context, userID string) ([]models.Compatibility, error)
	// Add other necessary methods like CalculateCompatibility, GetAdvice etc.
}

// --- Implementation ---

type compatibilityRepository struct {
	db *gorm.DB
}

// NewCompatibilityRepository creates a new instance of CompatibilityRepository
func NewCompatibilityRepository(db *gorm.DB) CompatibilityRepository {
	return &compatibilityRepository{db: db}
}

func (r *compatibilityRepository) CreateCompatibilityResult(ctx context.Context, result *models.Compatibility) error {
	return r.db.WithContext(ctx).Create(result).Error
}

func (r *compatibilityRepository) GetCompatibilityResultByID(ctx context.Context, id string) (*models.Compatibility, error) {
	var result models.Compatibility
	// Assuming Compatibility ID is uint
	if err := r.db.WithContext(ctx).First(&result, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *compatibilityRepository) GetCompatibilityResultsByUserID(ctx context.Context, userID string) ([]models.Compatibility, error) {
	var results []models.Compatibility
	// Assuming User ID is uint
	if err := r.db.WithContext(ctx).Where("user1_id = ? OR user2_id = ?", userID, userID).Order("created_at DESC").Find(&results).Error; err != nil {
		return nil, err
	}
	return results, nil
}

// TODO: Implement other methods like FindValidCompatibility if needed by the service
