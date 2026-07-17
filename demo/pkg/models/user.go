// Package models holds domain types shared by every service.
// In a huge monorepo this is the kind of package that has HUNDREDS of
// references — perfect for practicing gr (find references).
package models

import (
	"errors"
	"time"
)

// ErrNotFound is returned by any store when an entity does not exist.
var ErrNotFound = errors.New("not found")

// User is the core identity type. Try `gr` on it — both services use it.
type User struct {
	ID        string    `json:"id"`
	Email     string    `json:"email"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

// NewUser builds a User with defaults applied.
// TODO(demo): validate the email format here.
func NewUser(id, email, name string) User {
	return User{
		ID:        id,
		Email:     email,
		Name:      name,
		CreatedAt: time.Now().UTC(),
	}
}

// Validate reports whether the user is complete enough to persist.
func (u User) Validate() error {
	if u.ID == "" || u.Email == "" {
		return errors.New("user: id and email are required")
	}
	return nil
}
