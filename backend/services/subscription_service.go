package services

import (
	"context"
	"errors"
	"time"

	"kimiyomi/models"
	"kimiyomi/repository"
)

// SubscriptionService handles subscription-related business logic
type SubscriptionService interface {
	CreateSubscription(ctx context.Context, subscription *models.Subscription) error
	GetSubscription(ctx context.Context, subscriptionID string) (*models.Subscription, error)
	UpdateSubscription(ctx context.Context, subscription *models.Subscription) error
	CancelSubscription(ctx context.Context, subscriptionID string) error
}

type subscriptionService struct {
	repo repository.SubscriptionRepository
}

// NewSubscriptionService creates a new subscription service instance
func NewSubscriptionService(repo repository.SubscriptionRepository) SubscriptionService {
	return &subscriptionService{
		repo: repo,
	}
}

func (s *subscriptionService) CreateSubscription(ctx context.Context, subscription *models.Subscription) error {
	// Validate subscription data
	if err := subscription.Validate(); err != nil {
		return err
	}

	// Set default values
	subscription.CreatedAt = time.Now()
	subscription.Status = models.SubscriptionStatusActive

	// Store in database
	return s.repo.Create(ctx, subscription)
}

func (s *subscriptionService) GetSubscription(ctx context.Context, subscriptionID string) (*models.Subscription, error) {
	if subscriptionID == "" {
		return nil, errors.New("subscription ID is required")
	}

	return s.repo.GetByID(ctx, subscriptionID)
}

func (s *subscriptionService) UpdateSubscription(ctx context.Context, subscription *models.Subscription) error {
	if subscription.ID == "" {
		return errors.New("subscription ID is required")
	}

	// Validate updated subscription data
	if err := subscription.Validate(); err != nil {
		return err
	}

	subscription.UpdatedAt = time.Now()
	return s.repo.Update(ctx, subscription)
}

func (s *subscriptionService) CancelSubscription(ctx context.Context, subscriptionID string) error {
	if subscriptionID == "" {
		return errors.New("subscription ID is required")
	}

	subscription, err := s.repo.GetByID(ctx, subscriptionID)
	if err != nil {
		return err
	}

	subscription.Status = models.SubscriptionStatusCanceled
	subscription.UpdatedAt = time.Now()

	return s.repo.Update(ctx, subscription)
}
