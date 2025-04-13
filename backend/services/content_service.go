package services

import (
	"context"

	"kimiyomi/models"
	"kimiyomi/repository"
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
}

// NewContentService creates a new instance of ContentService
func NewContentService(repo repository.ContentRepository) ContentService {
	return &contentService{
		repo: repo,
	}
}

// GetContent retrieves content by ID
func (s *contentService) GetContent(ctx context.Context, id string) (*models.Content, error) {
	return s.repo.GetByID(ctx, id)
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
