import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 44,
          child: Icon(Icons.person, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          displayName != null && displayName.isNotEmpty
              ? displayName
              : 'Usuário',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
          title: const Text('Modo escuro'),
          subtitle: const Text('Salvar preferência neste dispositivo'),
          value: darkMode,
          onChanged: onDarkModeChanged,
        ),
        const Divider(height: 32),
        FilledButton.icon(
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    );
  }
}
