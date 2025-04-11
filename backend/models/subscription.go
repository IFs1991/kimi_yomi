package models

import (
	"time"

	"gorm.io/gorm"
)

// Subscription represents a user's subscription
type Subscription struct {
	ID           string    `json:"id" gorm:"primaryKey"`
	UserID       string    `json:"user_id" gorm:"index"`
	PlanID       string    `json:"plan_id"`
	Status       string    `json:"status"`
	StartDate    time.Time `json:"start_date"`
	EndDate      time.Time `json:"end_date"`
	BillingCycle string    `json:"billing_cycle"`
	Amount       float64   `json:"amount"`
	AutoRenew    bool      `json:"auto_renew"`
	StripeSubID  string    `json:"stripe_subscription_id"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// SubscriptionStatus represents the status of a subscription
const (
	SubscriptionStatusActive   = "active"
	SubscriptionStatusInactive = "inactive"
	SubscriptionStatusCanceled = "canceled"
	SubscriptionStatusExpired  = "expired"
)

// BillingCycle represents the billing cycle options
const (
	BillingCycleMonthly = "monthly"
	BillingCycleYearly  = "yearly"
)

// Validate performs validation checks on the subscription
func (s *Subscription) Validate() error {
	// Add validation logic here
	if s.UserID == "" {
		return ErrInvalidUserID
	}
	if s.PlanID == "" {
		return ErrInvalidPlanID
	}
	if s.Amount < 0 {
		return ErrInvalidAmount
	}
	return nil
}

// BeforeCreate is a GORM hook that runs before creating a new subscription
func (s *Subscription) BeforeCreate(tx *gorm.DB) error {
	if err := s.Validate(); err != nil {
		return err
	}
	return nil
}
