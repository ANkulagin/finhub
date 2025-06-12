// main.go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
)

// ServiceHealth represents the health status of a service
type ServiceHealth struct {
	Name      string        `json:"name"`
	Status    string        `json:"status"`
	Latency   time.Duration `json:"latency_ms"`
	Error     string        `json:"error,omitempty"`
	Timestamp time.Time     `json:"timestamp"`
}

// HealthResponse is the response for the /ping endpoint
type HealthResponse struct {
	Status    string                   `json:"status"`
	Services  map[string]ServiceHealth `json:"services"`
	Timestamp time.Time                `json:"timestamp"`
}

func main() {
	port := "8088"

	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ FinHub Gateway Service")
	})

	// Health check endpoint that pings all services
	http.HandleFunc("/ping", pingAllServices)

	// Individual service proxy endpoints
	http.HandleFunc("/auth/ping", proxyPing("auth-svc", "50051"))
	http.HandleFunc("/profile/ping", proxyPing("profile-svc", "50052"))
	http.HandleFunc("/expense/ping", proxyPing("expense-svc", "50053"))
	http.HandleFunc("/budget/ping", proxyPing("budget-svc", "50054"))
	http.HandleFunc("/notification/ping", proxyPing("notification-svc", "50055"))
	http.HandleFunc("/obsidian/ping", proxyPing("obsidian-sync-svc", "50056"))

	http.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "# FAKE metrics for gateway-svc")
	})

	fmt.Printf("🚀 Starting gateway-svc on port %s\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}

func pingAllServices(w http.ResponseWriter, r *http.Request) {
	services := []struct {
		name string
		host string
		port string
	}{
		{"auth-svc", "auth-svc", "8089"},
		{"profile-svc", "profile-svc", "8089"},
		{"expense-svc", "expense-svc", "8089"},
		{"budget-svc", "budget-svc", "8089"},
		{"notification-svc", "notification-svc", "8089"},
		{"obsidian-sync-svc", "obsidian-sync-svc", "8089"},
	}

	var wg sync.WaitGroup
	healthChecks := make(map[string]ServiceHealth)
	mu := sync.Mutex{}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	// Параллельная проверка всех сервисов
	for _, svc := range services {
		wg.Add(1)
		go func(name, host, port string) {
			defer wg.Done()

			health := checkServiceHealth(ctx, name, host, port)

			mu.Lock()
			healthChecks[name] = health
			mu.Unlock()
		}(svc.name, svc.host, svc.port)
	}

	wg.Wait()

	// Определяем общий статус
	overallStatus := "healthy"
	for _, health := range healthChecks {
		if health.Status != "healthy" {
			overallStatus = "unhealthy"
			break
		}
	}

	response := HealthResponse{
		Status:    overallStatus,
		Services:  healthChecks,
		Timestamp: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	if overallStatus != "healthy" {
		w.WriteHeader(http.StatusServiceUnavailable)
	}

	_ = json.NewEncoder(w).Encode(response)
}

func checkServiceHealth(ctx context.Context, name, host, port string) ServiceHealth {
	start := time.Now()
	health := ServiceHealth{
		Name:      name,
		Timestamp: time.Now(),
	}

	url := fmt.Sprintf("http://%s:%s/ping", host, port)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		health.Status = "error"
		health.Error = fmt.Sprintf("failed to create request: %v", err)
		return health
	}

	client := &http.Client{
		Timeout: 2 * time.Second,
	}

	resp, err := client.Do(req)
	latency := time.Since(start)
	health.Latency = latency / time.Millisecond

	if err != nil {
		health.Status = "unhealthy"
		health.Error = fmt.Sprintf("connection failed: %v", err)
		return health
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode == http.StatusOK {
		health.Status = "healthy"
	} else {
		health.Status = "unhealthy"
		health.Error = fmt.Sprintf("unexpected status code: %d", resp.StatusCode)
	}

	return health
}

// proxyPing proxies a ping request to a specific service
func proxyPing(serviceName, servicePort string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		health := checkServiceHealth(ctx, serviceName, serviceName, servicePort)

		w.Header().Set("Content-Type", "application/json")
		if health.Status != "healthy" {
			w.WriteHeader(http.StatusServiceUnavailable)
		}

		_ = json.NewEncoder(w).Encode(health)
	}
}
