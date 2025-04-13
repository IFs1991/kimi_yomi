package subscription

import (
	"context"
	"kimiyomi/models"
	"kimiyomi/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Request/Response structs
type CreateSubscriptionRequest struct {
	UserID      string      `json:"user_id" validate:"required"`
	PlanID      string      `json:"plan_id" validate:"required"`
	PaymentInfo PaymentInfo `json:"payment_info" validate:"required"`
}

type PaymentInfo struct {
	PaymentMethodID string `json:"payment_method_id" validate:"required"`
	Currency        string `json:"currency" validate:"required"`
}

type SubscriptionResponse struct {
	ID        string `json:"id"`
	UserID    string `json:"user_id"`
	PlanID    string `json:"plan_id"`
	Status    string `json:"status"`
	CreatedAt string `json:"created_at"`
}

// Handler struct
type SubscriptionHandler struct {
	subscriptionService services.SubscriptionService
}

// NewSubscriptionHandler creates a new subscription handler
func NewSubscriptionHandler(subscriptionService services.SubscriptionService) *SubscriptionHandler {
	return &SubscriptionHandler{
		subscriptionService: subscriptionService,
	}
}

// CreateSubscription handles subscription creation
func (h *SubscriptionHandler) CreateSubscription(c *gin.Context) {
	var req struct {
		PlanID       string `json:"plan_id" binding:"required"`
		BillingCycle string `json:"billing_cycle" binding:"required,oneof=monthly yearly"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("user_id") // From auth middleware

	// Create models.Subscription object (example - adjust as needed)
	subscription := &models.Subscription{
		UserID:       userID,
		PlanID:       req.PlanID,
		BillingCycle: req.BillingCycle,
		// Set other fields like StartDate, AutoRenew based on logic
	}

	// Pass context and the subscription object
	if err := h.subscriptionService.CreateSubscription(c.Request.Context(), subscription); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, subscription) // Return the created subscription
}

// GetSubscription handles retrieving a subscription
func (h *SubscriptionHandler) GetSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	// Pass context
	subscription, err := h.subscriptionService.GetSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Subscription not found"})
		return
	}

	c.JSON(http.StatusOK, subscription)
}

// CancelSubscription handles subscription cancellation
func (h *SubscriptionHandler) CancelSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	// Pass context
	err := h.subscriptionService.CancelSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Subscription cancelled successfully"})
}

// GetUserSubscriptions handles retrieving all subscriptions for a user
func (h *SubscriptionHandler) GetUserSubscriptions(c *gin.Context) {
	// userID := c.GetString("user_id") // From auth middleware
	// subscriptions, err := h.subscriptionService.GetUserSubscriptions(userID) // Method does not exist on interface
	// if err != nil {
	// 	c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	// 	return
	// }
	// c.JSON(http.StatusOK, subscriptions)
	c.JSON(http.StatusNotImplemented, gin.H{"message": "GetUserSubscriptions not implemented"})
}

// RenewSubscription handles subscription renewal
func (h *SubscriptionHandler) RenewSubscription(c *gin.Context) {
	// subscriptionID := c.Param("id")
	// err := h.subscriptionService.RenewSubscription(subscriptionID) // Method does not exist on interface
	// if err != nil {
	// 	c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	// 	return
	// }
	// c.JSON(http.StatusOK, gin.H{"message": "Subscription renewed successfully"})
	c.JSON(http.StatusNotImplemented, gin.H{"message": "RenewSubscription not implemented"})
}

// RegisterRoutes registers subscription routes
func (h *SubscriptionHandler) RegisterRoutes(router *gin.RouterGroup) {
	subscriptions := router.Group("/subscriptions")
	{
		subscriptions.POST("", h.CreateSubscription)
		subscriptions.GET("/:id", h.GetSubscription)
		subscriptions.POST("/:id/cancel", h.CancelSubscription)
		subscriptions.POST("/:id/renew", h.RenewSubscription)
		subscriptions.GET("", h.GetUserSubscriptions)
	}
}

// Interface for service layer
type SubscriptionAPI interface {
	CreateSubscription(ctx context.Context, req CreateSubscriptionRequest) (*SubscriptionResponse, error)
}
