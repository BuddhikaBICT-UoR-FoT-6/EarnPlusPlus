class NotificationDto {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  NotificationDto({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'isRead': isRead,
        'createdAt': createdAt,
      };

  factory NotificationDto.fromJson(Map<String, dynamic> json) => NotificationDto(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['isRead'] as bool,
        createdAt: json['createdAt'] as String,
      );
}
