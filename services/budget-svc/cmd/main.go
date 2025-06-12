// main.go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	port := "50054"
	http.HandleFunc("/ping", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ Hello from budget-svc!")
	})

	http.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "# FAKE metrics for budget-svc")
	})

	fmt.Println("🚀 Starting auth-svc on port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}
