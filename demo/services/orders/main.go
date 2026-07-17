// The orders service — sibling of the users service, sharing pkg/models.
//
// Run it:   cd demo/services/orders && go run .
// Try it:   curl localhost:8082/orders
package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gearup-demo/models"
)

// orders is a static dataset; a real service would use a store like the
// users service does. Exercise: extract an OrderStore interface here,
// mirroring services/users/store.go (use Space-f-f to flip between them).
var orders = []models.Order{
	{ID: "o1", UserID: "u1", Total: 4999, Status: models.OrderPaid},
	{ID: "o2", UserID: "u1", Total: 1250, Status: models.OrderPending},
	{ID: "o3", UserID: "u2", Total: 89900, Status: models.OrderShipped},
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /orders", handleList)
	mux.HandleFunc("GET /orders/cancellable", handleCancellable)

	log.Println("orders service on :8082")
	log.Fatal(http.ListenAndServe(":8082", mux))
}

func handleList(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, orders)
}

// handleCancellable returns orders that may still be cancelled.
// `gd` on CanCancel jumps into pkg/models/order.go.
func handleCancellable(w http.ResponseWriter, r *http.Request) {
	var out []models.Order
	for _, o := range orders {
		if o.CanCancel() {
			out = append(out, o)
		}
	}
	writeJSON(w, http.StatusOK, out)
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}
