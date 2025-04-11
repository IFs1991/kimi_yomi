package models

import (
	"errors"
	"time"

	"github.com/go-playground/validator/v10"
	"gorm.io/gorm"
)

// Purchase represents a purchase transaction (Apple In-App Purchase or Google Play Billing)
type Purchase struct {
	ID          uint      `json:"id" gorm:"primaryKey"`               // 自動採番されるID
	UserID      string    `json:"user_id" gorm:"index"`               // ユーザーID (Firebase AuthenticationのUID)
	ProductID   string    `json:"product_id" gorm:"index"`            // 商品ID (App Store Connect/Google Play Consoleで設定)
	PurchaseID  string    `json:"purchase_id" gorm:"unique;not null"` // 購入ID (レシートから取得、重複を防ぐためにunique)
	Platform    string    `json:"platform"`                           // "ios" or "android"
	Receipt     string    `json:"receipt"`                            // レシートデータ (検証のために保存)
	PurchasedAt time.Time `json:"purchased_at"`                       // 購入日時
	ExpiresAt   time.Time `json:"expires_at" gorm:"index"`            // 有効期限 (サブスクリプションの場合)
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Validate performs validation on Purchase fields
func (p *Purchase) Validate() error {
	validate := validator.New()
	return validate.Struct(p)
}

// BeforeCreate is a GORM hook that runs before creating a new purchase
func (p *Purchase) BeforeCreate(tx *gorm.DB) error {
	p.CreatedAt = time.Now()
	p.UpdatedAt = time.Now()
	if err := p.Validate(); err != nil {
		return err
	}
	// 重複チェックをここで行うことも可能 (purchase_id がuniqueの場合)
	var existingPurchase Purchase
	if err := tx.Where("purchase_id = ?", p.PurchaseID).First(&existingPurchase).Error; err == nil {
		// 既に同じ purchase_id が存在する場合は、エラーを返す (または更新処理を行う)
		// return errors.New("duplicated purchase_id")

		// 更新
		p.ID = existingPurchase.ID
		return tx.Model(&Purchase{}).Where("purchase_id = ?", p.PurchaseID).Updates(p).Error
	} else if !errors.Is(err, gorm.ErrRecordNotFound) { // レコードが存在しない以外のエラー
		return err
	}
	return nil
}

// BeforeUpdate is a GORM hook that runs before updating a purchase
func (p *Purchase) BeforeUpdate() error {
	p.UpdatedAt = time.Now()
	return p.Validate() // 更新時にもバリデーション
}
