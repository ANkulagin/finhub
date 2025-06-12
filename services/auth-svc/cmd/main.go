// main.go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	port := "50051"
	http.HandleFunc("/ping", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ Hello from auth-svc!")
	})

	http.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "# FAKE metrics for authsvc")
	})

	fmt.Println("🚀 Starting auth-svc on port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}
