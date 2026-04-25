package middleware

import (
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

var slidingWindowScript = redis.NewScript(`
local key = KEYS[1]
local now_ms = tonumber(ARGV[1])
local window_ms = tonumber(ARGV[2])
local member = ARGV[3]

redis.call("ZREMRANGEBYSCORE", key, "-inf", now_ms - window_ms)
redis.call("ZADD", key, now_ms, member)
local count = redis.call("ZCARD", key)
redis.call("PEXPIRE", key, window_ms)

return count
`)

func AuthRateLimit(redisClient *redis.Client, limit int64, window time.Duration) fiber.Handler {
	windowMs := window.Milliseconds()

	return func(c *fiber.Ctx) error {
		if redisClient == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "SERVICE_UNAVAILABLE",
					"message": "rate limiter is not configured",
				},
			})
		}

		ip := c.IP()
		key := fmt.Sprintf("rate_limit:auth:%s", ip)
		nowMs := time.Now().UnixMilli()
		member := fmt.Sprintf("%d-%s", nowMs, uuid.NewString())

		result, err := slidingWindowScript.Run(c.UserContext(), redisClient, []string{key}, nowMs, windowMs, member).Int64()
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "RATE_LIMIT_ERROR",
					"message": "failed to evaluate rate limit",
				},
			})
		}

		if result > limit {
			retryAfterSeconds := int64(60)
			oldest, oldestErr := redisClient.ZRangeWithScores(c.UserContext(), key, 0, 0).Result()
			if oldestErr == nil && len(oldest) > 0 {
				elapsedMs := nowMs - int64(oldest[0].Score)
				remainingMs := windowMs - elapsedMs
				if remainingMs < 0 {
					remainingMs = 0
				}
				retryAfterSeconds = int64(math.Ceil(float64(remainingMs) / 1000))
				if retryAfterSeconds < 1 {
					retryAfterSeconds = 1
				}
			}

			c.Set("Retry-After", strconv.FormatInt(retryAfterSeconds, 10))
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error": fiber.Map{
					"code":    "RATE_LIMITED",
					"message": "too many requests",
				},
			})
		}

		return c.Next()
	}
}

