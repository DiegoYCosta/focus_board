// lib/src/tip_edit_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:focus_board/src/tip_model.dart';
// import '../tip_model.dart';

class TipEditDialog extends StatefulWidget {
  final TipModel? tip;

  const TipEditDialog({Key? key, this.tip}) : super(key: key);

  @override
  _TipEditDialogState createState() => _TipEditDialogState();
}

class _TipEditDialogState extends State<TipEditDialog> {
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  String? _imagePath;
  bool _showLink = false;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.tip != null) {
      _contentController.text = widget.tip!.content;
      _imagePath = widget.tip!.imagePath;
      _linkController.text = widget.tip!.link ?? '';
      _showLink = widget.tip!.showLink;
      _isImage = widget.tip!.isImage;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imagePath = result.files.single.path;
        _isImage = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.tip == null ? 'Nova Dica' : 'Editar Dica',
        style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Conteúdo',
                hintText: 'Digite o texto da dica',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(fontFamily: 'Roboto'),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Link (opcional)',
                hintText: 'https://exemplo.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(fontFamily: 'Roboto'),
            ),
            if (_linkController.text.isNotEmpty) ...[
              SizedBox(height: 12),
              SwitchListTile(
                title: Text('Mostrar Preview do Link', style: TextStyle(fontFamily: 'Roboto')),
                value: _showLink,
                onChanged: (value) => setState(() => _showLink = value!),
                secondary: Icon(Icons.preview, color: Colors.green[600], size: 18),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                  label: Text('Selecionar Imagem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (_imagePath != null) ...[
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() {
                      _imagePath = null;
                      _isImage = false;
                    }),
                  ),
                ],
              ],
            ),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imagePath!),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600], fontFamily: 'Roboto')),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Salvar', style: TextStyle(color: Colors.white, fontFamily: 'Roboto')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final tip = TipModel(
              content: _contentController.text,
              isImage: _isImage,
              imagePath: _imagePath,
              link: _linkController.text.isEmpty ? null : _linkController.text,
              showLink: _showLink,
            );
            Navigator.pop(context, tip);
          },
        ),
      ],
    );
  }
}