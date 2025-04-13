package v1

import (
	"net/http"
	"strconv"

	"kimiyomi/models"
	"kimiyomi/services"

	"github.com/gin-gonic/gin"
)

// DiagnosisHandler handles Big5 personality diagnosis endpoints
type DiagnosisHandler struct {
	diagnosisService services.DiagnosisService
}

// NewDiagnosisHandler creates a new instance of DiagnosisHandler
func NewDiagnosisHandler(ds services.DiagnosisService) *DiagnosisHandler {
	return &DiagnosisHandler{diagnosisService: ds}
}

// GetQuestions returns the Big5 personality assessment questions
func (h *DiagnosisHandler) GetQuestions(c *gin.Context) {
	questions, err := h.diagnosisService.GetQuestions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, questions)
}

// SubmitAnswers processes the user's Big5 assessment answers and returns results
func (h *DiagnosisHandler) SubmitAnswers(c *gin.Context) {
	var answers []models.Answer
	if err := c.ShouldBindJSON(&answers); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, _ := c.Get("userID")
	result, err := h.diagnosisService.SubmitAnswers(userID.(uint), answers)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

// GetResult retrieves a specific Big5 diagnosis result by ID
func (h *DiagnosisHandler) GetResult(c *gin.Context) {
	resultID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid result ID"})
		return
	}

	userID, _ := c.Get("userID")
	result, err := h.diagnosisService.GetResult(userID.(uint), uint(resultID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

func RegisterDiagnosisRoutes(r *gin.RouterGroup, ds services.DiagnosisService) {
	h := NewDiagnosisHandler(ds)

	r.GET("/questions", h.GetQuestions)
	r.POST("/answers", h.SubmitAnswers)
	r.GET("/results/:id", h.GetResult)
}
