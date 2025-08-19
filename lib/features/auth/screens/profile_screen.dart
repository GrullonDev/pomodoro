import 'package:flutter/material.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = ProfileViewModel()..load();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(t.profileTitle)),
          body: vm.loadingProfile
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.profileInfoSection, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              Text('UID: ${vm.uid ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              if (vm.email != null)
                                Text('Email: ${vm.email}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: vm.name,
                                decoration: InputDecoration(labelText: t.profileNameLabel),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: vm.saving
                                      ? null
                                      : () => vm.saveProfile(
                                            (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
                                            t.profileUpdated,
                                          ),
                                  child: vm.saving
                                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Text(t.profileSave),
                                ),
                              ),
                              if (vm.error != null) ...[
                                const SizedBox(height: 8),
                                Text(vm.error!, style: const TextStyle(color: Colors.red)),
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.profileChangePassword, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              TextField(
                                controller: vm.currentPwd,
                                obscureText: true,
                                decoration: InputDecoration(labelText: t.profileCurrentPasswordOptional),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: vm.newPwd,
                                obscureText: true,
                                decoration: InputDecoration(labelText: t.profileNewPassword),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: vm.confirmPwd,
                                obscureText: true,
                                decoration: InputDecoration(labelText: t.profileConfirmNewPassword),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: vm.saving
                                      ? null
                                      : () => vm.changePassword(t.passwordMismatch, t.passwordUpdated),
                                  child: Text(t.profileUpdatePassword),
                                ),
                              ),
                              if (vm.pwdMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  vm.pwdMessage!,
                                  style: TextStyle(
                                    color: vm.pwdMessage == t.passwordUpdated ? Colors.green : Colors.red,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
