// main.go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	port := "8088"
	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ Hello from obsidian-sync-svc!")
	})

	http.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "# FAKE metrics for  obsidian-sync-svc")
	})

	fmt.Println("🚀 Starting obsidian-sync-svc on port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}
