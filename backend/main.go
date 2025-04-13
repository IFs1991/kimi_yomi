package main

import (
	"context"
	"log"
	"net/http"
	"os"

	authHandler "kimiyomi/api/v1/auth" // モジュール名からのパス
	"kimiyomi/api/v1/compatibility"    // モジュール名からのパス
	"kimiyomi/api/v1/content"          // モジュール名からのパス
	"kimiyomi/api/v1/diagnosis"        // モジュール名からのパス
	"kimiyomi/api/v1/payment"          // モジュール名からのパス
	"kimiyomi/api/v1/subscription"     // モジュール名からのパス

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize Firebase and AuthHandler
	ctx := context.Background()
	credentialsPath := os.Getenv("FIREBASE_CREDENTIALS_PATH") // Get path from environment variable
	if credentialsPath == "" {
		credentialsPath = "path/to/your/serviceAccountKey.json" // Fallback (replace with your default)
		log.Println("WARNING: FIREBASE_CREDENTIALS_PATH not set, using default path.  This is insecure for production.")
	}

	auth, err := authHandler.NewAuthHandler(ctx, credentialsPath)
	if err != nil {
		log.Fatalf("Failed to initialize Firebase Auth: %v", err)
	}

	// Gin framework initialization
	router := gin.Default()

	// Middleware setup
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	// router.Use(AuthMiddleware()) // Removed:  Now handled per-group
	router.Use(ErrorHandlingMiddleware())

	// API routing setup
	api := router.Group("/api/v1")
	{
		authGroup := api.Group("/auth")
		{
			// No middleware here:  /register and /login are *unprotected*
			auth.RegisterRoutes(authGroup) // Use the RegisterRoutes method
		}

		// --- Protected Routes ---
		// All routes *below* this will use the FirebaseAuthMiddleware.
		protected := api.Group("/") // Group under a common root
		protected.Use(authHandler.FirebaseAuthMiddleware(auth.firebaseAuth))
		{
			diagnosisGroup := protected.Group("/diagnosis")
			{
				diagnosisGroup.GET("/questions", diagnosis.GetQuestions)
				diagnosisGroup.POST("/submit", diagnosis.SubmitAnswers)
				diagnosisGroup.GET("/result", diagnosis.GetResult)
			}

			compatibilityGroup := protected.Group("/compatibility")
			{
				compatibilityGroup.GET("/daily", compatibility.GetDailyCompatibility)
				compatibilityGroup.POST("/calculate", compatibility.CalculateCompatibility)
			}

			paymentGroup := protected.Group("/payments")
			{
				paymentGroup.POST("", payment.CreatePayment)
				paymentGroup.GET("/:id", payment.GetPayment)
				paymentGroup.POST("/:id/refund", payment.ProcessRefund)
				paymentGroup.GET("", payment.GetUserPayments)
			}

			contentGroup := protected.Group("/contents")
			{
				contentGroup.POST("", content.CreateContent)
				contentGroup.GET("/:id", content.GetContent)
				contentGroup.PUT("/:id", content.UpdateContent)
				contentGroup.DELETE("/:id", content.DeleteContent)
				contentGroup.GET("", content.ListContents)
				contentGroup.GET("/type/:type", content.ListContentsByType)
			}

			subscriptionGroup := protected.Group("/subscriptions")
			{
				subscriptionGroup.POST("", subscription.CreateSubscription)
				subscriptionGroup.GET("/:id", subscription.GetSubscription)
				subscriptionGroup.POST("/:id/cancel", subscription.CancelSubscription)
				subscriptionGroup.POST("/:id/renew", subscription.RenewSubscription)
				subscriptionGroup.GET("", subscription.GetUserSubscriptions)
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
}

// AuthMiddleware (REMOVED - now using FirebaseAuthMiddleware from auth.go)

func ErrorHandlingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			//  Aggregate errors and return a single JSON response
			var errorMessages []string
			for _, err := range c.Errors {
				errorMessages = append(errorMessages, err.Error())
			}
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"errors": errorMessages})

		}
	}
}
