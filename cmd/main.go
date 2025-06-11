// Package main is the entry point of the application.
package main

import (
	"fmt"
	"net/http"
)

func main() {
	port := "8088"

	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ Hello from Finhub Web Service!")
	})

	fmt.Println("🚀 Starting server on port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}
