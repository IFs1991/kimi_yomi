package subscription

import (
	"kimiyomi/models"
	"kimiyomi/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

/* // Remove unused Request/Response structs
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
*/

// SubscriptionAPI handles subscription related API requests.
// Renamed from SubscriptionHandler
type SubscriptionAPI struct {
	subscriptionService services.SubscriptionService
}

// NewSubscriptionAPI creates a new subscription handler instance.
// Renamed from NewSubscriptionHandler
func NewSubscriptionAPI(subscriptionService services.SubscriptionService) *SubscriptionAPI {
	return &SubscriptionAPI{
		subscriptionService: subscriptionService,
	}
}

// CreateSubscription handles subscription creation
func (h *SubscriptionAPI) CreateSubscription(c *gin.Context) {
	var req struct {
		PlanID       string `json:"plan_id" binding:"required"`
		BillingCycle string `json:"billing_cycle" binding:"required,oneof=monthly yearly"`
		// Add PaymentMethodID or other necessary fields from client
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

	// Create models.Subscription object
	subscription := &models.Subscription{
		UserID:       userID.(string),
		PlanID:       req.PlanID,
		BillingCycle: req.BillingCycle,
		Status:       models.SubscriptionStatusActive, // Initial status
		AutoRenew:    true,                            // Default auto-renew
		// Set StartDate, EndDate based on PlanID and BillingCycle logic
		// Link Stripe Subscription ID after successful payment/setup
	}

	// Pass context and the subscription object
	if err := h.subscriptionService.CreateSubscription(c.Request.Context(), subscription); err != nil {
		// Consider more specific error handling (e.g., duplicate subscription)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create subscription: " + err.Error()})
		return
	}

	// Return the created subscription (or relevant parts)
	c.JSON(http.StatusCreated, subscription)
}

// GetSubscription handles retrieving a subscription
func (h *SubscriptionAPI) GetSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")

	// TODO: Validate that the requesting user owns this subscription or has permission
	// userID, _ := c.Get("uid")

	// Pass context
	subscription, err := h.subscriptionService.GetSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Subscription not found or error retrieving subscription"})
		return
	}

	c.JSON(http.StatusOK, subscription)
}

// CancelSubscription handles subscription cancellation
func (h *SubscriptionAPI) CancelSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")

	// TODO: Validate that the requesting user owns this subscription or has permission
	// userID, _ := c.Get("uid")

	// Pass context
	err := h.subscriptionService.CancelSubscription(c.Request.Context(), subscriptionID)
	if err != nil {
		// Handle specific errors (e.g., already cancelled)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Subscription cancelled successfully"})
}

/*
// GetUserSubscriptions - Service method not available in interface
func (h *SubscriptionAPI) GetUserSubscriptions(c *gin.Context) {
	userID, exists := c.Get("uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// subscriptions, err := h.subscriptionService.GetUserSubscriptions(c.Request.Context(), userID.(string))
	// if err != nil {
	// 	c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	// 	return
	// }
	// c.JSON(http.StatusOK, subscriptions)
	c.JSON(http.StatusNotImplemented, gin.H{"message": "GetUserSubscriptions endpoint not fully implemented"})
}

// RenewSubscription - Service method not available in interface
func (h *SubscriptionAPI) RenewSubscription(c *gin.Context) {
	subscriptionID := c.Param("id")
	// TODO: Validate ownership

	// err := h.subscriptionService.RenewSubscription(c.Request.Context(), subscriptionID)
	// if err != nil {
	// 	c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	// 	return
	// }
	// c.JSON(http.StatusOK, gin.H{"message": "Subscription renewed successfully"})
	c.JSON(http.StatusNotImplemented, gin.H{"message": "RenewSubscription endpoint not fully implemented"})
}
*/

/*
// Remove RegisterRoutes
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
*/

/*
// Remove extra interface definition
type SubscriptionAPI interface {
	CreateSubscription(ctx context.Context, req CreateSubscriptionRequest) (*SubscriptionResponse, error)
}
*/
