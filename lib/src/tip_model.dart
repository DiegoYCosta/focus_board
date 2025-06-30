import 'dart:io';

class TipModel {
  final String content;
  final String? imagePath;
  final String? link;
  final bool showLink; // Adicionado!

  TipModel({
    required this.content,
    this.imagePath,
    this.link,
    this.showLink = false, // valor padrão!
  });

  bool get isImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isLink => link != null && link!.trim().isNotEmpty;

  File? getFile() => imagePath != null ? File(imagePath!) : null;

  Map<String, dynamic> toJson() => {
    'content': content,
    'imagePath': imagePath,
    'link': link,
    'showLink': showLink, // salva!
  };

  factory TipModel.fromJson(Map<String, dynamic> map) => TipModel(
    content: map['content'],
    imagePath: map['imagePath'],
    link: map['link'],
    showLink: map['showLink'] ?? false, // lê, valor default = false
  );
}
