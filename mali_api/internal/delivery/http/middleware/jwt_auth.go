package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

type AccessTokenClaims struct {
	TokenType string `json:"token_type"`
	jwt.RegisteredClaims
}

func JWTAuth(accessSecret string) fiber.Handler {
	secret := []byte(strings.TrimSpace(accessSecret))

	return func(c *fiber.Ctx) error {
		if len(secret) == 0 {
			return unauthorized(c, "auth middleware is not configured")
		}

		authHeader := strings.TrimSpace(c.Get(fiber.HeaderAuthorization))
		if authHeader == "" {
			return unauthorized(c, "missing authorization header")
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			return unauthorized(c, "invalid authorization header format")
		}

		tokenString := strings.TrimSpace(parts[1])
		if tokenString == "" {
			return unauthorized(c, "missing bearer token")
		}

		claims := &AccessTokenClaims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(t *jwt.Token) (interface{}, error) {
			if t.Method == nil || t.Method.Alg() != jwt.SigningMethodHS256.Alg() {
				return nil, jwt.ErrTokenSignatureInvalid
			}
			return secret, nil
		})
		if err != nil || token == nil || !token.Valid {
			return unauthorized(c, "invalid or expired token")
		}

		if claims.TokenType != "access" {
			return unauthorized(c, "invalid token type")
		}
		if claims.Subject == "" {
			return unauthorized(c, "missing token subject")
		}

		c.Locals("userID", claims.Subject)

		return c.Next()
	}
}

func unauthorized(c *fiber.Ctx, message string) error {
	requestID, _ := c.Locals("request_id").(string)
	return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
		"error": fiber.Map{
			"code":       "UNAUTHORIZED",
			"message":    message,
			"request_id": requestID,
		},
	})
}

