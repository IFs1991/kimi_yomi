/// 課金プランのタイプ（例：月額、年額）
enum PlanInterval {
  month,
  year,
  oneTime, // 買い切りなど
  unknown,
}

/// 料金プランを表現するモデルクラス
class Plan {
  final String id; // プランの一意なID (例: 'premium_monthly')
  final String name; // プラン名 (例: 'プレミアムプラン')
  final String description; // プランの説明
  final double price; // 価格
  final String currency; // 通貨コード (例: 'JPY')
  final PlanInterval interval; // 課金間隔
  final int? intervalCount; // 課金間隔の数 (例: 1ヶ月ごと、3ヶ月ごと)
  final String? platformProductId; // App Store / Google Play の商品ID
  final List<String> features; // このプランで利用可能な機能リスト

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    this.intervalCount = 1,
    this.platformProductId,
    this.features = const [],
  });

  // 必要に応じてファクトリコンストラクタやメソッドを追加
  // 例: Mapからの変換
  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      interval: PlanInterval.values[json['interval'] as int],
      intervalCount: json['interval_count'] as int?,
      platformProductId: json['platform_product_id'] as String?,
      features: List<String>.from(json['features'] as List<dynamic>),
    );
  }

  // 例: Mapへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval.index,
      'interval_count': intervalCount,
      'platform_product_id': platformProductId,
      'features': features,
    };
  }

  String get formattedPrice {
    // 簡単な価格フォーマット例 (必要に応じてintlパッケージなどを使用)
    return "${price.toStringAsFixed(0)} $currency / ${interval.toString().split('.').last}";
  }
}