// lib/src/tip_storage.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'tip_model.dart';

class TipStorage {
  static Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/tips.json';
  }

  static Future<List<TipModel>> loadTips() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) return [];
      final jsonStr = await file.readAsString();
      final list = (jsonDecode(jsonStr) as List).map((e) {
        print('Carregando tip: ${e['content']} | showLink: ${e['showLink']}');
        return TipModel.fromJson(e);
      }).toList();
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveTips(List<TipModel> tips) async {
    final file = File(await _filePath);
    await file.writeAsString(jsonEncode(tips.map((t) => t.toJson()).toList()));
  }
}