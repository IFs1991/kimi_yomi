package models

import (
	"errors"
	"time"
)

// Content represents a content item in the system
type Content struct {
	ID          string    `json:"id" gorm:"primaryKey"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Type        string    `json:"type"`
	Price       float64   `json:"price"`
	Status      string    `json:"status"`
	MediaURL    string    `json:"media_url"`
	AccessLevel string    `json:"access_level"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ContentType represents the type of content
const (
	ContentTypeArticle = "article"
	ContentTypeVideo   = "video"
	ContentTypeAudio   = "audio"
)

// ContentStatus represents the status of content
const (
	ContentStatusDraft     = "draft"
	ContentStatusPublished = "published"
	ContentStatusArchived  = "archived"
)

// AccessLevel represents content access levels
const (
	AccessLevelFree        = "free"
	AccessLevelPremium     = "premium"
	AccessLevelSubscribers = "subscribers"
)

// Validate performs validation on Content fields
func (c *Content) Validate() error {
	if c.Title == "" {
		return ErrInvalidTitle
	}
	if c.URL == "" {
		return ErrInvalidURL
	}
	if c.Price < 0 {
		return ErrInvalidPrice
	}
	if c.CreatorID == 0 {
		return ErrInvalidCreator
	}
	return nil
}

// Common errors for Content model
var (
	ErrInvalidTitle   = errors.New("title cannot be empty")
	ErrInvalidURL     = errors.New("URL cannot be empty")
	ErrInvalidPrice   = errors.New("price cannot be negative")
	ErrInvalidCreator = errors.New("creator ID is required")
)
