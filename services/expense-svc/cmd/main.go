// main.go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	port := "50053"
	http.HandleFunc("/ping", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ Hello from expense-svc!")
	})

	http.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "# FAKE metrics for expense-svc")
	})

	fmt.Println("🚀 Starting expense-svc on port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}
