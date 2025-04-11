package payment

import (
	"net/http"
	"src/backend/services"

	"github.com/gin-gonic/gin"
)

// PaymentHandler handles payment-related HTTP requests
type PaymentHandler struct {
	paymentService *services.PaymentService
}

// NewPaymentHandler creates a new payment handler instance
func NewPaymentHandler(paymentService *services.PaymentService) *PaymentHandler {
	return &PaymentHandler{
		paymentService: paymentService,
	}
}

// PaymentRequest represents the payment creation request
type PaymentRequest struct {
	Amount      float64 `json:"amount" binding:"required"`
	Currency    string  `json:"currency" binding:"required"`
	Description string  `json:"description"`
}

// PaymentResponse represents the payment response
type PaymentResponse struct {
	ID        string  `json:"id"`
	Amount    float64 `json:"amount"`
	Currency  string  `json:"currency"`
	Status    string  `json:"status"`
	CreatedAt string  `json:"created_at"`
}

// CreatePayment handles payment creation
func (h *PaymentHandler) CreatePayment(c *gin.Context) {
	var req struct {
		Amount   float64 `json:"amount" binding:"required,gt=0"`
		Currency string  `json:"currency" binding:"required,len=3"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id") // From auth middleware
	payment, err := h.paymentService.CreatePayment(userID, req.Amount, req.Currency)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, payment)
}

// GetPayment handles retrieving a payment
func (h *PaymentHandler) GetPayment(c *gin.Context) {
	paymentID := c.Param("id")
	payment, err := h.paymentService.GetPayment(paymentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
		return
	}

	c.JSON(http.StatusOK, payment)
}

// ProcessRefund handles payment refund
func (h *PaymentHandler) ProcessRefund(c *gin.Context) {
	paymentID := c.Param("id")
	err := h.paymentService.ProcessRefund(paymentID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Refund processed successfully"})
}

// GetUserPayments handles retrieving all payments for a user
func (h *PaymentHandler) GetUserPayments(c *gin.Context) {
	userID := c.GetString("user_id") // From auth middleware
	payments, err := h.paymentService.GetUserPayments(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, payments)
}

// RegisterRoutes registers payment routes
func (h *PaymentHandler) RegisterRoutes(router *gin.RouterGroup) {
	payments := router.Group("/payments")
	{
		payments.POST("", h.CreatePayment)
		payments.GET("/:id", h.GetPayment)
		payments.POST("/:id/refund", h.ProcessRefund)
		payments.GET("", h.GetUserPayments)
	}
}
