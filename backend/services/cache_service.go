package services

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
)

type CacheService struct {
	client *redis.Client
}

type CacheConfig struct {
	DefaultTTL time.Duration
	MaxRetries int
}

// キャッシュキーの構造体
type CacheKey struct {
	Model     string
	Prompt    string
	MaxTokens int
}

// 生成AIのレスポンス構造体
type AIResponse struct {
	Text      string    `json:"text"`
	CreatedAt time.Time `json:"created_at"`
	Model     string    `json:"model"`
}

func NewCacheService(client *redis.Client) *CacheService {
	return &CacheService{
		client: client,
	}
}

// キャッシュキーを生成
func (k CacheKey) String() string {
	return fmt.Sprintf("ai:response:%s:%s:%d", k.Model, k.Prompt, k.MaxTokens)
}

// 生成AIのレスポンスをキャッシュから取得
func (s *CacheService) GetAIResponse(ctx context.Context, key CacheKey) (*AIResponse, error) {
	val, err := s.client.Get(ctx, key.String()).Result()
	if err == redis.Nil {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("キャッシュの取得に失敗: %w", err)
	}

	var response AIResponse
	if err := json.Unmarshal([]byte(val), &response); err != nil {
		return nil, fmt.Errorf("レスポンスのデシリアライズに失敗: %w", err)
	}

	return &response, nil
}

// 生成AIのレスポンスをキャッシュに保存
func (s *CacheService) SetAIResponse(ctx context.Context, key CacheKey, response *AIResponse, ttl time.Duration) error {
	data, err := json.Marshal(response)
	if err != nil {
		return fmt.Errorf("レスポンスのシリアライズに失敗: %w", err)
	}

	if err := s.client.Set(ctx, key.String(), data, ttl).Err(); err != nil {
		return fmt.Errorf("キャッシュの保存に失敗: %w", err)
	}

	return nil
}

// 類似プロンプトのキャッシュを検索
func (s *CacheService) SearchSimilarResponses(ctx context.Context, prompt string, similarity float64) ([]*AIResponse, error) {
	pattern := fmt.Sprintf("ai:response:*:%s:*", prompt[:min(len(prompt), 50)])
	keys, err := s.client.Keys(ctx, pattern).Result()
	if err != nil {
		return nil, fmt.Errorf("類似キーの検索に失敗: %w", err)
	}

	var responses []*AIResponse
	for _, key := range keys {
		val, err := s.client.Get(ctx, key).Result()
		if err != nil {
			continue
		}

		var response AIResponse
		if err := json.Unmarshal([]byte(val), &response); err != nil {
			continue
		}

		// TODO: プロンプトの類似度チェックを実装
		// 現在は単純なプレフィックスマッチング
		responses = append(responses, &response)
	}

	return responses, nil
}

// キャッシュの有効期限を更新
func (s *CacheService) UpdateTTL(ctx context.Context, key CacheKey, ttl time.Duration) error {
	return s.client.Expire(ctx, key.String(), ttl).Err()
}

// キャッシュの統計情報を取得
func (s *CacheService) GetStats(ctx context.Context) (map[string]interface{}, error) {
	info, err := s.client.Info(ctx, "memory").Result()
	if err != nil {
		return nil, fmt.Errorf("統計情報の取得に失敗: %w", err)
	}

	// TODO: 統計情報のパース処理を実装
	return map[string]interface{}{
		"raw_info": info,
	}, nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
