import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'tip_model.dart';

class TipEditDialog extends StatefulWidget {
  final TipModel? tip;

  const TipEditDialog({Key? key, this.tip}) : super(key: key);

  @override
  State<TipEditDialog> createState() => _TipEditDialogState();
}

class _TipEditDialogState extends State<TipEditDialog> {
  TextEditingController contentCtrl = TextEditingController();
  TextEditingController linkCtrl = TextEditingController();
  String? imagePath;
  bool showLink = false; // Novo campo

  @override
  void initState() {
    super.initState();
    contentCtrl.text = widget.tip?.content ?? '';
    linkCtrl.text = widget.tip?.link ?? '';
    imagePath = widget.tip?.imagePath;
    showLink = widget.tip?.showLink ?? false;
  }

  void pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        imagePath = result.files.single.path!;
      });
    }
  }

  void removeImage() {
    setState(() {
      imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tip == null ? 'Nova Dica' : 'Editar Dica'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Texto da Dica'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: linkCtrl,
              decoration: InputDecoration(
                labelText: 'Link (opcional)',
                hintText: 'https://...',
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: showLink,
                  onChanged: (v) => setState(() => showLink = v ?? false),
                ),
                Expanded(
                  child: Text("Mostrar o link ao final"),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (imagePath != null)
              Column(
                children: [
                  Image.file(File(imagePath!), height: 100),
                  TextButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Remover Imagem'),
                    onPressed: removeImage,
                  ),
                ],
              ),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Imagem'),
                  onPressed: pickImage,
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Salvar'),
          onPressed: () {
            final tip = TipModel(
              content: contentCtrl.text,
              isImage: imagePath != null && imagePath!.isNotEmpty,
              imagePath: imagePath,
              link: linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim(),
              showLink: showLink,
            );
            Navigator.pop(context, tip);
          },
        ),
      ],
    );
  }
}
