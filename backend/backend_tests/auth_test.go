package auth_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	authHandler "src/backend/api/v1/auth" // Import your auth package
	"testing"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require" // Use require for fatal assertions
)

// MockFirebaseAuth is a mock implementation of the Firebase Auth client.
type MockFirebaseAuth struct {
	Users          map[string]*auth.UserRecord
	CreatedUsers   []*auth.UserToCreate
	CustomTokens   map[string]string // uid -> token
	DeletedUsers   []string
	EmailActions   []map[string]interface{}
    PasswordResetLinks map[string]string
}

func NewMockFirebaseAuth() *MockFirebaseAuth {
	return &MockFirebaseAuth{
		Users:        make(map[string]*auth.UserRecord),
		CreatedUsers: make([]*auth.UserToCreate, 0),
		CustomTokens: make(map[string]string),
		DeletedUsers: make([]string, 0),
		EmailActions: make([]map[string]interface{}, 0),
        PasswordResetLinks: make(map[string]string),
	}
}

func (m *MockFirebaseAuth) CreateUser(ctx context.Context, params *auth.UserToCreate) (*auth.UserRecord, error) {
	if _, exists := m.Users[params.Email]; exists {
		return nil, fmt.Errorf("email already exists")
	}
	uid := fmt.Sprintf("uid-%s", params.Email) // Simple UID generation for testing
	userRecord := &auth.UserRecord{
		UserInfo: &auth.UserInfo{
			UID:         uid,
			Email:       params.Email,
			DisplayName: params.DisplayName,
		},
		EmailVerified: params.EmailVerified,
		// You can add more fields as needed for your tests
	}
	m.Users[params.Email] = userRecord
	m.CreatedUsers = append(m.CreatedUsers, params) // Store for later verification
	return userRecord, nil
}

func (m *MockFirebaseAuth) GetUserByEmail(ctx context.Context, email string) (*auth.UserRecord, error) {
	user, ok := m.Users[email]
	if !ok {
		return nil, fmt.Errorf("user not found")
	}
	return user, nil
}

func (m *MockFirebaseAuth) CustomToken(ctx context.Context, uid string) (string, error) {
	token := fmt.Sprintf("custom-token-%s", uid) // Simple token generation
	m.CustomTokens[uid] = token
	return token, nil
}

func (m *MockFirebaseAuth) SetCustomUserClaims(ctx context.Context, uid string, claims map[string]interface{}) error {
    user, ok := m.findUserByUID(uid)
    if !ok {
        return fmt.Errorf("user not found")
    }

    if user.CustomClaims == nil {
        user.CustomClaims = make(map[string]interface{})
    }
    for k, v := range claims {
        user.CustomClaims[k] = v
    }
    return nil
}

func (m *MockFirebaseAuth) VerifyEmail(ctx context.Context, code string) (map[string]interface{}, error) {
	m.EmailActions = append(m.EmailActions, map[string]interface{}{"action": "VerifyEmail", "code": code})

	// Simulate verification
	for _, user := range m.Users {
		if !user.EmailVerified {
			user.EmailVerified = true
			return map[string]interface{}{}, nil // Return empty map on success

		}
	}
	return nil, fmt.Errorf("No user to verify") //Should not happen in test
}

func (m *MockFirebaseAuth) DeleteUser(ctx context.Context, uid string) error {
    if _, ok := m.findUserByUID(uid); !ok {
        return fmt.Errorf("user not found")
    }
    m.DeletedUsers = append(m.DeletedUsers, uid)

	var userKey string
	for email, userRecord := range m.Users {
		if userRecord.UID == uid {
			userKey = email
			break
		}
	}

	if userKey != "" {
		delete(m.Users, userKey) // Remove the user from the map
	}

    return nil
}

func (m *MockFirebaseAuth) findUserByUID(uid string) (*auth.UserRecord, bool) {
    for _, user := range m.Users {
        if user.UID == uid {
            return user, true
        }
    }
    return nil, false
}

func (m *MockFirebaseAuth) EmailVerificationLink(ctx context.Context, email string)(string, error){
	m.EmailActions = append(m.EmailActions, map[string]interface{}{"action": "EmailVerificationLink", "email":email})
	return fmt.Sprintf("verification-link-for-%s", email), nil // Mock link
}

func (m *MockFirebaseAuth) PasswordResetLink(ctx context.Context, email string) (string, error) {
    if _, exists := m.Users[email]; !exists {
        return "", fmt.Errorf("user not found")
    }
	link := fmt.Sprintf("password-reset-link-for-%s", email)
    m.PasswordResetLinks[email] = link  // Store the link
    return link, nil
}

func (m *MockFirebaseAuth) VerifyPasswordResetCode(ctx context.Context, code string) (string, error){
	//Add to EmailActions for Test
	m.EmailActions = append(m.EmailActions, map[string]interface{}{"action": "VerifyPasswordResetCode", "code": code})
	return "test@example.com", nil //OK
}

func setupRouter(mockAuth *MockFirebaseAuth) *gin.Engine {
	router := gin.Default()
	// Create a real AuthHandler, but pass in the mock client.
	auth := &authHandler.AuthHandler{
		FirebaseAuth: mockAuth,
	}

	authGroup := router.Group("/api/v1/auth")
	auth.RegisterRoutes(authGroup)
	return router
}

func TestAuthAPI(t *testing.T) {
	gin.SetMode(gin.TestMode) // Set Gin to test mode
	mockAuth := NewMockFirebaseAuth()
	router := setupRouter(mockAuth) // Pass the mock client

	t.Run("Test User Registration - Success", func(t *testing.T) {
		user := authHandler.RegisterRequest{
			Email:       "test@example.com",
			Password:    "password123",
			DisplayName: "Test User",
		}

		jsonValue, _ := json.Marshal(user)
		req, _ := http.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		assert.Contains(t, w.Body.String(), "User registered successfully")
		assert.Contains(t, w.Body.String(), "uid") // Check for UID in response
		require.Len(t, mockAuth.CreatedUsers, 1, "One user should be created")
		assert.Equal(t, "test@example.com", mockAuth.CreatedUsers[0].Email)
		assert.False(t, mockAuth.CreatedUsers[0].EmailVerified) // Should start unverified

		require.Len(t, mockAuth.EmailActions, 1)
		assert.Equal(t, "EmailVerificationLink", mockAuth.EmailActions[0]["action"])
		assert.Equal(t, "test@example.com", mockAuth.EmailActions[0]["email"])
	})

	t.Run("Test User Registration - Duplicate Email", func(t *testing.T) {
		// Preregister user
		_, _ = mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "duplicate@example.com"})

		user := authHandler.RegisterRequest{
			Email:    "duplicate@example.com",
			Password: "password123",
		}

		jsonValue, _ := json.Marshal(user)
		req, _ := http.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		assert.Contains(t, w.Body.String(), "email already exists") // Expect specific error
	})

	t.Run("Test User Registration - Bad Request", func(t *testing.T) {
		// Missing email
		user := authHandler.RegisterRequest{
			Password: "password123",
		}

		jsonValue, _ := json.Marshal(user)
		req, _ := http.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "required") // Check for validation error
	})

	t.Run("Test User Login - Success", func(t *testing.T) {
		// Preregister a verified user
		createdUser, err := mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "login@example.com", Password: "password123", EmailVerified: true})
		require.NoError(t, err)

		credentials := authHandler.LoginRequest{
			Email:    "login@example.com",
			Password: "password123",
		}

		jsonValue, _ := json.Marshal(credentials)
		req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)

		var response map[string]string
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.NotEmpty(t, response["token"])
		assert.Equal(t, createdUser.UID, response["uid"])
		assert.Equal(t, response["token"], mockAuth.CustomTokens[createdUser.UID])

	})

	t.Run("Test User Login - User Not Found", func(t *testing.T) {
		credentials := authHandler.LoginRequest{
			Email:    "notfound@example.com",
			Password: "password123",
		}

		jsonValue, _ := json.Marshal(credentials)
		req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		assert.Contains(t, w.Body.String(), "Invalid credentials")
	})

	t.Run("Test User Login - Email Not Verified", func(t *testing.T) {
		// Preregister an *unverified* user
		_, _ = mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "unverified@example.com", Password: "password123", EmailVerified: false})


		credentials := authHandler.LoginRequest{
			Email:    "unverified@example.com",
			Password: "password123",
		}

		jsonValue, _ := json.Marshal(credentials)
		req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code) // Correct status code
		assert.Contains(t, w.Body.String(), "Email not verified")
	})

	t.Run("Test Password Reset - Success", func(t *testing.T) {
		// Preregister user
		_, _ = mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "reset@example.com"})

		resetRequest := authHandler.ResetPasswordRequest{
			Email: "reset@example.com",
		}
		jsonValue, _ := json.Marshal(resetRequest)
		req, _ := http.NewRequest("POST", "/api/v1/auth/reset-password", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "Password reset email sent")

		// Check if PasswordResetLink was called
        require.Len(t, mockAuth.PasswordResetLinks, 1)
        _, exists := mockAuth.PasswordResetLinks["reset@example.com"]
        assert.True(t, exists, "Password reset link should be generated for the user")

	})

	t.Run("Test Verify Email - Success", func(t *testing.T){
		// Arrange
		_, _ = mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "verifyemail@example.com", EmailVerified: false}) // Create unverified User
		// Create a verification request with a mock oobCode
		req, _ := http.NewRequest("POST", "/api/v1/auth/verify-email?oobCode=test_oob_code&mode=verifyEmail", nil)
		w := httptest.NewRecorder()

		// Act
		router.ServeHTTP(w, req)

		// Assert
		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "Email verified successfully")
		require.Len(t, mockAuth.EmailActions, 1)
		assert.Equal(t, "VerifyEmail", mockAuth.EmailActions[0]["action"])
		assert.Equal(t, "test_oob_code", mockAuth.EmailActions[0]["code"])

	})

	t.Run("Test Verify Email - Missing Parameters", func(t *testing.T){
		//Arrange
		_, _ = mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "verifyemail@example.com"}) // Create User

		// Create a verification request with a mock oobCode
		req, _ := http.NewRequest("POST", "/api/v1/auth/verify-email", nil)
		w := httptest.NewRecorder()

		//Act
		router.ServeHTTP(w, req)

		//Assert
		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "Missing oobCode or mode")

	})

	t.Run("Test Verify Email - Invalid mode", func(t *testing.T){
		//Arrange
		_, _ = mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "verifyemail@example.com"}) // Create User

		// Create a verification request with a mock oobCode
		req, _ := http.NewRequest("POST", "/api/v1/auth/verify-email?oobCode=test_oob_code&mode=invalid", nil)
		w := httptest.NewRecorder()

		//Act
		router.ServeHTTP(w, req)

		//Assert
		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "Invalid mode")
	})

	t.Run("Test Verify Age - Success", func(t *testing.T){

		// Arrange: Create a user and simulate authentication (set UID in context)
		user, err := mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "ageverify@example.com", EmailVerified: true})
		require.NoError(t, err)

		verifyAgeRequest := authHandler.VerifyAgeRequest{
			Age: 20,
		}

		jsonValue, _ := json.Marshal(verifyAgeRequest)
		req, _ := http.NewRequest("POST", "/api/v1/auth/verify-age", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")

		// Set the UID in the context, as the middleware would do
		ctx := context.WithValue(req.Context(), "uid", user.UID)
		req = req.WithContext(ctx)


		w := httptest.NewRecorder()

		// Act
		router.ServeHTTP(w, req)

		//Assert
		assert.Equal(t, http.StatusOK, w.Code)
		assert.Contains(t, w.Body.String(), "Age verified successfully")

		// Verify that custom claims were set
		updatedUser, found := mockAuth.findUserByUID(user.UID)
		require.True(t, found)
		require.NotNil(t, updatedUser.CustomClaims)
		assert.Equal(t, true, updatedUser.CustomClaims["ageVerified"])
		assert.Equal(t, float64(20), updatedUser.CustomClaims["age"]) // Note: Claims are float64

	})

	t.Run("Test Verify Age - Unauthorized", func(t *testing.T) {
        verifyAgeRequest := authHandler.VerifyAgeRequest{
            Age: 20,
        }
        jsonValue, _ := json.Marshal(verifyAgeRequest)
        req, _ := http.NewRequest("POST", "/api/v1/auth/verify-age", bytes.NewBuffer(jsonValue))
        req.Header.Set("Content-Type", "application/json")

        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)

        assert.Equal(t, http.StatusUnauthorized, w.Code) // Expect 401
    })

	t.Run("Test Verify Age - Bad Request", func(t *testing.T) {
		user, err := mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "ageverify@example.com", EmailVerified: true})
		require.NoError(t, err)
		verifyAgeRequest := authHandler.VerifyAgeRequest{
            // Age: 20,  //Missing Age
        }
		jsonValue, _ := json.Marshal(verifyAgeRequest)
		req, _ := http.NewRequest("POST", "/api/v1/auth/verify-age", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")
		ctx := context.WithValue(req.Context(), "uid", user.UID)
		req = req.WithContext(ctx)

        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)

        assert.Equal(t, http.StatusBadRequest, w.Code) // Expect 401
		assert.Contains(t, w.Body.String(), "required") // Check for validation error

    })

	t.Run("Test Verify Age - Underage", func(t *testing.T){
		user, err := mockAuth.CreateUser(context.Background(), &auth.UserToCreate{Email: "ageverify@example.com", EmailVerified: true})
		require.NoError(t, err)
		verifyAgeRequest := authHandler.VerifyAgeRequest{
            Age: 17,
        }
		jsonValue, _ := json.Marshal(verifyAgeRequest)
		req, _ := http.NewRequest("POST", "/api/v1/auth/verify-age", bytes.NewBuffer(jsonValue))
		req.Header.Set("Content-Type", "application/json")
		ctx := context.WithValue(req.Context(), "uid", user.UID)
		req = req.WithContext(ctx)

        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code) // Expect 400
		assert.Contains(t, w.Body.String(), "Age must be 18 or older")

	})
}