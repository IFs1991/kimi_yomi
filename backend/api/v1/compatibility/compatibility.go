package v1

import (
	"net/http"
	"time"

	"your_project/services"

	"github.com/gin-gonic/gin"
)

type CompatibilityHandler struct {
	service services.CompatibilityService
}

func NewCompatibilityHandler(service services.CompatibilityService) *CompatibilityHandler {
	return &CompatibilityHandler{service: service}
}

func (h *CompatibilityHandler) RegisterRoutes(router *gin.RouterGroup) {
	router.GET("/daily", h.GetDailyCompatibility)
	router.POST("/diagnose", h.DiagnoseCompatibility)
	router.GET("/result/:targetID", h.GetCompatibilityResult)
}

type CompatibilityResponse struct {
	Date               time.Time `json:"date"`
	CompatibilityScore int       `json:"compatibility_score"`
	Advice             string    `json:"advice"`
	Topics             []string  `json:"topics"`
	Big5Factors        []string  `json:"big5_factors"`
	MatchingPoints     []string  `json:"matching_points"`
}

type DiagnoseRequest struct {
	TargetUserID string `json:"target_user_id" binding:"required"`
}

func (h *CompatibilityHandler) GetDailyCompatibility(c *gin.Context) {
	userID := c.GetString("userID")

	result, err := h.service.GetDailyCompatibility(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response := CompatibilityResponse{
		Date:               time.Now(),
		CompatibilityScore: result.Score,
		Advice:             result.Advice,
		Topics:             result.Topics,
		Big5Factors:        result.Factors,
		MatchingPoints:     result.MatchPoints,
	}

	c.JSON(http.StatusOK, response)
}

type DiagnoseResponse struct {
	Score  int      `json:"score"`
	Type   string   `json:"type"`
	Advice string   `json:"advice"`
	Topics []string `json:"topics"`
}

func (h *CompatibilityHandler) DiagnoseCompatibility(c *gin.Context) {
	var req DiagnoseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	userID := c.GetString("userID")
	result, err := h.service.DiagnoseCompatibility(userID, req.TargetUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response := DiagnoseResponse{
		Score:  result.Score,
		Type:   result.Type,
		Advice: result.Advice,
		Topics: result.Topics,
	}

	c.JSON(http.StatusOK, response)
}

type PremiumContentResponse struct {
	Content      string `json:"content"`
	IsAccessible bool   `json:"is_accessible"`
}

func (h *CompatibilityHandler) AccessPremiumContent(c *gin.Context) {
	userID := c.GetString("userID")

	content, accessible, err := h.service.CheckPremiumAccess(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response := PremiumContentResponse{
		Content:      content,
		IsAccessible: accessible,
	}

	c.JSON(http.StatusOK, response)
}
