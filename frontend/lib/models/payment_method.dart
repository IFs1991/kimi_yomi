/// 支払い方法のタイプ（例：カード、アプリ内課金など）
enum PaymentType {
  card,
  inAppPurchaseApple,
  inAppPurchaseGoogle,
  unknown,
}

/// 支払い方法を表現するモデルクラス
class PaymentMethod {
  final String id; // 支払い方法の一意なID
  final PaymentType type; // 支払いタイプ
  final String? last4; // カードの下4桁など
  final String? brand; // カードブランドなど
  final DateTime? expiryDate; // 有効期限 (カードの場合)
  final bool isDefault; // デフォルトの支払い方法か

  PaymentMethod({
    required this.id,
    required this.type,
    this.last4,
    this.brand,
    this.expiryDate,
    this.isDefault = false,
  });

  // 必要に応じてファクトリコンストラクタやメソッドを追加
  // 例: Mapからの変換
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentType.values[json['type'] as int],
      last4: json['last4'] as String?,
      brand: json['brand'] as String?,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      isDefault: json['isDefault'] as bool,
    );
  }

  // 例: Mapへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'last4': last4,
      'brand': brand,
      'expiryDate': expiryDate?.toIso8601String(),
      'isDefault': isDefault,
    };
  }
}