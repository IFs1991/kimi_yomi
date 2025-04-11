package services

import (
	"context"
	"fmt"
	"time"
)

type AIService struct {
	cache    *CacheService
	config   *AIConfig
	provider AIProvider
}

type AIConfig struct {
	CacheTTL            time.Duration
	SimilarityThreshold float64
	MaxRetries          int
	RetryDelay          time.Duration
}

type AIProvider interface {
	Generate(ctx context.Context, prompt string, maxTokens int) (string, error)
	GetModelName() string
}

func NewAIService(cache *CacheService, provider AIProvider, config *AIConfig) *AIService {
	return &AIService{
		cache:    cache,
		provider: provider,
		config:   config,
	}
}

// 生成AIを使用してテキストを生成（キャッシュ付き）
func (s *AIService) GenerateText(ctx context.Context, prompt string, maxTokens int) (*AIResponse, error) {
	// キャッシュキーを作成
	key := CacheKey{
		Model:     s.provider.GetModelName(),
		Prompt:    prompt,
		MaxTokens: maxTokens,
	}

	// キャッシュをチェック
	if response, err := s.cache.GetAIResponse(ctx, key); err == nil && response != nil {
		// キャッシュヒット：TTLを更新して返す
		s.cache.UpdateTTL(ctx, key, s.config.CacheTTL)
		return response, nil
	}

	// 類似のプロンプトをチェック
	similarResponses, err := s.cache.SearchSimilarResponses(ctx, prompt, s.config.SimilarityThreshold)
	if err == nil && len(similarResponses) > 0 {
		// 類似レスポンスが見つかった場合は最も類似度の高いものを返す
		// TODO: 類似度に基づいて最適なレスポンスを選択
		return similarResponses[0], nil
	}

	// キャッシュミス：APIを呼び出し
	text, err := s.generateWithRetry(ctx, prompt, maxTokens)
	if err != nil {
		return nil, fmt.Errorf("テキスト生成に失敗: %w", err)
	}

	// レスポンスを作成
	response := &AIResponse{
		Text:      text,
		CreatedAt: time.Now(),
		Model:     s.provider.GetModelName(),
	}

	// キャッシュに保存
	if err := s.cache.SetAIResponse(ctx, key, response, s.config.CacheTTL); err != nil {
		// キャッシュの保存に失敗してもレスポンスは返す
		fmt.Printf("キャッシュの保存に失敗: %v\n", err)
	}

	return response, nil
}

// リトライ付きの生成処理
func (s *AIService) generateWithRetry(ctx context.Context, prompt string, maxTokens int) (string, error) {
	var lastErr error
	for i := 0; i < s.config.MaxRetries; i++ {
		text, err := s.provider.Generate(ctx, prompt, maxTokens)
		if err == nil {
			return text, nil
		}
		lastErr = err
		time.Sleep(s.config.RetryDelay)
	}
	return "", fmt.Errorf("リトライ回数超過: %w", lastErr)
}

// キャッシュ統計の取得
func (s *AIService) GetCacheStats(ctx context.Context) (map[string]interface{}, error) {
	return s.cache.GetStats(ctx)
}
