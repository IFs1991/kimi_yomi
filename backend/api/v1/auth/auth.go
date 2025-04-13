package auth

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"github.com/gin-gonic/gin"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

type AuthHandler struct {
	firebaseAuth *auth.Client
	app          *firebase.App // Firebase App instance
}

// NewAuthHandler creates a new AuthHandler.
func NewAuthHandler(ctx context.Context, credentialsPath string) (*AuthHandler, error) {
	opt := option.WithCredentialsFile(credentialsPath) // Path to your Firebase service account key
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return nil, fmt.Errorf("error initializing app: %v", err)
	}

	client, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("error getting Auth client: %v", err)
	}

	return &AuthHandler{firebaseAuth: client, app: app}, nil
}

func (h *AuthHandler) RegisterRoutes(router *gin.RouterGroup) {
	router.POST("/register", h.Register)
	router.POST("/login", h.Login)
	router.POST("/verify-age", h.VerifyAge)         // Custom Claims
	router.POST("/verify-email", h.VerifyEmail)     // Firebase built-in, plus custom action
	router.POST("/reset-password", h.ResetPassword) // Firebase built-in
	router.GET("/users", h.ListAllUsers)            // Example of listing users (admin only)
	router.DELETE("/user/:uid", h.DeleteUser)
}

// ---  Registration ---

type RegisterRequest struct {
	Email       string `json:"email" binding:"required"`
	Password    string `json:"password" binding:"required"`
	DisplayName string `json:"displayName"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	params := (&auth.UserToCreate{}).
		Email(req.Email).
		Password(req.Password).
		EmailVerified(false). // Important: Start unverified.
		DisplayName(req.DisplayName)

	user, err := h.firebaseAuth.CreateUser(c, params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("error creating user: %v", err)})
		return
	}

	// Send verification email.  This is crucial for security.
	if err := h.sendVerificationEmail(c, user.UID, req.Email); err != nil {
		//  Delete the user if email sending fails.
		h.firebaseAuth.DeleteUser(context.Background(), user.UID)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send verification email. User registration rolled back."})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "User registered successfully.  Check your email for verification.", "uid": user.UID})
}

// --- Login ---
type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Firebase SDK doesn't have a direct "login" function with email/password.
	// Instead, you verify an ID token generated on the *client-side* after
	// the user signs in using the Firebase client SDK.
	// This endpoint simulates that process for demonstration, but *in a real app*,
	// you MUST generate the ID token on the client.

	// 1.  ***(SIMULATED)*** Get the user.
	user, err := h.firebaseAuth.GetUserByEmail(c, req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// 2. ***(SIMULATED)*** Check password.  This is *NOT* secure and is for
	//    DEMONSTRATION ONLY. In your actual application, the client-side SDK
	//    handles password validation.  We're doing it here to show the flow.
	if !h.isPasswordValid(user, req.Password, c) { // IMPORTANT:  This needs client SDK.
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// 3. Check email verification
	if !user.EmailVerified {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Email not verified"})
		return
	}

	// 4. ***(SIMULATED)*** Create a custom token.  In a real app, you'd verify
	//    the ID token from the client SDK.
	customToken, err := h.firebaseAuth.CustomToken(c, user.UID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create custom token"})
		return
	}

	// In a *real* application, you would verify the ID token from the client
	// like this:  (This part goes in your middleware, usually)
	// idToken := c.GetHeader("Authorization") // Get from "Authorization: Bearer <token>"
	// idToken = strings.Replace(idToken, "Bearer ", "", 1)
	// token, err := h.firebaseAuth.VerifyIDToken(c, idToken)
	// ... handle errors, check token.UID, etc.

	c.JSON(http.StatusOK, gin.H{"token": customToken, "uid": user.UID}) // Return the *custom* token.
}

// isPasswordValid (SIMULATED - FOR DEMO ONLY).  This is NOT how you handle passwords.
// It's here to illustrate the login flow. The Firebase *client-side* SDK handles this.
func (h *AuthHandler) isPasswordValid(user *auth.UserRecord, password string, c *gin.Context) bool {
	// *** VERY IMPORTANT ***
	// This method is a placeholder for demonstration purposes. In a real application,
	// you *MUST* use the Firebase CLIENT SDK to handle password verification.  This
	// server-side check is insecure and should *NEVER* be used in production.
	// This example simulates what would happen on the client, but you should *never*
	// expose password checking logic on your server.

	// In a REAL app, use the client SDK to sign in:
	// firebase.auth().signInWithEmailAndPassword(email, password)
	//   .then((userCredential) => { ... })
	//   .catch((error) => { ... });

	// This is just a placeholder to make the demo work.
	return true
}

// --- Verify Age (Custom Claims) ---

type VerifyAgeRequest struct {
	Age int `json:"age" binding:"required"`
}

func (h *AuthHandler) VerifyAge(c *gin.Context) {
	// Get the user ID from the JWT (you'd normally do this in middleware)
	uid := h.getUIDFromContext(c) // Get UID from the request context (set by middleware)
	if uid == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req VerifyAgeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Age < 18 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Age must be 18 or older"})
		return
	}

	// Set custom claims.
	claims := map[string]interface{}{
		"ageVerified": true,
		"age":         req.Age,
	}
	if err := h.firebaseAuth.SetCustomUserClaims(c, uid, claims); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set custom claims"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Age verified successfully"})
}

// --- Verify Email ---

func (h *AuthHandler) VerifyEmail(c *gin.Context) {
	//  This endpoint handles the action *after* the user clicks the link in the email.

	oobCode := c.Query("oobCode") // Get the oobCode from the query parameter
	mode := c.Query("mode")       // Get the mode from the query parameter (verifyEmail, resetPassword)

	if oobCode == "" || mode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing oobCode or mode"})
		return
	}

	// Handle email verification.
	if mode == "verifyEmail" {
		// _, err := h.firebaseAuth.VerifyEmail(c, oobCode); // SDK v4ではこのメソッドは提供されない
		// if err != nil {
		// 	c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Email verification failed: %v", err)})
		// 	return
		// }
		// TODO: Implement email verification using Action Code Handler on client-side
		c.JSON(http.StatusOK, gin.H{"message": "Email verification endpoint reached (implement client-side logic)"})
		return
	}

	// Future extension: Handle password reset here too, if needed.
	if mode == "resetPassword" {
		//newPassword := c.PostForm("newPassword")

		// _, err := h.firebaseAuth.VerifyPasswordResetCode(context.Background(), oobCode) // SDK v4ではこのメソッドは提供されない
		// if err != nil {
		// 	log.Printf("error verifying password reset code: %v\n", err)
		// 	// Handle error.
		// }
		// TODO: Implement password reset confirmation using Action Code Handler on client-side
		c.JSON(http.StatusOK, gin.H{"message": "Password reset verification endpoint reached (implement client-side logic)"})
		return
	}

	c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mode"}) // Unknown mode
}

// --- Reset Password ---
type ResetPasswordRequest struct {
	Email string `json:"email" binding:"required"`
}

func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Generate and send the password reset email.
	if err := h.sendPasswordResetEmail(c, req.Email); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password reset email sent"})
}

// sendPasswordResetEmail sends a password reset email to the user.
func (h *AuthHandler) sendPasswordResetEmail(ctx context.Context, email string) error {
	//  Generate the password reset link.
	link, err := h.firebaseAuth.PasswordResetLink(ctx, email)
	if err != nil {
		return fmt.Errorf("failed to generate password reset link: %v", err)
	}

	// In a real application, you'd use an email sending service (e.g., SendGrid, AWS SES)
	// to send the email.  Here, we just print the link.
	log.Printf("Password reset link: %s", link) // Log the link (for testing)
	fmt.Printf("Password reset link: %s\n", link)

	// TODO: Replace this with actual email sending logic.
	return nil
}

// --- Send Verification Email  ---
func (h *AuthHandler) sendVerificationEmail(ctx context.Context, uid, email string) error {
	// Generate the email verification link.

	//   actionCodeSettings := &auth.ActionCodeSettings{
	// 	  URL: "http://localhost:8080/auth/verify-email", // Set to your handler's URL
	//   }

	link, err := h.firebaseAuth.EmailVerificationLink(ctx, email)

	if err != nil {
		return fmt.Errorf("failed to generate email verification link: %v", err)
	}

	// In a real application, send the email using a service like SendGrid, Mailgun, etc.
	log.Printf("Verification link for %s: %s", email, link)
	fmt.Printf("Verification link for %s: %s\n", email, link) // Print to console (replace with email sending)
	return nil
}

// --- Helper Functions ---
// getUIDFromContext retrieves the UID from the Gin context.
// This assumes you have middleware that verifies the Firebase ID token
// and sets the UID in the context.
func (h *AuthHandler) getUIDFromContext(c *gin.Context) string {
	uid, exists := c.Get("uid") // Get UID set by authentication middleware
	if !exists {
		return ""
	}
	return uid.(string)
}

// --- Admin Functions (Requires Admin Privileges) ---

// ListAllUsers lists all users (for admin purposes).
func (h *AuthHandler) ListAllUsers(c *gin.Context) {
	// Check if the user has admin privileges (using custom claims, for example).
	// You would normally do this in middleware.  This is just an example.
	if !h.isAdmin(c) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden"})
		return
	}

	iter := h.firebaseAuth.Users(c, "") // Empty string for default project
	for {
		user, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("error listing users: %v", err)})
			return
		}
		log.Printf("user: %+v\n", user) // Log user info (for demonstration)
	}
	c.JSON(http.StatusOK, gin.H{"message": "Listed all users successfully. See server logs for details."})
}

// DeleteUser deletes a user by UID (requires admin).
func (h *AuthHandler) DeleteUser(c *gin.Context) {
	// Check for admin privileges (typically in middleware).
	if !h.isAdmin(c) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden"})
		return
	}

	uid := c.Param("uid")
	if uid == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing UID"})
		return
	}

	if err := h.firebaseAuth.DeleteUser(c, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("error deleting user: %v", err)})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("User %s deleted successfully", uid)})
}

// isAdmin checks if the user has admin privileges (example using custom claims).
func (h *AuthHandler) isAdmin(c *gin.Context) bool {
	//  In a real application, you'd verify the ID token in middleware and
	//  set the user's claims in the context.  This is a simplified example.
	uid := h.getUIDFromContext(c)
	if uid == "" {
		return false
	}

	user, err := h.firebaseAuth.GetUser(c, uid)
	if err != nil {
		return false
	}

	// Check for an "admin" custom claim.
	if adminClaim, ok := user.CustomClaims["admin"]; ok {
		if isAdmin, ok := adminClaim.(bool); ok && isAdmin {
			return true
		}
	}
	return false
}

// ---  Middleware (Example) ---

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

		// Optional:  Check for email verification
		//if !token.Claims["email_verified"].(bool) {
		//	c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Email not verified"})
		//	return
		//}

		c.Next()
	}
}

// --- Example Usage in main.go ---
/*
func main() {
    ctx := context.Background()
    authHandler, err := auth.NewAuthHandler(ctx, "path/to/your/serviceAccountKey.json") // Replace with your path
    if err != nil {
        log.Fatalf("Failed to initialize AuthHandler: %v", err)
    }

    router := gin.Default()

		// Apply middleware to protected routes.
    authGroup := router.Group("/auth")
		authGroup.Use(auth.FirebaseAuthMiddleware(authHandler.firebaseAuth)) // Protect ALL /auth routes
		authHandler.RegisterRoutes(authGroup)

		//OR
		//protectedGroup := router.Group("/protected")
    //protectedGroup.Use(auth.FirebaseAuthMiddleware(authHandler.firebaseAuth)) // Protect ALL /auth routes
		//authHandler.RegisterRoutes(protectedGroup)

    // Example of a protected route (requires authentication)
    router.GET("/protected", auth.FirebaseAuthMiddleware(authHandler.firebaseAuth), func(c *gin.Context) {
        uid := c.GetString("uid") // Retrieve UID set by middleware.
        c.JSON(http.StatusOK, gin.H{"message": "This is a protected resource", "uid": uid})
    })


    // Add other routes...

    if err := router.Run(":8080"); err != nil {
        log.Fatal(err)
    }
}

*/
