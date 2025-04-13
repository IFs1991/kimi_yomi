package repository

import (
	"context"
	"kimiyomi/models"

	"gorm.io/gorm"
)

// PaymentRepository defines the interface for payment data operations
type PaymentRepository interface {
	GetPaymentByID(ctx context.Context, paymentID string) (*models.Payment, error)
	ListPaymentsByUserID(ctx context.Context, userID string) ([]*models.Payment, error)
	CreatePayment(ctx context.Context, payment *models.Payment) error
	UpdatePayment(ctx context.Context, payment *models.Payment) error
}

type paymentRepository struct {
	db *gorm.DB
}

// NewPaymentRepository creates a new instance of PaymentRepository
func NewPaymentRepository(db *gorm.DB) PaymentRepository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) GetPaymentByID(ctx context.Context, paymentID string) (*models.Payment, error) {
	var payment models.Payment
	if err := r.db.WithContext(ctx).First(&payment, "id = ?", paymentID).Error; err != nil {
		return nil, err
	}
	return &payment, nil
}

func (r *paymentRepository) ListPaymentsByUserID(ctx context.Context, userID string) ([]*models.Payment, error) {
	var payments []*models.Payment
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Find(&payments).Error; err != nil {
		return nil, err
	}
	return payments, nil
}

func (r *paymentRepository) CreatePayment(ctx context.Context, payment *models.Payment) error {
	return r.db.WithContext(ctx).Create(payment).Error
}

func (r *paymentRepository) UpdatePayment(ctx context.Context, payment *models.Payment) error {
	return r.db.WithContext(ctx).Save(payment).Error
}
