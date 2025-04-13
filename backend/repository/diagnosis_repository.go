package repository

import (
	"context"

	"kimiyomi/models"

	"gorm.io/gorm"
)

// DiagnosisRepository defines operations for diagnosis data
type DiagnosisRepository interface {
	CreateDiagnosisSession(ctx context.Context, session *models.DiagnosisSession) error
	GetDiagnosisSessionByID(ctx context.Context, id uint) (*models.DiagnosisSession, error)
	GetDiagnosisSessionsByUserID(ctx context.Context, userID uint) ([]models.DiagnosisSession, error)
	UpdateDiagnosisSession(ctx context.Context, session *models.DiagnosisSession) error
	SaveAnswer(ctx context.Context, answer *models.Answer) error
	// Add other necessary methods like GetQuestions, SaveAnswers etc.
}

// --- Implementation ---

type diagnosisRepository struct {
	db *gorm.DB
}

// NewDiagnosisRepository creates a new instance of DiagnosisRepository
func NewDiagnosisRepository(db *gorm.DB) DiagnosisRepository {
	return &diagnosisRepository{db: db}
}

func (r *diagnosisRepository) CreateDiagnosisSession(ctx context.Context, session *models.DiagnosisSession) error {
	return r.db.WithContext(ctx).Create(session).Error
}

func (r *diagnosisRepository) GetDiagnosisSessionByID(ctx context.Context, id uint) (*models.DiagnosisSession, error) {
	var session models.DiagnosisSession
	if err := r.db.WithContext(ctx).Preload("Answers").First(&session, id).Error; err != nil { // Preload Answers
		return nil, err
	}
	return &session, nil
}

func (r *diagnosisRepository) GetDiagnosisSessionsByUserID(ctx context.Context, userID uint) ([]models.DiagnosisSession, error) {
	var sessions []models.DiagnosisSession
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Order("created_at DESC").Find(&sessions).Error; err != nil {
		return nil, err
	}
	return sessions, nil
}

func (r *diagnosisRepository) UpdateDiagnosisSession(ctx context.Context, session *models.DiagnosisSession) error {
	// Use Save to handle associations correctly if needed, or Update for specific fields
	return r.db.WithContext(ctx).Save(session).Error
}

func (r *diagnosisRepository) SaveAnswer(ctx context.Context, answer *models.Answer) error {
	return r.db.WithContext(ctx).Create(answer).Error
}

// TODO: Implement other methods like GetQuestions if needed by the service
