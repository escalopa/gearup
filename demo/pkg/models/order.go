package models

import "time"

// OrderStatus enumerates the order lifecycle.
type OrderStatus string

const (
	OrderPending   OrderStatus = "pending"
	OrderPaid      OrderStatus = "paid"
	OrderShipped   OrderStatus = "shipped"
	OrderCancelled OrderStatus = "cancelled"
)

// Order is a purchase made by a User. Note the UserID link — jump between
// this file and user.go with harpoon pins (Space-1 / Space-2).
type Order struct {
	ID        string      `json:"id"`
	UserID    string      `json:"user_id"`
	Total     int64       `json:"total_cents"`
	Status    OrderStatus `json:"status"`
	CreatedAt time.Time   `json:"created_at"`
}

// CanCancel reports whether the order may still be cancelled.
func (o Order) CanCancel() bool {
	return o.Status == OrderPending || o.Status == OrderPaid
}
