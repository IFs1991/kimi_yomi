package repository

import (
	"context"
	"kimiyomi/models"

	"gorm.io/gorm"
)

// ContentRepository defines the interface for content data operations
type ContentRepository interface {
	GetByID(ctx context.Context, id string) (*models.Content, error)
	FindAll(ctx context.Context, filter models.ContentFilter) ([]models.Content, error)
	Create(ctx context.Context, content *models.Content) error
	Update(ctx context.Context, content *models.Content) error
	Delete(ctx context.Context, id string) error
}

type contentRepository struct {
	db *gorm.DB
}

// NewContentRepository creates a new instance of ContentRepository
func NewContentRepository(db *gorm.DB) ContentRepository {
	return &contentRepository{db: db}
}

func (r *contentRepository) GetByID(ctx context.Context, id string) (*models.Content, error) {
	var content models.Content
	if err := r.db.WithContext(ctx).First(&content, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &content, nil
}

func (r *contentRepository) FindAll(ctx context.Context, filter models.ContentFilter) ([]models.Content, error) {
	var contents []models.Content
	query := r.db.WithContext(ctx)

	// Apply filters if provided (example)
	if filter.Type != "" {
		query = query.Where("type = ?", filter.Type)
	}
	if filter.Status != "" {
		query = query.Where("status = ?", filter.Status)
	}

	if err := query.Find(&contents).Error; err != nil {
		return nil, err
	}
	return contents, nil
}

func (r *contentRepository) Create(ctx context.Context, content *models.Content) error {
	return r.db.WithContext(ctx).Create(content).Error
}

func (r *contentRepository) Update(ctx context.Context, content *models.Content) error {
	return r.db.WithContext(ctx).Save(content).Error
}

func (r *contentRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Delete(&models.Content{}, "id = ?", id).Error
}
