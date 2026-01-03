class Announcement {
  final String title;
  final String message;
  final String type;

  Announcement({
    required this.title,
    required this.message,
    required this.type,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      title: json['title'],
      message: json['message'],
      type: json['type'],
    );
  }
}