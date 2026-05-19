class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final int createdAt;
  final int? productId;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.productId,
    this.read = false,
  });

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    int? createdAt,
    int? productId,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      productId: productId ?? this.productId,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'createdAt': createdAt,
        'productId': productId,
        'read': read,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: (map['createdAt'] as num).toInt(),
      productId: (map['productId'] as num?)?.toInt(),
      read: map['read'] as bool? ?? false,
    );
  }
}
