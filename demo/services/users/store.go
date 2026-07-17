package main

import (
	"sync"

	"github.com/gearup-demo/models"
)

// UserStore is the persistence interface. Put your cursor on it and press
// gI — you'll jump to every implementation (MemoryStore here; real
// codebases will have postgres, redis, mocks...).
type UserStore interface {
	Get(id string) (models.User, error)
	Put(u models.User) error
	List() []models.User
}

// MemoryStore is an in-memory UserStore implementation.
type MemoryStore struct {
	mu    sync.RWMutex
	users map[string]models.User
}

// NewMemoryStore creates an empty MemoryStore.
func NewMemoryStore() *MemoryStore {
	return &MemoryStore{users: make(map[string]models.User)}
}

// Get returns the user with the given id, or models.ErrNotFound.
func (s *MemoryStore) Get(id string) (models.User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	u, ok := s.users[id]
	if !ok {
		return models.User{}, models.ErrNotFound
	}
	return u, nil
}

// Put validates and stores a user.
func (s *MemoryStore) Put(u models.User) error {
	if err := u.Validate(); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.users[u.ID] = u
	return nil
}

// List returns all users. TODO(demo): add pagination.
func (s *MemoryStore) List() []models.User {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]models.User, 0, len(s.users))
	for _, u := range s.users {
		out = append(out, u)
	}
	return out
}
