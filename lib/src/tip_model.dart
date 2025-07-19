// lib/src/tip_model.dart
import 'dart:io';

class TipModel {
  final String content;
  final bool isImage;
  final String? imagePath;
  final String? link;
  final bool showLink;

  TipModel({
    required this.content,
    required this.isImage,
    this.imagePath,
    this.link,
    this.showLink = false,
  });

  TipModel copyWith({
    String? content,
    bool? isImage,
    String? imagePath,
    String? link,
    bool? showLink,
  }) {
    return TipModel(
      content: content ?? this.content,
      isImage: isImage ?? this.isImage,
      imagePath: imagePath ?? this.imagePath,
      link: link ?? this.link,
      showLink: showLink ?? this.showLink,
    );
  }

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasLink => link != null && link!.trim().isNotEmpty;

  File? getFile() => imagePath != null ? File(imagePath!) : null;

  Map<String, dynamic> toJson() => {
    'content': content,
    'isImage': isImage,
    'imagePath': imagePath,
    'link': link,
    'showLink': showLink,
  };

  factory TipModel.fromJson(Map<String, dynamic> map) => TipModel(
    content: map['content'],
    isImage: map['isImage'] ?? false,
    imagePath: map['imagePath'],
    link: map['link'],
    showLink: map['showLink'] ?? false,
  );
}