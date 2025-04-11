package content

import (
	"net/http"
	"src/backend/models"
	"src/backend/services"
	"strconv"

	"github.com/gin-gonic/gin"
)

type ContentHandler struct {
	contentService *services.ContentService
}

func NewContentHandler(contentService *services.ContentService) *ContentHandler {
	return &ContentHandler{
		contentService: contentService,
	}
}

// CreateContent handles content creation
func (h *ContentHandler) CreateContent(c *gin.Context) {
	var content models.Content
	if err := c.ShouldBindJSON(&content); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.contentService.CreateContent(&content); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, content)
}

// GetContent handles retrieving a content item
func (h *ContentHandler) GetContent(c *gin.Context) {
	contentID := c.Param("id")
	content, err := h.contentService.GetContent(contentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Content not found"})
		return
	}

	c.JSON(http.StatusOK, content)
}

// UpdateContent handles content updates
func (h *ContentHandler) UpdateContent(c *gin.Context) {
	var content models.Content
	if err := c.ShouldBindJSON(&content); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	content.ID = c.Param("id")
	if err := h.contentService.UpdateContent(&content); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, content)
}

// DeleteContent handles content deletion
func (h *ContentHandler) DeleteContent(c *gin.Context) {
	contentID := c.Param("id")
	if err := h.contentService.DeleteContent(contentID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Content deleted successfully"})
}

// ListContents handles retrieving a list of content items
func (h *ContentHandler) ListContents(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	contents, total, err := h.contentService.ListContents(page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"contents": contents,
		"total":    total,
		"page":     page,
		"pageSize": pageSize,
	})
}

// ListContentsByType handles retrieving content items by type
func (h *ContentHandler) ListContentsByType(c *gin.Context) {
	contentType := c.Param("type")
	contents, err := h.contentService.ListContentsByType(contentType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, contents)
}

// RegisterRoutes registers content routes
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
