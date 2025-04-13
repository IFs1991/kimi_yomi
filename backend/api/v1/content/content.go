package content

import (
	"kimiyomi/models"
	"kimiyomi/services"
	"net/http"

	// "strconv"

	"github.com/gin-gonic/gin"
)

// ContentAPI handles content related API requests.
// Renamed from ContentHandler
type ContentAPI struct {
	contentService services.ContentService
}

// NewContentAPI creates a new ContentAPI instance.
// Renamed from NewContentHandler
func NewContentAPI(contentService services.ContentService) *ContentAPI {
	return &ContentAPI{
		contentService: contentService,
	}
}

// CreateContent handles content creation
func (h *ContentAPI) CreateContent(c *gin.Context) {
	var content models.Content
	if err := c.ShouldBindJSON(&content); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Pass context to service method
	if err := h.contentService.CreateContent(c.Request.Context(), &content); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, content)
}

// GetContent handles retrieving a content item
func (h *ContentAPI) GetContent(c *gin.Context) {
	contentID := c.Param("id")
	// Pass context to service method
	content, err := h.contentService.GetContent(c.Request.Context(), contentID)
	if err != nil {
		// Consider differentiating between Not Found and other errors
		c.JSON(http.StatusNotFound, gin.H{"error": "Content not found or error retrieving content"})
		return
	}

	c.JSON(http.StatusOK, content)
}

// UpdateContent handles content updates
func (h *ContentAPI) UpdateContent(c *gin.Context) {
	contentID := c.Param("id") // Get ID from path
	var content models.Content
	if err := c.ShouldBindJSON(&content); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	content.ID = contentID // Set the ID from path param, overriding any potential ID in body

	// Pass context to service method
	if err := h.contentService.UpdateContent(c.Request.Context(), &content); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, content)
}

// DeleteContent handles content deletion
func (h *ContentAPI) DeleteContent(c *gin.Context) {
	contentID := c.Param("id")
	// Pass context to service method
	if err := h.contentService.DeleteContent(c.Request.Context(), contentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Content deleted successfully"})
}

// ListContents handles retrieving a list of content items based on filters
func (h *ContentAPI) ListContents(c *gin.Context) {
	// Extract filter parameters from query string
	var filter models.ContentFilter
	if err := c.ShouldBindQuery(&filter); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid filter parameters: " + err.Error()})
		return
	}

	// Pass context and filter to service method
	contents, err := h.contentService.ListContents(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return the list of contents
	c.JSON(http.StatusOK, contents)
}

// ListContentsByType handles retrieving content items by type (maps to ListContents with filter)
func (h *ContentAPI) ListContentsByType(c *gin.Context) {
	contentType := c.Param("type")
	if contentType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Content type parameter is required"})
		return
	}

	filter := models.ContentFilter{
		Type: contentType,
		// Add other potential default filters or extract from query
	}

	// Pass context and filter to service method
	contents, err := h.contentService.ListContents(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, contents)
}

/*
// Remove RegisterRoutes as routes are defined in main.go
func (h *ContentHandler) RegisterRoutes(router *gin.RouterGroup) {
	contents := router.Group("/contents")
	{
		contents.POST("", h.CreateContent)
		contents.GET("/:id", h.GetContent)
		contents.PUT("/:id", h.UpdateContent)
		contents.DELETE("/:id", h.DeleteContent)
		contents.GET("", h.ListContents)
		contents.GET("/type/:type", h.ListContentsByType)
	}
}
*/
