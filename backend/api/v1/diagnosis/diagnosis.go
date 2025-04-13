package diagnosis

import (
	"errors"
	"net/http"
	"strconv"

	"kimiyomi/services"

	"github.com/gin-gonic/gin"
)

// DiagnosisAPI handles Big5 personality diagnosis endpoints
type DiagnosisAPI struct {
	diagnosisService services.DiagnosisService
}

// NewDiagnosisAPI creates a new instance of DiagnosisAPI
func NewDiagnosisAPI(ds services.DiagnosisService) *DiagnosisAPI {
	return &DiagnosisAPI{diagnosisService: ds}
}

// GetQuestions returns the Big5 personality assessment questions
func (h *DiagnosisAPI) GetQuestions(c *gin.Context) {
	userID, err := getUintUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized or invalid user ID format"})
		return
	}

	// Start a new session (or get existing active one - logic needed in service)
	session, err := h.diagnosisService.StartDiagnosis(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start diagnosis session: " + err.Error()})
		return
	}

	// Get the first question for this session
	question, err := h.diagnosisService.GetNextQuestion(c.Request.Context(), session.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get next question: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, question)
}

// SubmitAnswersRequest defines the structure for submitting answers
type SubmitAnswersRequest struct {
	SessionID  uint `json:"session_id" binding:"required"` // Need session ID
	QuestionID uint `json:"question_id" binding:"required"`
	Score      int  `json:"score" binding:"required,min=1,max=5"`
}

// SubmitAnswers processes a single answer submission for a session
// Changed from taking a list of answers to a single answer per request
func (h *DiagnosisAPI) SubmitAnswers(c *gin.Context) {
	var req SubmitAnswersRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Optional: Validate that the user making the request owns the session
	// userIDFromToken, _ := c.Get("uid")
	// session, err := h.diagnosisService.GetSessionByID(c.Request.Context(), req.SessionID) ... check session.UserID

	err := h.diagnosisService.SubmitAnswer(c.Request.Context(), req.SessionID, req.QuestionID, req.Score)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Maybe return the next question or completion status?
	c.JSON(http.StatusOK, gin.H{"message": "Answer submitted successfully"})
}

// GetResult retrieves the final diagnosis result for the user
// Note: This route might not need a result ID if it always fetches the latest user result
func (h *DiagnosisAPI) GetResult(c *gin.Context) {
	userID, err := getUintUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized or invalid user ID format"})
		return
	}

	// Get the result associated with the user ID
	result, err := h.diagnosisService.GetDiagnosisResult(c.Request.Context(), userID)
	if err != nil {
		// Distinguish between "not found" and other errors
		c.JSON(http.StatusNotFound, gin.H{"error": "Diagnosis result not found or error retrieving result: " + err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}

// Helper function to get and convert user ID from context
func getUintUserIDFromContext(c *gin.Context) (uint, error) {
	userIDAny, exists := c.Get("uid") // Firebase UID is typically string
	if !exists {
		return 0, errors.New("user ID not found in context")
	}
	userIDStr, ok := userIDAny.(string)
	if !ok {
		return 0, errors.New("user ID in context is not a string")
	}
	// Convert string UID to uint - This might be incorrect if Firebase UID is not numeric
	// If Firebase UID is used directly, service/repo layer needs to handle string IDs
	userIDUint64, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		return 0, errors.New("failed to parse user ID string to uint")
	}
	return uint(userIDUint64), nil
}
