package config

import (
	"fmt"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	DatabaseURL      string
	RedisURL         string
	JWTSecret        string
	JWTRefreshSecret string
	Port             string
	Env              string
}

func Load() (Config, error) {
	v := viper.New()
	v.AutomaticEnv()

	v.SetDefault("ENV", "development")
	env := strings.ToLower(v.GetString("ENV"))

	if env != "production" {
		v.SetConfigFile(".env")
		if err := v.ReadInConfig(); err != nil {
			return Config{}, fmt.Errorf("failed to read .env config file in %s mode: %w", env, err)
		}
	}

	cfg := Config{
		DatabaseURL:      strings.TrimSpace(v.GetString("DATABASE_URL")),
		RedisURL:         strings.TrimSpace(v.GetString("REDIS_URL")),
		JWTSecret:        strings.TrimSpace(v.GetString("JWT_SECRET")),
		JWTRefreshSecret: strings.TrimSpace(v.GetString("JWT_REFRESH_SECRET")),
		Port:             strings.TrimSpace(v.GetString("PORT")),
		Env:              strings.TrimSpace(v.GetString("ENV")),
	}

	if cfg.Env == "" {
		cfg.Env = "development"
	}

	if err := validateRequired(cfg); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func validateRequired(cfg Config) error {
	required := map[string]string{
		"DATABASE_URL":      cfg.DatabaseURL,
		"REDIS_URL":         cfg.RedisURL,
		"JWT_SECRET":        cfg.JWTSecret,
		"JWT_REFRESH_SECRET": cfg.JWTRefreshSecret,
		"PORT":              cfg.Port,
		"ENV":               cfg.Env,
	}

	for key, value := range required {
		if strings.TrimSpace(value) == "" {
			return fmt.Errorf("missing required config value: %s", key)
		}
	}

	return nil
}

