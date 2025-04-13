package services

import (
	"kimiyomi/models"

	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo UserRepository
}

type UserRepository interface {
	CreateUser(user *models.User) error
	FindUserByEmail(email string) (*models.User, error)
	FindUserByID(userID uint) (*models.User, error)
	UpdateUser(user *models.User) error
}

func NewAuthService(repo UserRepository) *AuthService {
	return &AuthService{userRepo: repo}
}

func (s *AuthService) Register(email, password string) (*models.User, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &models.User{
		Email:    email,
		Password: string(hashedPassword),
	}

	if err := s.userRepo.CreateUser(user); err != nil {
		return nil, err
	}

	return user, nil
}

func (s *AuthService) Login(email, password string) (*models.User, error) {
	user, err := s.userRepo.FindUserByEmail(email)
	if err != nil {
		return nil, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return nil, err
	}

	return user, nil
}

func (s *AuthService) ChangePassword(userID uint, oldPassword, newPassword string) error {
	user, err := s.userRepo.FindUserByID(userID)
	if err != nil {
		return err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(oldPassword)); err != nil {
		return err
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	user.Password = string(hashedPassword)
	return s.userRepo.UpdateUser(user)
}
