package services

import (
	"context"
	"errors"
	"kimiyomi/models"
	"kimiyomi/repository"
	"time"
	// "gorm.io/gorm" // Remove gorm import
)

// DiagnosisService defines the interface for diagnosis logic
type DiagnosisService interface {
	StartDiagnosis(ctx context.Context, userID uint) (*models.DiagnosisSession, error)
	GetNextQuestion(ctx context.Context, sessionID uint) (*models.Question, error)
	SubmitAnswer(ctx context.Context, sessionID uint, questionID uint, score int) error
	GetDiagnosisResult(ctx context.Context, userID uint) (*models.Big5Results, error)
}

// diagnosisService implements DiagnosisService
type diagnosisService struct {
	diagRepo repository.DiagnosisRepository // Use repository.DiagnosisRepository
	// Assuming QuestionRepository and UserRepository are needed for full functionality
	// questionRepo repository.QuestionRepository // Placeholder
	// userRepo repository.UserRepository       // Placeholder
}

// NewDiagnosisService creates a new instance of DiagnosisService
// Modify to accept required repositories
func NewDiagnosisService(diagRepo repository.DiagnosisRepository /*, questionRepo repository.QuestionRepository, userRepo repository.UserRepository*/) DiagnosisService {
	return &diagnosisService{
		diagRepo: diagRepo,
		// questionRepo: questionRepo,
		// userRepo: userRepo,
	}
}

// StartDiagnosis begins a new diagnosis session
func (s *diagnosisService) StartDiagnosis(ctx context.Context, userID uint) (*models.DiagnosisSession, error) {
	session := &models.DiagnosisSession{
		UserID: userID,
		// CreatedAt: time.Now(), // Remove timestamp assignment (handled by GORM)
		// UpdatedAt: time.Now(), // Remove timestamp assignment (handled by GORM)
	}

	err := s.diagRepo.CreateDiagnosisSession(ctx, session)
	if err != nil {
		return nil, err
	}
	// The session object should now have the ID assigned by the database
	return session, nil
}

// GetNextQuestion retrieves the next question for the session
func (s *diagnosisService) GetNextQuestion(ctx context.Context, sessionID uint) (*models.Question, error) {
	session, err := s.diagRepo.GetDiagnosisSessionByID(ctx, sessionID)
	if err != nil {
		return nil, err
	}

	if session.IsComplete {
		return nil, errors.New("diagnosis session is already complete")
	}

	// TODO: Replace this with a call to a QuestionRepository
	// question, err := s.questionRepo.GetQuestionByOrderIndex(ctx, session.CurrentIndex+1)
	// if err != nil {
	// 	 return nil, err
	// }
	// return question, nil

	// Temporary placeholder implementation using GetCategoryQuestions (Not ideal)
	questions := models.GetCategoryQuestions("O") // Assuming a single category for now
	if session.CurrentIndex < len(questions) {
		return &questions[session.CurrentIndex], nil
	}
	return nil, errors.New("no more questions available")
}

// SubmitAnswer submits an answer for a question in the session
func (s *diagnosisService) SubmitAnswer(ctx context.Context, sessionID uint, questionID uint, score int) error {
	// Input validation
	if score < 1 || score > 5 {
		return errors.New("invalid score value")
	}

	session, err := s.diagRepo.GetDiagnosisSessionByID(ctx, sessionID)
	if err != nil {
		return err
	}
	if session.IsComplete {
		return errors.New("cannot submit answer to a completed session")
	}

	// TODO: Validate questionID corresponds to session.CurrentIndex+1 using QuestionRepository

	answer := &models.Answer{
		UserID:     session.UserID,
		QuestionID: questionID,
		Score:      score,
		// CreatedAt:  time.Now(), // Remove timestamp assignment (handled by GORM)
		// UpdatedAt:  time.Now(), // Remove timestamp assignment (handled by GORM)
	}

	// TODO: Implement saving the answer using a repository (e.g., AnswerRepository or within DiagnosisRepository)
	err = s.diagRepo.SaveAnswer(ctx, answer) // Placeholder - Uncomment to use 'answer'
	if err != nil {
		return err
	}

	session.CurrentIndex++
	session.UpdatedAt = time.Now()

	// TODO: Get total question count from QuestionRepository
	var totalQuestions int = 5 // Hardcoded placeholder
	if session.CurrentIndex >= totalQuestions {
		session.IsComplete = true
	}

	err = s.diagRepo.UpdateDiagnosisSession(ctx, session)
	if err != nil {
		// TODO: Handle potential transaction rollback if answer saving was separate
		return err
	}

	// If session is now complete, calculate and save results (moved out of transaction)
	if session.IsComplete {
		results, err := s.calculateAndSaveResults(ctx, session.UserID)
		if err != nil {
			// TODO: Consider how to handle failure here. Maybe mark session as incomplete again?
			return err
		}
		// Results saved in calculateAndSaveResults
		_ = results // Use results if needed
	}

	return nil
}

// GetDiagnosisResult retrieves the latest Big5 results for a user
// Renamed from calculateResults to reflect its purpose in the service interface
func (s *diagnosisService) GetDiagnosisResult(ctx context.Context, userID uint) (*models.Big5Results, error) {
	// TODO: Replace this with a call to UserRepository to get the user and their results
	// user, err := s.userRepo.GetByID(ctx, userID)
	// if err != nil {
	// 	 return nil, err
	// }
	// if user.Big5Results == nil { // Check if results exist
	// 	 return nil, errors.New("no diagnosis results found for this user")
	// }
	// return user.Big5Results, nil

	return nil, errors.New("GetDiagnosisResult not fully implemented") // Placeholder
}

// calculateAndSaveResults calculates Big5 scores and saves them to the user model
// This is now an internal helper method
func (s *diagnosisService) calculateAndSaveResults(ctx context.Context, userID uint) (*models.Big5Results, error) {
	// TODO: Fetch answers using repository
	// answers, err := s.diagRepo.GetAnswersByUserID(ctx, userID)
	// if err != nil {
	// 	 return nil, err
	// }
	answers := []models.Answer{} // Placeholder

	results := &models.Big5Results{}
	counts := make(map[string]int)
	scores := make(map[string]float64)

	for _, answer := range answers {
		// TODO: Fetch question details using QuestionRepository
		// question, err := s.questionRepo.GetByID(ctx, answer.QuestionID)
		// if err != nil {
		// 	 return nil, err
		// }
		question := models.Question{Category: "O", IsReversed: false} // Placeholder

		score := float64(answer.Score)
		if question.IsReversed {
			score = 6 - score // 5点スケールの反転
		}

		scores[question.Category] += score
		counts[question.Category]++
	}

	// Calculate averages
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

	// TODO: Fetch user using UserRepository and save results
	// user, err := s.userRepo.GetByID(ctx, userID)
	// if err != nil {
	// 	 return nil, err
	// }
	// user.Big5Results = results
	// user.Big5Results.UpdatedAt = time.Now()
	// user.LastDiagnosis = time.Now()
	// err = s.userRepo.Update(ctx, user)
	// if err != nil {
	// 	 return nil, err
	// }

	return results, nil
}
