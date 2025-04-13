package services

import (
	"errors"
	"kimiyomi/models"
	"time"

	"gorm.io/gorm"
)

type DiagnosisService struct {
	db *gorm.DB
}

func NewDiagnosisService(db *gorm.DB) *DiagnosisService {
	return &DiagnosisService{db: db}
}

// StartDiagnosis 新しい診断セッションを開始
func (s *DiagnosisService) StartDiagnosis(userID uint) (*models.DiagnosisSession, error) {
	session := &models.DiagnosisSession{
		UserID: userID,
	}

	result := s.db.Create(session)
	if result.Error != nil {
		return nil, result.Error
	}

	return session, nil
}

// GetNextQuestion 次の質問を取得
func (s *DiagnosisService) GetNextQuestion(sessionID uint) (*models.Question, error) {
	var session models.DiagnosisSession
	if err := s.db.First(&session, sessionID).Error; err != nil {
		return nil, err
	}

	var question models.Question
	if err := s.db.Where("order_index = ?", session.CurrentIndex+1).First(&question).Error; err != nil {
		return nil, err
	}

	return &question, nil
}

// SubmitAnswer 回答を提出
func (s *DiagnosisService) SubmitAnswer(sessionID uint, questionID uint, score int) error {
	var session models.DiagnosisSession
	if err := s.db.First(&session, sessionID).Error; err != nil {
		return err
	}

	answer := &models.Answer{
		UserID:     session.UserID,
		QuestionID: questionID,
		Score:      score,
	}

	if !answer.ValidateScore() {
		return errors.New("invalid score value")
	}

	tx := s.db.Begin()

	if err := tx.Create(answer).Error; err != nil {
		tx.Rollback()
		return err
	}

	session.CurrentIndex++
	if err := tx.Save(&session).Error; err != nil {
		tx.Rollback()
		return err
	}

	// 全質問が完了した場合、結果を計算
	var totalQuestions int64
	s.db.Model(&models.Question{}).Count(&totalQuestions)

	if session.CurrentIndex >= int(totalQuestions) {
		results, err := s.calculateResults(session.UserID)
		if err != nil {
			tx.Rollback()
			return err
		}

		user := &models.User{}
		if err := tx.First(user, session.UserID).Error; err != nil {
			tx.Rollback()
			return err
		}

		user.Big5Results = *results
		user.Big5Results.UpdatedAt = time.Now()
		user.LastDiagnosis = time.Now()

		if err := tx.Save(user).Error; err != nil {
			tx.Rollback()
			return err
		}

		session.IsComplete = true
		if err := tx.Save(&session).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit().Error
}

// calculateResults Big5スコアの計算
func (s *DiagnosisService) calculateResults(userID uint) (*models.Big5Results, error) {
	var answers []models.Answer
	if err := s.db.Where("user_id = ?", userID).Find(&answers).Error; err != nil {
		return nil, err
	}

	results := &models.Big5Results{}
	counts := make(map[string]int)
	scores := make(map[string]float64)

	for _, answer := range answers {
		var question models.Question
		if err := s.db.First(&question, answer.QuestionID).Error; err != nil {
			return nil, err
		}

		score := float64(answer.Score)
		if question.IsReversed {
			score = 6 - score // 5点スケールの反転
		}

		scores[question.Category] += score
		counts[question.Category]++
	}

	// 各カテゴリーの平均値を計算
	if count := counts["O"]; count > 0 {
		results.Openness = scores["O"] / float64(count)
	}
	if count := counts["C"]; count > 0 {
		results.Conscientiousness = scores["C"] / float64(count)
	}
	if count := counts["E"]; count > 0 {
		results.Extraversion = scores["E"] / float64(count)
	}
	if count := counts["A"]; count > 0 {
		results.Agreeableness = scores["A"] / float64(count)
	}
	if count := counts["N"]; count > 0 {
		results.Neuroticism = scores["N"] / float64(count)
	}

	return results, nil
}
