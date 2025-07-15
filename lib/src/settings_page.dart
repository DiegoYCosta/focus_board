// lib/src/settings_page.dart

import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sobre o App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Board v1.0',
              style: Theme.of(context).textTheme.titleLarge,
            ),
                SizedBox(height: 12),
            Text('Um app focado em foco e desempenho, certifique-se de o utilizar apenas em um monitor widescreen ou quando houver mais de um monitor.'),
            SizedBox(height: 24),
            Text('Desenvolvido por Diego Costa.'),
            SizedBox(height: 12),
            Text('Desenvolvido em Flutter'),
          ],
        ),
      ),
    );
  }
}