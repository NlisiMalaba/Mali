package postgres

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mali-app/mali_api/internal/domain"
	"github.com/mali-app/mali_api/internal/repository/sqlc"
	"github.com/testcontainers/testcontainers-go"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

func TestUserRepository_WithRealPostgres(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	pg := startPostgresContainer(t, ctx)

	connString, err := pg.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("get postgres connection string: %v", err)
	}

	pool, err := pgxpool.New(ctx, connString)
	if err != nil {
		t.Fatalf("connect pgx pool: %v", err)
	}
	defer pool.Close()

	if err := applyMigrations(ctx, pool); err != nil {
		t.Fatalf("apply migrations: %v", err)
	}

	repo := NewUserRepository(sqlc.New(pool))

	email := "test@example.com"
	phone := "+263771000001"
	passwordHash := "hash_1"

	created, err := repo.Create(ctx, &domain.User{
		Email:        &email,
		Phone:        &phone,
		Name:         "Test User",
		PasswordHash: &passwordHash,
	})
	if err != nil {
		t.Fatalf("create user: %v", err)
	}

	if created.ID.String() == "" {
		t.Fatal("expected created user ID")
	}
	if created.Email == nil || *created.Email != email {
		t.Fatalf("unexpected email, got=%v", created.Email)
	}
	if created.Phone == nil || *created.Phone != phone {
		t.Fatalf("unexpected phone, got=%v", created.Phone)
	}

	byEmail, err := repo.FindByEmail(ctx, email)
	if err != nil {
		t.Fatalf("find by email: %v", err)
	}
	if byEmail.ID != created.ID {
		t.Fatalf("expected same user by email, got=%s want=%s", byEmail.ID, created.ID)
	}

	byPhone, err := repo.FindByPhone(ctx, phone)
	if err != nil {
		t.Fatalf("find by phone: %v", err)
	}
	if byPhone.ID != created.ID {
		t.Fatalf("expected same user by phone, got=%s want=%s", byPhone.ID, created.ID)
	}

	duplicatePhone := "+263771000002"
	_, err = repo.Create(ctx, &domain.User{
		Email:        &email,
		Phone:        &duplicatePhone,
		Name:         "Duplicate Email",
		PasswordHash: &passwordHash,
	})
	if err == nil {
		t.Fatal("expected duplicate email insert to fail")
	}
}

func startPostgresContainer(t *testing.T, ctx context.Context) *tcpostgres.PostgresContainer {
	t.Helper()

	pg, err := tcpostgres.Run(ctx,
		"postgres:16-alpine",
		tcpostgres.WithDatabase("mali_test"),
		tcpostgres.WithUsername("postgres"),
		tcpostgres.WithPassword("postgres"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(60*time.Second),
		),
	)
	if err != nil {
		t.Fatalf("start postgres testcontainer: %v", err)
	}

	t.Cleanup(func() {
		_ = pg.Terminate(context.Background())
	})

	return pg
}

func applyMigrations(ctx context.Context, pool *pgxpool.Pool) error {
	migrationsDir := filepath.Join("..", "..", "..", "db", "migrations")
	upFiles, err := filepath.Glob(filepath.Join(migrationsDir, "*.up.sql"))
	if err != nil {
		return fmt.Errorf("glob migration files: %w", err)
	}

	sort.Strings(upFiles)
	for _, path := range upFiles {
		sqlBytes, readErr := os.ReadFile(path)
		if readErr != nil {
			return fmt.Errorf("read migration %s: %w", path, readErr)
		}

		statement := strings.TrimSpace(string(sqlBytes))
		if statement == "" {
			continue
		}

		if _, execErr := pool.Exec(ctx, statement); execErr != nil {
			return fmt.Errorf("apply migration %s: %w", path, execErr)
		}
	}

	return nil
}

