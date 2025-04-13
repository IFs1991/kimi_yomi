package services

import (
	"context"

	"kimiyomi/models"
	"kimiyomi/repository"

	"gorm.io/gorm"
)

// ContentService handles business logic for content-related operations
type ContentService interface {
	GetContent(ctx context.Context, id string) (*models.Content, error)
	ListContents(ctx context.Context, filter models.ContentFilter) ([]models.Content, error)
	CreateContent(ctx context.Context, content *models.Content) error
	UpdateContent(ctx context.Context, content *models.Content) error
	DeleteContent(ctx context.Context, id string) error
}

type contentService struct {
	repo repository.ContentRepository
	db   *gorm.DB
}

// NewContentService creates a new instance of ContentService
func NewContentService(repo repository.ContentRepository, db *gorm.DB) ContentService {
	return &contentService{
		repo: repo,
		db:   db,
	}
}

// GetContent retrieves content by ID
func (s *contentService) GetContent(ctx context.Context, id string) (*models.Content, error) {
	var content models.Content
	if err := s.db.First(&content, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &content, nil
}

// ListContents retrieves contents based on filter
func (s *contentService) ListContents(ctx context.Context, filter models.ContentFilter) ([]models.Content, error) {
	return s.repo.FindAll(ctx, filter)
}

// CreateContent creates new content
func (s *contentService) CreateContent(ctx context.Context, content *models.Content) error {
	if err := content.Validate(); err != nil {
		return err
	}
	return s.repo.Create(ctx, content)
}

// UpdateContent updates existing content
func (s *contentService) UpdateContent(ctx context.Context, content *models.Content) error {
	if err := content.Validate(); err != nil {
		return err
	}
	return s.repo.Update(ctx, content)
}

// DeleteContent deletes content by ID
func (s *contentService) DeleteContent(ctx context.Context, id string) error {
	return s.repo.Delete(ctx, id)
}

// ListContents retrieves a list of content items with pagination
func (s *contentService) ListContents(page, pageSize int) ([]models.Content, int64, error) {
	var contents []models.Content
	var total int64

	if err := s.db.Model(&models.Content{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	if err := s.db.Offset(offset).Limit(pageSize).Find(&contents).Error; err != nil {
		return nil, 0, err
	}

	return contents, total, nil
}

// ListContentsByType retrieves content items by type
func (s *contentService) ListContentsByType(contentType string) ([]models.Content, error) {
	var contents []models.Content
	if err := s.db.Where("type = ?", contentType).Find(&contents).Error; err != nil {
		return nil, err
	}
	return contents, nil
}

// UpdateContentStatus updates the status of a content item
func (s *contentService) UpdateContentStatus(contentID string, status string) error {
	return s.db.Model(&models.Content{}).Where("id = ?", contentID).Update("status", status).Error
}

// GetContentByAccessLevel retrieves content items by access level
func (s *contentService) GetContentByAccessLevel(accessLevel string) ([]models.Content, error) {
	var contents []models.Content
	if err := s.db.Where("access_level = ?", accessLevel).Find(&contents).Error; err != nil {
		return nil, err
	}
	return contents, nil
}
