package compatibility

import (
	"kimiyomi/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// CompatibilityAPI handles compatibility related API requests.
// Renamed from CompatibilityHandler
type CompatibilityAPI struct {
	service services.CompatibilityService
}

// NewCompatibilityAPI creates a new CompatibilityAPI instance.
// Renamed from NewCompatibilityHandler
func NewCompatibilityAPI(service services.CompatibilityService) *CompatibilityAPI {
	return &CompatibilityAPI{service: service}
}

// RegisterRoutes registers compatibility routes (adjust as needed).
// func (h *CompatibilityAPI) RegisterRoutes(router *gin.RouterGroup) {
// 	router.GET("/daily", h.GetDailyCompatibility)
// 	router.POST("/calculate", h.CalculateCompatibility) // Assuming this handler exists
// }

// --- Request/Response Structs (Keep only those needed by current routes) ---

// // CompatibilityResponse struct for /daily endpoint (adjust fields based on service response)
// type CompatibilityResponse struct {
// 	Date               time.Time `json:"date"`
// 	CompatibilityScore float64   `json:"compatibility_score"` // Match service model type
// 	Description        string    `json:"description"`
// 	// Add other relevant fields from models.Compatibility
// }

// CalculateRequest struct for /calculate endpoint
type CalculateRequest struct {
	User2ID string `json:"user2_id" binding:"required"`
}

// // CalculateResponse struct for /calculate endpoint (adjust fields based on service response)
// type CalculateResponse struct {
// 	CompatibilityScore float64 `json:"compatibility_score"` // Match service model type
// 	Description        string  `json:"description"`
// 	// Add other relevant fields from models.Compatibility
// }

// --- Handlers ---

// GetDailyCompatibility handles GET /daily requests.
func (h *CompatibilityAPI) GetDailyCompatibility(c *gin.Context) {
	userID, exists := c.Get("uid") // Get UID from middleware context
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	result, err := h.service.GetDailyCompatibility(c.Request.Context(), userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return the raw models.Compatibility for now, or map to a specific response struct
	c.JSON(http.StatusOK, result)
}

// CalculateCompatibility handles POST /calculate requests.
func (h *CompatibilityAPI) CalculateCompatibility(c *gin.Context) {
	var req CalculateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request: " + err.Error()})
		return
	}

	user1ID, exists := c.Get("uid") // Get UID from middleware context
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	result, err := h.service.CalculateCompatibility(c.Request.Context(), user1ID.(string), req.User2ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return the raw models.Compatibility for now, or map to a specific response struct
	c.JSON(http.StatusOK, result)
}

/*
// Remove unused handlers and structs

func (h *CompatibilityHandler) DiagnoseCompatibility(c *gin.Context) {
	// ... removed ...
}

type DiagnoseResponse struct {
	// ... removed ...
}

func (h *CompatibilityHandler) GetCompatibilityResult(c *gin.Context) {
    // ... This route wasn't in main.go
}

type PremiumContentResponse struct {
    // ... removed ...
}

func (h *CompatibilityHandler) AccessPremiumContent(c *gin.Context) {
    // ... This route wasn't in main.go
}
*/
