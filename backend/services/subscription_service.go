package services

import (
	"context"
	"errors"
	"time"

	"kimiyomi/models"
	"kimiyomi/repository"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/sub"
	"gorm.io/gorm"
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
	db   *gorm.DB
}

// NewSubscriptionService creates a new subscription service instance
func NewSubscriptionService(repo repository.SubscriptionRepository, db *gorm.DB) SubscriptionService {
	return &subscriptionService{
		repo: repo,
		db:   db,
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

	subscription.Status = models.SubscriptionStatusCancelled
	subscription.UpdatedAt = time.Now()

	return s.repo.Update(ctx, subscription)
}

// CreateSubscription creates a new subscription
func (s *subscriptionService) CreateSubscription(userID, planID string, billingCycle string) (*models.Subscription, error) {
	// Create Stripe subscription
	params := &stripe.SubscriptionParams{
		Customer: stripe.String(userID),
		Items: []*stripe.SubscriptionItemsParams{
			{
				Plan: stripe.String(planID),
			},
		},
	}

	stripeSub, err := sub.New(params)
	if err != nil {
		return nil, err
	}

	// Create local subscription record
	sub := &models.Subscription{
		UserID:       userID,
		PlanID:       planID,
		Status:       models.SubscriptionStatusActive,
		StartDate:    time.Now(),
		EndDate:      time.Now().AddDate(0, 1, 0), // Default to 1 month
		BillingCycle: billingCycle,
		AutoRenew:    true,
		StripeSubID:  stripeSub.ID,
	}

	if err := s.db.Create(sub).Error; err != nil {
		return nil, err
	}

	return sub, nil
}

// GetSubscription retrieves a subscription by ID
func (s *subscriptionService) GetSubscription(subscriptionID string) (*models.Subscription, error) {
	var sub models.Subscription
	if err := s.db.First(&sub, "id = ?", subscriptionID).Error; err != nil {
		return nil, err
	}
	return &sub, nil
}

// UpdateSubscriptionStatus updates the status of a subscription
func (s *subscriptionService) UpdateSubscriptionStatus(subscriptionID string, status string) error {
	return s.db.Model(&models.Subscription{}).Where("id = ?", subscriptionID).Update("status", status).Error
}

// CancelSubscription cancels a subscription
func (s *subscriptionService) CancelSubscription(subscriptionID string) error {
	sub, err := s.GetSubscription(subscriptionID)
	if err != nil {
		return err
	}

	// Cancel Stripe subscription
	_, err = sub.Cancel(sub.StripeSubID, nil)
	if err != nil {
		return err
	}

	// Update local subscription record
	return s.UpdateSubscriptionStatus(subscriptionID, models.SubscriptionStatusCanceled)
}

// GetUserSubscriptions retrieves all subscriptions for a user
func (s *subscriptionService) GetUserSubscriptions(userID string) ([]models.Subscription, error) {
	var subs []models.Subscription
	if err := s.db.Where("user_id = ?", userID).Find(&subs).Error; err != nil {
		return nil, err
	}
	return subs, nil
}

// RenewSubscription renews an existing subscription
func (s *subscriptionService) RenewSubscription(subscriptionID string) error {
	sub, err := s.GetSubscription(subscriptionID)
	if err != nil {
		return err
	}

	if !sub.AutoRenew {
		return errors.New("auto-renewal is disabled for this subscription")
	}

	// Update subscription dates
	sub.StartDate = sub.EndDate
	sub.EndDate = sub.EndDate.AddDate(0, 1, 0) // Add 1 month

	return s.db.Save(sub).Error
}
