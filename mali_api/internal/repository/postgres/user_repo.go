package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
)

type UserRepository struct {
	queries *sqlc.Queries
}

func NewUserRepository(queries *sqlc.Queries) *UserRepository {
	return &UserRepository{queries: queries}
}

var _ domain.IUserRepository = (*UserRepository)(nil)

func (r *UserRepository) Create(ctx context.Context, user *domain.User) (*domain.User, error) {
	params := sqlc.CreateUserParams{
		Email:        textFromPtr(user.Email),
		Phone:        textFromPtr(user.Phone),
		Name:         user.Name,
		PasswordHash: textFromPtr(user.PasswordHash),
	}

	created, err := r.queries.CreateUser(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	mapped, err := mapSQLCUserToDomain(created)
	if err != nil {
		return nil, fmt.Errorf("map created user: %w", err)
	}

	return mapped, nil
}

func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	found, err := r.queries.GetUserByEmail(ctx, pgtype.Text{String: email, Valid: true})
	if err != nil {
		return nil, fmt.Errorf("find user by email: %w", err)
	}

	user, err := mapSQLCUserToDomain(found)
	if err != nil {
		return nil, fmt.Errorf("map user by email: %w", err)
	}

	return user, nil
}

func (r *UserRepository) FindByPhone(ctx context.Context, phone string) (*domain.User, error) {
	found, err := r.queries.GetUserByPhone(ctx, pgtype.Text{String: phone, Valid: true})
	if err != nil {
		return nil, fmt.Errorf("find user by phone: %w", err)
	}

	user, err := mapSQLCUserToDomain(found)
	if err != nil {
		return nil, fmt.Errorf("map user by phone: %w", err)
	}

	return user, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	var dbID pgtype.UUID
	if err := dbID.Scan(id.String()); err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	found, err := r.queries.GetUserByID(ctx, dbID)
	if err != nil {
		return nil, fmt.Errorf("find user by id: %w", err)
	}

	user, err := mapSQLCUserToDomain(found)
	if err != nil {
		return nil, fmt.Errorf("map user by id: %w", err)
	}

	return user, nil
}

func (r *UserRepository) UpdatePassword(ctx context.Context, id uuid.UUID, passwordHash string) error {
	var dbID pgtype.UUID
	if err := dbID.Scan(id.String()); err != nil {
		return fmt.Errorf("parse user id: %w", err)
	}

	err := r.queries.UpdateUserPassword(ctx, sqlc.UpdateUserPasswordParams{
		ID:           dbID,
		PasswordHash: pgtype.Text{String: passwordHash, Valid: true},
	})
	if err != nil {
		return fmt.Errorf("update user password: %w", err)
	}

	return nil
}

func mapSQLCUserToDomain(user sqlc.User) (*domain.User, error) {
	parsedID, err := uuidFromPG(user.ID)
	if err != nil {
		return nil, fmt.Errorf("parse user id: %w", err)
	}

	createdAt, err := timeFromPG(user.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("parse created_at: %w", err)
	}

	updatedAt, err := timeFromPG(user.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("parse updated_at: %w", err)
	}

	return &domain.User{
		ID:           parsedID,
		Email:        ptrFromText(user.Email),
		Phone:        ptrFromText(user.Phone),
		Name:         user.Name,
		PasswordHash: ptrFromText(user.PasswordHash),
		CreatedAt:    createdAt,
		UpdatedAt:    updatedAt,
	}, nil
}

func ptrFromText(value pgtype.Text) *string {
	if !value.Valid {
		return nil
	}

	v := value.String
	return &v
}

func textFromPtr(value *string) pgtype.Text {
	if value == nil {
		return pgtype.Text{}
	}

	return pgtype.Text{
		String: *value,
		Valid:  true,
	}
}

func uuidFromPG(value pgtype.UUID) (uuid.UUID, error) {
	if !value.Valid {
		return uuid.Nil, fmt.Errorf("uuid is null")
	}

	raw, err := value.Value()
	if err != nil {
		return uuid.Nil, err
	}

	u, ok := raw.([16]byte)
	if !ok {
		return uuid.Nil, fmt.Errorf("unexpected uuid value type: %T", raw)
	}

	return uuid.UUID(u), nil
}

func timeFromPG(value pgtype.Timestamptz) (time.Time, error) {
	if !value.Valid {
		return time.Time{}, fmt.Errorf("timestamp is null")
	}

	return value.Time, nil
}

