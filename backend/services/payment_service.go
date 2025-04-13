package services

import (
	"context"
	"errors"
	"time"

	"kimiyomi/models"
	"kimiyomi/repository"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/paymentintent"
	"github.com/stripe/stripe-go/refund"
	// "gorm.io/gorm" // Remove gorm import
)

// PaymentService handles all payment related business logic
type PaymentService interface {
	CreatePaymentIntent(ctx context.Context, userID string, amount float64, currency string) (*models.Payment, *stripe.PaymentIntent, error)
	GetPaymentByID(ctx context.Context, paymentID string) (*models.Payment, error)
	ListUserPayments(ctx context.Context, userID string) ([]*models.Payment, error)
	UpdatePaymentStatus(ctx context.Context, paymentID string, status string) error
	ProcessRefund(ctx context.Context, paymentID string) error
}

// paymentService implements PaymentService
type paymentService struct {
	payRepo  repository.PaymentRepository // Use repository.PaymentRepository
	userRepo repository.UserRepository    // Use repository.UserRepository (optional, depending on needs)
}

// NewPaymentService creates a new instance of PaymentService
func NewPaymentService(payRepo repository.PaymentRepository, userRepo repository.UserRepository) PaymentService {
	return &paymentService{
		payRepo:  payRepo,
		userRepo: userRepo,
	}
}

// CreatePaymentIntent creates a new payment intent and saves the initial payment record
func (s *paymentService) CreatePaymentIntent(ctx context.Context, userID string, amount float64, currency string) (*models.Payment, *stripe.PaymentIntent, error) {
	// TODO: Validate user existence using userRepo if necessary

	params := &stripe.PaymentIntentParams{
		Amount:   stripe.Int64(int64(amount * 100)), // Amount in cents
		Currency: stripe.String(currency),
		// Add customer ID if available: Customer: stripe.String(user.StripeCustomerID),
		// Add other necessary params like metadata, description, etc.
	}

	pi, err := paymentintent.New(params)
	if err != nil {
		return nil, nil, err // Return payment intent error
	}

	payment := &models.Payment{
		UserID:        userID,
		Amount:        amount,
		Currency:      currency,
		Status:        models.PaymentStatusPending,
		PaymentMethod: models.PaymentMethodCard, // Or determine dynamically
		StripeID:      pi.ID,
		// CreatedAt and UpdatedAt are handled by GORM/repository
	}

	// Use repository to create payment
	if err := s.payRepo.CreatePayment(ctx, payment); err != nil {
		// TODO: Consider canceling the payment intent if db creation fails
		return nil, pi, err // Return db error, but also the created payment intent
	}

	return payment, pi, nil
}

// GetPaymentByID retrieves a payment by its ID using the repository
func (s *paymentService) GetPaymentByID(ctx context.Context, paymentID string) (*models.Payment, error) {
	payment, err := s.payRepo.GetPaymentByID(ctx, paymentID)
	if err != nil {
		return nil, err // Includes record not found
	}
	return payment, nil
}

// ListUserPayments retrieves all payments for a user using the repository
func (s *paymentService) ListUserPayments(ctx context.Context, userID string) ([]*models.Payment, error) {
	return s.payRepo.ListPaymentsByUserID(ctx, userID)
}

// UpdatePaymentStatus updates the status of a payment using the repository
func (s *paymentService) UpdatePaymentStatus(ctx context.Context, paymentID string, status string) error {
	// Optional: Add validation for allowed status transitions
	payment, err := s.payRepo.GetPaymentByID(ctx, paymentID)
	if err != nil {
		return err
	}
	payment.Status = status
	payment.UpdatedAt = time.Now() // Manually update UpdatedAt or handle in repo
	return s.payRepo.UpdatePayment(ctx, payment)
}

// ProcessRefund processes a refund for a payment
func (s *paymentService) ProcessRefund(ctx context.Context, paymentID string) error {
	payment, err := s.payRepo.GetPaymentByID(ctx, paymentID)
	if err != nil {
		return err
	}

	if payment.Status != models.PaymentStatusSucceeded {
		return errors.New("payment cannot be refunded as it has not succeeded")
	}

	// Process refund through Stripe using Payment Intent ID
	refundParams := &stripe.RefundParams{
		PaymentIntent: stripe.String(payment.StripeID),
		// Add other refund params like amount, reason, metadata if needed
	}
	_, err = refund.New(refundParams)
	if err != nil {
		return err // Return Stripe refund error
	}

	// Update local payment status using the dedicated method
	return s.UpdatePaymentStatus(ctx, paymentID, models.PaymentStatusRefunded)
}

/*
// Remove old/duplicate methods that were directly using DB
// ProcessPayment handles the payment processing logic
func (s *paymentService) ProcessPayment(ctx context.Context, payment *models.Payment) error {
	// ... (Implementation using repo.CreatePayment exists)
}

// GetPayment retrieves a payment by ID
func (s *paymentService) GetPayment(paymentID string) (*models.Payment, error) {
	// ... (Implementation using repo.GetPaymentByID exists)
}

// GetUserPayments retrieves all payments for a user
func (s *paymentService) GetUserPayments(userID string) ([]models.Payment, error) {
	// ... (Implementation using repo.ListPaymentsByUserID exists)
}
*/
