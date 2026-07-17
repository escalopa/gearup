// The users service — a tiny HTTP API over a UserStore.
//
// Run it:   cd demo/services/users && go run .
// Try it:   curl localhost:8081/users
package main

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"

	"github.com/gearup-demo/models"
)

func main() {
	store := NewMemoryStore()

	// Seed data — try `gd` on models.NewUser to jump into the shared package.
	seed := []models.User{
		models.NewUser("u1", "amina@example.com", "Amina"),
		models.NewUser("u2", "omar@example.com", "Omar"),
		models.NewUser("u3", "sara@example.com", "Sara"),
	}
	for _, u := range seed {
		if err := store.Put(u); err != nil {
			log.Fatalf("seed: %v", err)
		}
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /users", handleList(store))
	mux.HandleFunc("GET /users/{id}", handleGet(store))

	log.Println("users service on :8081")
	log.Fatal(http.ListenAndServe(":8081", mux))
}

func handleList(store UserStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, store.List())
	}
}

func handleGet(store UserStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		u, err := store.Get(r.PathValue("id"))
		if errors.Is(err, models.ErrNotFound) {
			http.Error(w, "no such user", http.StatusNotFound)
			return
		}
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		writeJSON(w, http.StatusOK, u)
	}
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}
