// main.go
package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	port := "8088"
	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "✅ Hello from gateway-svc!")
	})

	http.HandleFunc("/budget", func(w http.ResponseWriter, _ *http.Request) {

		resp, err := http.Get("http://budget-svc:8088/")
		if err != nil {
			// Если не удалось подключиться к сервису, возвращаем ошибку
			http.Error(w, "Could not connect to budget-svc", http.StatusServiceUnavailable)
			fmt.Printf("Error connecting to budget-svc: %v\n", err)
			return
		}
		defer func() {
			_ = resp.Body.Close()
		}()

		// Копируем заголовоки из ответа budget-svc в наш ответ
		for key, values := range resp.Header {
			for _, value := range values {
				w.Header().Add(key, value)
			}
		}

		// Устанавливаем статус-код ответа такой же, как у budget-svc
		w.WriteHeader(resp.StatusCode)

		// Копируем тело ответа от budget-svc напрямую в наш ответ
		_, _ = io.Copy(w, resp.Body)
	})

	http.HandleFunc("/metrics", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintln(w, "# FAKE metrics for gateway-svc")
	})

	fmt.Println("🚀 Starting gateway-svc on port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}
