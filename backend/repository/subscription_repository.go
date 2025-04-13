package repository

import (
	"context"
	"kimiyomi/models"

	"gorm.io/gorm"
)

// SubscriptionRepository defines the interface for subscription data operations
type SubscriptionRepository interface {
	GetByID(ctx context.Context, subscriptionID string) (*models.Subscription, error)
	GetByUserID(ctx context.Context, userID string) ([]*models.Subscription, error)
	Create(ctx context.Context, subscription *models.Subscription) error
	Update(ctx context.Context, subscription *models.Subscription) error
}

type subscriptionRepository struct {
	db *gorm.DB
}

// NewSubscriptionRepository creates a new instance of SubscriptionRepository
func NewSubscriptionRepository(db *gorm.DB) SubscriptionRepository {
	return &subscriptionRepository{db: db}
}

func (r *subscriptionRepository) GetByID(ctx context.Context, subscriptionID string) (*models.Subscription, error) {
	var subscription models.Subscription
	if err := r.db.WithContext(ctx).First(&subscription, "id = ?", subscriptionID).Error; err != nil {
		return nil, err
	}
	return &subscription, nil
}

func (r *subscriptionRepository) GetByUserID(ctx context.Context, userID string) ([]*models.Subscription, error) {
	var subscriptions []*models.Subscription
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Find(&subscriptions).Error; err != nil {
		return nil, err
	}
	return subscriptions, nil
}

func (r *subscriptionRepository) Create(ctx context.Context, subscription *models.Subscription) error {
	return r.db.WithContext(ctx).Create(subscription).Error
}

func (r *subscriptionRepository) Update(ctx context.Context, subscription *models.Subscription) error {
	return r.db.WithContext(ctx).Save(subscription).Error
}
