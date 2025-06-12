// main.go
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// PingResponse is the response for the /ping endpoint
type PingResponse struct {
	Service   string    `json:"service"`
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
}

func main() {
	serviceName := "auth-svc"
	httpPort := "8089"
	grpcPort := "50051"

	httpMux := http.NewServeMux()

	httpMux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintf(w, "✅ %s is running!\n", serviceName)
	})

	httpMux.HandleFunc("/ping", func(w http.ResponseWriter, _ *http.Request) {
		response := PingResponse{
			Service:   serviceName,
			Status:    "healthy",
			Timestamp: time.Now(),
			Version:   "1.0.0",
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(response)
	})

	httpMux.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		_, _ = fmt.Fprintf(w, "# HELP service_up Service is up\n")
		_, _ = fmt.Fprintf(w, "# TYPE service_up gauge\n")
		_, _ = fmt.Fprintf(w, "service_up{service=\"%s\"} 1\n", serviceName)
	})

	go func() {
		fmt.Printf("🌐 Starting HTTP server for %s on port %s\n", serviceName, httpPort)
		if err := http.ListenAndServe(":"+httpPort, httpMux); err != nil {
			panic(fmt.Sprintf("HTTP server failed: %v", err))
		}
	}()

	fmt.Printf("🚀 Starting %s gRPC server on port %s\n", serviceName, grpcPort)

	select {}
}
