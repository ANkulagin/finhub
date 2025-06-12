#!/bin/bash
# scripts/update-services-ping.sh

services=(
    "auth-svc:50051"
    "profile-svc:50052"
    "expense-svc:50053"
    "budget-svc:50054"
    "notification-svc:50055"
    "obsidian-sync-svc:50056"
)

for service_data in "${services[@]}"; do
    IFS=':' read -r service grpc_port <<< "$service_data"

    cat > "services/$service/cmd/main.go" << EOF
// main.go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type PingResponse struct {
    Service   string    \`json:"service"\`
    Status    string    \`json:"status"\`
    Timestamp time.Time \`json:"timestamp"\`
    Version   string    \`json:"version"\`
}

func main() {
    serviceName := "$service"
    httpPort := "8089"
    grpcPort := "$grpc_port"

    httpMux := http.NewServeMux()

    httpMux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
        _, _ = fmt.Fprintf(w, "✅ %s is running!\\n", serviceName)
    })

    httpMux.HandleFunc("/ping", func(w http.ResponseWriter, _ *http.Request) {
        response := PingResponse{
            Service:   serviceName,
            Status:    "healthy",
            Timestamp: time.Now(),
            Version:   "1.0.0",
        }

        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(response)
    })

    httpMux.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
        w.Header().Set("Content-Type", "text/plain")
        _, _ = fmt.Fprintf(w, "# HELP service_up Service is up\\n")
        _, _ = fmt.Fprintf(w, "# TYPE service_up gauge\\n")
        _, _ = fmt.Fprintf(w, "service_up{service=\\"%s\\"} 1\\n", serviceName)
    })

    go func() {
        fmt.Printf("🌐 Starting HTTP server for %s on port %s\\n", serviceName, httpPort)
        if err := http.ListenAndServe(":"+httpPort, httpMux); err != nil {
            panic(fmt.Sprintf("HTTP server failed: %v", err))
        }
    }()

    fmt.Printf("🚀 Starting %s gRPC server on port %s\\n", serviceName, grpcPort)

    select {}
}
EOF
done

echo "✅ All services updated with ping endpoints!"