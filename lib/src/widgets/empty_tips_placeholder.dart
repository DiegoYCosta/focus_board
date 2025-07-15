import 'package:flutter/material.dart';

class EmptyTipsPlaceholder extends StatelessWidget {
  const EmptyTipsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Nenhuma tela adicionada ainda",
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            "Clique no botão '+' abaixo para adicionar sua primeira tela.",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
