package services

import (
	"context"
	"errors"
	"time"

	"backend/models"
	"backend/repository"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/paymentintent"
	"github.com/stripe/stripe-go/refund"
	"gorm.io/gorm"
)

// PaymentService handles all payment related business logic
type PaymentService interface {
	ProcessPayment(ctx context.Context, payment *models.Payment) error
	GetPaymentByID(ctx context.Context, paymentID string) (*models.Payment, error)
	ListPayments(ctx context.Context, userID string) ([]*models.Payment, error)
	CreatePayment(userID string, amount float64, currency string) (*models.Payment, error)
	GetPayment(paymentID string) (*models.Payment, error)
	UpdatePaymentStatus(paymentID string, status string) error
	ProcessRefund(paymentID string) error
	GetUserPayments(userID string) ([]models.Payment, error)
}

type paymentService struct {
	repo repository.PaymentRepository
	db   *gorm.DB
}

// NewPaymentService creates a new instance of PaymentService
func NewPaymentService(repo repository.PaymentRepository, db *gorm.DB) PaymentService {
	return &paymentService{
		repo: repo,
		db:   db,
	}
}

// ProcessPayment handles the payment processing logic
func (s *paymentService) ProcessPayment(ctx context.Context, payment *models.Payment) error {
	// Validate payment
	if err := payment.Validate(); err != nil {
		return err
	}

	// Set payment timestamp
	payment.CreatedAt = time.Now()
	payment.UpdatedAt = time.Now()

	// Process payment through external payment gateway
	// TODO: Implement payment gateway integration

	// Save payment to database
	if err := s.repo.CreatePayment(ctx, payment); err != nil {
		return err
	}

	return nil
}

// GetPaymentByID retrieves a payment by its ID
func (s *paymentService) GetPaymentByID(ctx context.Context, paymentID string) (*models.Payment, error) {
	payment, err := s.repo.GetPaymentByID(ctx, paymentID)
	if err != nil {
		return nil, err
	}
	if payment == nil {
		return nil, errors.New("payment not found")
	}
	return payment, nil
}

// ListPayments retrieves all payments for a user
func (s *paymentService) ListPayments(ctx context.Context, userID string) ([]*models.Payment, error) {
	payments, err := s.repo.ListPaymentsByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}
	return payments, nil
}

// CreatePayment creates a new payment intent
func (s *paymentService) CreatePayment(userID string, amount float64, currency string) (*models.Payment, error) {
	params := &stripe.PaymentIntentParams{
		Amount:   stripe.Int64(int64(amount * 100)), // Convert to cents
		Currency: stripe.String(currency),
	}

	pi, err := paymentintent.New(params)
	if err != nil {
		return nil, err
	}

	payment := &models.Payment{
		UserID:        userID,
		Amount:        amount,
		Currency:      currency,
		Status:        models.PaymentStatusPending,
		PaymentMethod: models.PaymentMethodCard,
		StripeID:      pi.ID,
	}

	if err := s.db.Create(payment).Error; err != nil {
		return nil, err
	}

	return payment, nil
}

// GetPayment retrieves a payment by ID
func (s *paymentService) GetPayment(paymentID string) (*models.Payment, error) {
	var payment models.Payment
	if err := s.db.First(&payment, "id = ?", paymentID).Error; err != nil {
		return nil, err
	}
	return &payment, nil
}

// UpdatePaymentStatus updates the status of a payment
func (s *paymentService) UpdatePaymentStatus(paymentID string, status string) error {
	return s.db.Model(&models.Payment{}).Where("id = ?", paymentID).Update("status", status).Error
}

// ProcessRefund processes a refund for a payment
func (s *paymentService) ProcessRefund(paymentID string) error {
	payment, err := s.GetPayment(paymentID)
	if err != nil {
		return err
	}

	if payment.Status != models.PaymentStatusSucceeded {
		return errors.New("payment cannot be refunded")
	}

	// Process refund through Stripe
	refundParams := &stripe.RefundParams{
		PaymentIntent: stripe.String(payment.StripeID),
	}
	_, err = refund.New(refundParams)
	if err != nil {
		return err
	}

	return s.UpdatePaymentStatus(paymentID, models.PaymentStatusRefunded)
}

// GetUserPayments retrieves all payments for a user
func (s *paymentService) GetUserPayments(userID string) ([]models.Payment, error) {
	var payments []models.Payment
	if err := s.db.Where("user_id = ?", userID).Find(&payments).Error; err != nil {
		return nil, err
	}
	return payments, nil
}
