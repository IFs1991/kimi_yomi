package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	authAPI "kimiyomi/api/v1/auth"
	compAPI "kimiyomi/api/v1/compatibility"
	contentAPI "kimiyomi/api/v1/content"
	diagAPI "kimiyomi/api/v1/diagnosis"
	paymentAPI "kimiyomi/api/v1/payment"
	subAPI "kimiyomi/api/v1/subscription"

	"kimiyomi/repository"
	"kimiyomi/services"

	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres" // Example DB driver
	"gorm.io/gorm"
	// Add other necessary imports like redis client
)

// --- Dependency Setup ---

// App holds application dependencies
// Define necessary dependencies
// RedisClient *redis.Client // Example

// Add other services like CacheService, AIService

// Keep existing auth handler for now
// Add other API handlers
// Restore
// Restore
// Restore
// Restore

// InitializeApp sets up the application dependencies
func InitializeApp(ctx context.Context) (*App, error) {
app := &App{}

// 1. Initialize Database Connection (Example using PostgreSQL)
dsn := os.Getenv("DATABASE_URL")
if dsn == "" {
dsn = "host=localhost user=postgres password=password dbname=kimiyomi port=5432 sslmode=disable TimeZone=Asia/Tokyo"
log.Println("WARNING: DATABASE_URL not set, using default DSN.")
}
db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
if err != nil {
return nil, fmt.Errorf("failed to connect database: %w", err)
}
app.DB = db

// 2. Initialize Repositories
userRepo := repository.NewUserRepository(db) // Assuming NewUserRepository exists
compRepo := repository.NewCompatibilityRepository(db) // Assuming NewCompatibilityRepository exists
contentRepo := repository.NewContentRepository(db)
diagRepo := repository.NewDiagnosisRepository(db) // Assuming NewDiagnosisRepository exists
paymentRepo := repository.NewPaymentRepository(db)
subRepo := repository.NewSubscriptionRepository(db) // Assuming NewSubscriptionRepository exists
// Initialize other repositories (Question, Answer etc.) if needed

// 3. Initialize Services
app.AuthService = services.NewAuthService(userRepo)
app.CompatibilityService = services.NewCompatibilityService(compRepo, userRepo)
app.ContentService = services.NewContentService(contentRepo)
app.DiagnosisService = services.NewDiagnosisService(diagRepo /*, questionRepo, userRepo */) // Pass required repos
app.PaymentService = services.NewPaymentService(paymentRepo, userRepo)
app.SubscriptionService = services.NewSubscriptionService(subRepo)
// Initialize other services

// 4. Initialize API Handlers
credentialsPath := os.Getenv("FIREBASE_CREDENTIALS_PATH")
if credentialsPath == "" {
credentialsPath = "path/to/your/serviceAccountKey.json" // Fallback
log.Println("WARNING: FIREBASE_CREDENTIALS_PATH not set.")
}
// Keep existing AuthHandler initialization for Firebase setup
app.AuthAPI, err = authAPI.NewAuthHandler(ctx, credentialsPath, userRepo)
if err != nil {
return nil, fmt.Errorf("failed to initialize auth handler: %w", err)
}

// Initialize other API handlers (assuming they exist and accept services)
app.CompAPI = compAPI.NewCompatibilityAPI(app.CompatibilityService)
app.ContentAPI = contentAPI.NewContentAPI(app.ContentService)
app.DiagAPI = diagAPI.NewDiagnosisAPI(app.DiagnosisService)
app.PaymentAPI = paymentAPI.NewPaymentAPI(app.PaymentService)
app.SubscriptionAPI = subAPI.NewSubscriptionAPI(app.SubscriptionService)

return app, nil
}

// --- Main Function ---

func main() {
ctx := context.Background()

// Initialize dependencies
app, err := InitializeApp(ctx)
if err != nil {
log.Fatalf("Failed to initialize application: %v", err)
}

// Gin framework initialization
router := gin.Default()

// Middleware setup
router.Use(gin.Logger())
router.Use(gin.Recovery())
router.Use(ErrorHandlingMiddleware())

// API routing setup using initialized handlers
api := router.Group("/api/v1")
{
authGroup := api.Group("/auth")
{
// Use RegisterRoutes from the initialized AuthAPI
app.AuthAPI.RegisterRoutes(authGroup)
}

// --- Protected Routes ---
protected := api.Group("/")
// Use middleware from the initialized AuthAPI
protected.Use(FirebaseAuthMiddleware(app.AuthAPI.FirebaseAuthClient())) // Use getter method
{
diagnosisGroup := protected.Group("/diagnosis")
{
// Use methods from initialized DiagAPI
diagnosisGroup.GET("/questions", app.DiagAPI.GetQuestions) // Restore
diagnosisGroup.POST("/submit", app.DiagAPI.SubmitAnswers) // Restore
diagnosisGroup.GET("/result", app.DiagAPI.GetResult) // Restore
}

compatibilityGroup := protected.Group("/compatibility")
{
// Use methods from initialized CompAPI
compatibilityGroup.GET("/daily", app.CompAPI.GetDailyCompatibility) // Restore
compatibilityGroup.POST("/calculate", app.CompAPI.CalculateCompatibility) // Restore
}

paymentGroup := protected.Group("/payments")
{
// Use methods from initialized PaymentAPI
paymentGroup.POST("", app.PaymentAPI.CreatePayment) // Restore
paymentGroup.GET("/:id", app.PaymentAPI.GetPayment) // Restore
paymentGroup.POST("/:id/refund", app.PaymentAPI.ProcessRefund) // Restore
paymentGroup.GET("", app.PaymentAPI.GetUserPayments) // Restore
}

contentGroup := protected.Group("/contents")
{
// Use methods from initialized ContentAPI
contentGroup.POST("", app.ContentAPI.CreateContent) // Restore
contentGroup.GET("/:id", app.ContentAPI.GetContent) // Restore
contentGroup.PUT("/:id", app.ContentAPI.UpdateContent) // Restore
contentGroup.DELETE("/:id", app.ContentAPI.DeleteContent) // Restore
contentGroup.GET("", app.ContentAPI.ListContents) // Restore
contentGroup.GET("/type/:type", app.ContentAPI.ListContentsByType) // Restore
}

subscriptionGroup := protected.Group("/subscriptions")
{
// Use methods from initialized SubscriptionAPI
subscriptionGroup.POST("", app.SubscriptionAPI.CreateSubscription) // Restore
subscriptionGroup.GET("/:id", app.SubscriptionAPI.GetSubscription) // Restore
subscriptionGroup.POST("/:id/cancel", app.SubscriptionAPI.CancelSubscription) // Restore
// subscriptionGroup.POST("/:id/renew", app.SubscriptionAPI.RenewSubscription) // Keep commented - Service method missing
// subscriptionGroup.GET("", app.SubscriptionAPI.GetUserSubscriptions) // Keep commented - Service method missing
}
}
}

// Server startup
port := os.Getenv("PORT")
if port == "" {
port = "8080"
}
if err := router.Run(":" + port); err != nil {
log.Fatalf("Failed to start server: %v", err)
}

// Middleware needs to be accessible or defined here
func FirebaseAuthMiddleware(authClient *auth.Client) gin.HandlerFunc {

	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}

		idToken := strings.Replace(authHeader, "Bearer ", "", 1)

		token, err := authClient.VerifyIDToken(c, idToken)
		if err != nil {
			log.Printf("Error verifying ID token: %v\n", err)
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		// Set UID in context for use by handlers
		c.Set("uid", token.UID)
		c.Next()
	}
}

func ErrorHandlingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			var errorMessages []string
			for _, err := range c.Errors {
				errorMessages = append(errorMessages, err.Error())
			}
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"errors": errorMessages})
		}
	}
}
