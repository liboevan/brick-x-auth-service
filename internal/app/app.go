package app

import (
	"brick-x-auth-service/internal/auth"
	"brick-x-auth-service/internal/config"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

type App struct {
	config     *config.Config
	authManager auth.AuthManager
	router     *mux.Router
}

func NewApp(config *config.Config, authManager auth.AuthManager) *App {
	app := &App{
		config:     config,
		authManager: authManager,
		router:     mux.NewRouter(),
	}
	app.setupRoutes()
	return app
}

func (a *App) setupRoutes() {
	// Health check
	a.router.HandleFunc("/health", a.healthHandler).Methods("GET")
	// Build info
	a.router.HandleFunc("/build-info.json", a.buildInfoHandler).Methods("GET")
	a.router.HandleFunc("/VERSION", a.versionHandler).Methods("GET")

	// Auth API routes
	authRouter := a.router.PathPrefix("/auth").Subrouter()
	authRouter.HandleFunc("/login", a.loginHandler).Methods("POST")
	authRouter.HandleFunc("/exchange", a.exchangeHandler).Methods("POST")
	authRouter.HandleFunc("/validate", a.validateHandler).Methods("POST")
	authRouter.HandleFunc("/me", a.meHandler).Methods("GET")
	authRouter.HandleFunc("/auth-type", a.requirePermission(a.getAuthTypeHandler, "x/layout:read")).Methods("GET")
	authRouter.HandleFunc("/auth-type", a.requirePermission(a.setAuthTypeHandler, "x/layout:write")).Methods("POST")

	// User/Role/Permission API routes
	userRouter := a.router.PathPrefix("/user").Subrouter()
	userRouter.HandleFunc("/users", a.requirePermission(a.getUsersHandler, "user:read")).Methods("GET")
	userRouter.HandleFunc("/users", a.requirePermission(a.createUserHandler, "user:write")).Methods("POST")
	userRouter.HandleFunc("/users/{username}", a.requirePermission(a.updateUserHandler, "user:write")).Methods("PUT")
	userRouter.HandleFunc("/users/{username}", a.requirePermission(a.deleteUserHandler, "user:write")).Methods("DELETE")

	userRouter.HandleFunc("/roles", a.requirePermission(a.getRolesHandler, "role:read")).Methods("GET")
	userRouter.HandleFunc("/roles", a.requirePermission(a.createRoleHandler, "role:write")).Methods("POST")
	userRouter.HandleFunc("/roles/{name}", a.requirePermission(a.updateRoleHandler, "role:write")).Methods("PUT")
	userRouter.HandleFunc("/roles/{name}", a.requirePermission(a.deleteRoleHandler, "role:write")).Methods("DELETE")

	userRouter.HandleFunc("/permissions", a.requirePermission(a.getPermissionsHandler, "permission:read")).Methods("GET")
	userRouter.HandleFunc("/permissions", a.requirePermission(a.setPermissionsHandler, "permission:write")).Methods("POST")
}

func (a *App) healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "healthy",
		"service": "brick-x-auth-service",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

func (a *App) buildInfoHandler(w http.ResponseWriter, r *http.Request) {
	// Read build info from file
	data, err := os.ReadFile("/app/build-info.json")
	if err != nil {
		http.Error(w, "Build info not available", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Write(data)
}

func (a *App) versionHandler(w http.ResponseWriter, r *http.Request) {
	// Read version from file
	data, err := os.ReadFile("/app/VERSION")
	if err != nil {
		http.Error(w, "Version not available", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "text/plain")
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Write(data)
}

func (a *App) loginHandler(w http.ResponseWriter, r *http.Request) {
	var req auth.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	token, err := a.authManager.AuthenticateLocal(req.Username, req.Password)
	if err != nil {
		http.Error(w, "Authentication failed", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(auth.LoginResponse{
		Token: token,
		Type:  "Bearer",
	})
}

func (a *App) exchangeHandler(w http.ResponseWriter, r *http.Request) {
	var req auth.ExchangeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	token, err := a.authManager.ExchangeToken(req.BrickAuthToken)
	if err != nil {
		http.Error(w, "Token exchange failed", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(auth.LoginResponse{
		Token: token,
		Type:  "Bearer",
	})
}

func (a *App) validateHandler(w http.ResponseWriter, r *http.Request) {
	var req auth.Token
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	valid, userInfo, err := a.authManager.ValidateToken(req.Token)
	if err != nil || !valid {
		http.Error(w, "Token validation failed", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(auth.ValidateResponse{
		Valid:   valid,
		UserInfo: userInfo,
	})
}

func (a *App) meHandler(w http.ResponseWriter, r *http.Request) {
	// Extract token from Authorization header
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		http.Error(w, "Authorization header required", http.StatusUnauthorized)
		return
	}

	// Check if it's a Bearer token
	if !strings.HasPrefix(authHeader, "Bearer ") {
		http.Error(w, "Invalid authorization format", http.StatusUnauthorized)
		return
	}

	// Extract token
	token := strings.TrimPrefix(authHeader, "Bearer ")

	// Validate token and get user info
	valid, userInfo, err := a.authManager.ValidateToken(token)
	if err != nil || !valid {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(userInfo)
}

func (a *App) disableLocalLoginHandler(w http.ResponseWriter, r *http.Request) {
	err := a.authManager.DisableLocalLogin()
	if err != nil {
		http.Error(w, "Failed to disable local login", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Local login disabled successfully",
	})
}

// getAuthTypeHandler/setAuthTypeHandler 返回固定值 "local"
func (a *App) getAuthTypeHandler(w http.ResponseWriter, r *http.Request) {
	type resp struct {
		AuthType string `json:"auth_type"`
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp{AuthType: "local"})
}

func (a *App) setAuthTypeHandler(w http.ResponseWriter, r *http.Request) {
	type req struct {
		AuthType string `json:"auth_type"`
	}
	var body req
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if body.AuthType != "local" && body.AuthType != "sso" && body.AuthType != "both" {
		http.Error(w, "Invalid auth_type", http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "Auth type updated (not persisted)", "auth_type": body.AuthType})
}

// requirePermission creates a middleware that requires a specific permission
func (a *App) requirePermission(handler http.HandlerFunc, requiredPermission string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Extract token from Authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Authorization header required", http.StatusUnauthorized)
			return
		}

		// Check if it's a Bearer token
		if !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "Invalid authorization format", http.StatusUnauthorized)
			return
		}

		// Extract token
		token := strings.TrimPrefix(authHeader, "Bearer ")

		// Validate token and get user info
		valid, userInfo, err := a.authManager.ValidateToken(token)
		if err != nil || !valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		// Check if user has required permission
		hasPermission := false
		for _, permission := range userInfo.Permissions {
			if permission == requiredPermission {
				hasPermission = true
				break
			}
		}

		if !hasPermission {
			http.Error(w, "Insufficient permissions", http.StatusForbidden)
			return
		}

		// Call the original handler
		handler(w, r)
	}
}

func (a *App) enableLocalLoginHandler(w http.ResponseWriter, r *http.Request) {
	err := a.authManager.EnableLocalLogin()
	if err != nil {
		http.Error(w, "Failed to enable local login", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Local login enabled successfully",
	})
}

// 用户管理
func (a *App) getUsersHandler(w http.ResponseWriter, r *http.Request) {
	users, err := a.authManager.GetUsers()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}
func (a *App) createUserHandler(w http.ResponseWriter, r *http.Request) {
	type req struct {
		Username string `json:"username"`
		Password string `json:"password"`
		Role     string `json:"role"`
	}
	var body req
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if err := a.authManager.CreateUser(body.Username, body.Password, body.Role); err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "User created"})
}
func (a *App) updateUserHandler(w http.ResponseWriter, r *http.Request) {
	username := mux.Vars(r)["username"]
	type req struct {
		Password *string `json:"password,omitempty"`
		Role     *string `json:"role,omitempty"`
	}
	var body req
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if err := a.authManager.UpdateUser(username, body.Password, body.Role); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "User updated"})
}
func (a *App) deleteUserHandler(w http.ResponseWriter, r *http.Request) {
	username := mux.Vars(r)["username"]
	if err := a.authManager.DeleteUser(username); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "User deleted"})
}
// 角色管理
func (a *App) getRolesHandler(w http.ResponseWriter, r *http.Request) {
	roles, err := a.authManager.GetRoles()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(roles)
}
func (a *App) createRoleHandler(w http.ResponseWriter, r *http.Request) {
	type req struct {
		Name        string   `json:"name"`
		Permissions []string `json:"permissions"`
	}
	var body req
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if err := a.authManager.CreateRole(body.Name, body.Permissions); err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Role created"})
}
func (a *App) updateRoleHandler(w http.ResponseWriter, r *http.Request) {
	name := mux.Vars(r)["name"]
	type req struct {
		Permissions []string `json:"permissions"`
	}
	var body req
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if err := a.authManager.UpdateRole(name, body.Permissions); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Role updated"})
}
func (a *App) deleteRoleHandler(w http.ResponseWriter, r *http.Request) {
	name := mux.Vars(r)["name"]
	if err := a.authManager.DeleteRole(name); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Role deleted"})
}
// 权限管理
func (a *App) getPermissionsHandler(w http.ResponseWriter, r *http.Request) {
	perms, err := a.authManager.GetPermissions()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(perms)
}
func (a *App) setPermissionsHandler(w http.ResponseWriter, r *http.Request) {
	var perms []string
	if err := json.NewDecoder(r.Body).Decode(&perms); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if err := a.authManager.SetPermissions(perms); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Permissions updated"})
}

func (a *App) Run() error {
	addr := fmt.Sprintf(":%d", a.config.Server.Port)
	log.Printf("Starting brick-x-auth-service on %s", addr)
	return http.ListenAndServe(addr, a.router)
} 