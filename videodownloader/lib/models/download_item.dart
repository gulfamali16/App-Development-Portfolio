class DownloadItem {
  final int? id;
  final String title;
  final String url;
  final String platform;
  final String thumbnail;
  final String fileSize;
  final String? filePath;
  final DateTime downloadDate;
  final bool isCompleted;

  DownloadItem({
    this.id,
    required this.title,
    required this.url,
    required this.platform,
    required this.thumbnail,
    required this.fileSize,
    this.filePath,
    required this.downloadDate,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'platform': platform,
      'thumbnail': thumbnail,
      'fileSize': fileSize,
      'filePath': filePath,
      'downloadDate': downloadDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      platform: map['platform'] as String,
      thumbnail: map['thumbnail'] as String,
      fileSize: map['fileSize'] as String,
      filePath: map['filePath'] as String?,
      downloadDate: DateTime.fromMillisecondsSinceEpoch(map['downloadDate'] as int),
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }

  DownloadItem copyWith({
    int? id,
    String? title,
    String? url,
    String? platform,
    String? thumbnail,
    String? fileSize,
    String? filePath,
    DateTime? downloadDate,
    bool? isCompleted,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      thumbnail: thumbnail ?? this.thumbnail,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      downloadDate: downloadDate ?? this.downloadDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
