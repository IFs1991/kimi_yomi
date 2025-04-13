package models

import (
	"errors"
	"time"
)

// PaymentStatus represents the status of a payment
const (
	PaymentStatusPending   = "pending"
	PaymentStatusSucceeded = "succeeded"
	PaymentStatusFailed    = "failed"
	PaymentStatusRefunded  = "refunded"
)

// PaymentMethod represents the method used for payment
const (
	PaymentMethodCard      = "card"
	PaymentMethodApplePay  = "apple_pay"
	PaymentMethodGooglePay = "google_pay"
)

// Payment represents a payment transaction
type Payment struct {
	ID            string    `json:"id" gorm:"primaryKey"`
	UserID        string    `json:"user_id" gorm:"index"`
	Amount        float64   `json:"amount"`
	Currency      string    `json:"currency"`
	Status        string    `json:"status"`
	PaymentMethod string    `json:"payment_method"`
	StripeID      string    `json:"stripe_id" gorm:"index"` // Store Stripe PaymentIntent ID
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// Validate performs validation checks on the Payment struct
func (p *Payment) Validate() error {
	if p.UserID == "" {
		return errors.New("user ID cannot be empty")
	}
	if p.Amount <= 0 {
		return errors.New("amount must be positive")
	}
	if p.Currency == "" {
		return errors.New("currency cannot be empty")
	}
	// Add more validation as needed (e.g., check status, payment method)
	return nil
}
