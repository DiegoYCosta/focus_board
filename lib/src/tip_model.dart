import 'dart:io';

class TipModel {
  final String content;
  final String? imagePath;

  TipModel({required this.content, this.imagePath});

  bool get isImage => imagePath != null && imagePath!.isNotEmpty;

  File? getFile() => imagePath != null ? File(imagePath!) : null;

  Map<String, dynamic> toJson() => {
    'content': content,
    'imagePath': imagePath,
  };

  factory TipModel.fromJson(Map<String, dynamic> map) => TipModel(
    content: map['content'],
    imagePath: map['imagePath'],
  );
}
