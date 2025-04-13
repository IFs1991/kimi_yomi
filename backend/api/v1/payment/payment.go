package payment

import (
	"kimiyomi/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// PaymentAPI handles payment-related HTTP requests.
// Renamed from PaymentHandler
type PaymentAPI struct {
	paymentService services.PaymentService // Use interface type
}

// NewPaymentAPI creates a new payment handler instance.
// Renamed from NewPaymentHandler
func NewPaymentAPI(paymentService services.PaymentService) *PaymentAPI {
	return &PaymentAPI{
		paymentService: paymentService,
	}
}

// CreatePayment handles payment creation (creating payment intent)
func (h *PaymentAPI) CreatePayment(c *gin.Context) {
	var req struct {
		Amount   float64 `json:"amount" binding:"required,gt=0"`
		Currency string  `json:"currency" binding:"required,len=3"`
		// Add other potential fields like PaymentMethodID
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, exists := c.Get("uid") // From auth middleware (string)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Call the service method to create payment intent
	payment, pi, err := h.paymentService.CreatePaymentIntent(c.Request.Context(), userID.(string), req.Amount, req.Currency)
	if err != nil {
		// Handle potential Stripe errors vs DB errors
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create payment intent: " + err.Error()})
		return
	}

	// Return necessary info to the client, e.g., client secret from PaymentIntent
	c.JSON(http.StatusCreated, gin.H{
		"payment_id":    payment.ID,
		"client_secret": pi.ClientSecret, // Important for client-side confirmation
		"status":        payment.Status,
	})
}

// GetPayment handles retrieving a payment by ID
func (h *PaymentAPI) GetPayment(c *gin.Context) {
	paymentID := c.Param("id")
	// Pass context to service method
	payment, err := h.paymentService.GetPaymentByID(c.Request.Context(), paymentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found or error retrieving payment"})
		return
	}

	// TODO: Check if the requesting user owns this payment
	// userID, _ := c.Get("uid")
	// if payment.UserID != userID.(string) { ... }

	c.JSON(http.StatusOK, payment)
}

// ProcessRefund handles payment refund
func (h *PaymentAPI) ProcessRefund(c *gin.Context) {
	paymentID := c.Param("id")

	// TODO: Validate user permissions to refund this payment

	// Pass context to service method
	err := h.paymentService.ProcessRefund(c.Request.Context(), paymentID)
	if err != nil {
		// Handle specific errors (e.g., already refunded, not succeeded)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Refund processed successfully"})
}

// GetUserPayments handles retrieving all payments for the authenticated user
func (h *PaymentAPI) GetUserPayments(c *gin.Context) {
	userID, exists := c.Get("uid") // From auth middleware
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Pass context to service method
	payments, err := h.paymentService.ListUserPayments(c.Request.Context(), userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, payments)
}

/*
// Remove RegisterRoutes
func (h *PaymentHandler) RegisterRoutes(router *gin.RouterGroup) {
	payments := router.Group("/payments")
	{
		payments.POST("", h.CreatePayment)
		payments.GET("/:id", h.GetPayment)
		payments.POST("/:id/refund", h.ProcessRefund)
		payments.GET("", h.GetUserPayments)
	}
}
*/

/*
// Remove unused structs if any
type PaymentRequest struct {
	Amount      float64 `json:"amount" binding:"required"`
	Currency    string  `json:"currency" binding:"required"`
	Description string  `json:"description"`
}

type PaymentResponse struct {
	ID        string  `json:"id"`
	Amount    float64 `json:"amount"`
	Currency  string  `json:"currency"`
	Status    string  `json:"status"`
	CreatedAt string  `json:"created_at"`
}
*/
