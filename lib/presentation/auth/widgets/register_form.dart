import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/auth/widgets/terms_and_conditions_dialog.dart';
import '../cubit/auth_cubit.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showTermsAndConditions() async {
    final accepted = await showTermsAndConditionsDialog(context);
    if (accepted == true) {
      setState(() => _acceptedTerms = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.registerFullNameLabel),
            validator: (value) =>
                value!.isEmpty ? l10n.registerNameError : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l10n.loginEmailLabel),
            validator: (value) =>
                value!.contains('@') ? null : l10n.registerEmailInvalid,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
            validator: (value) =>
                value!.length < 6 ? l10n.loginPasswordMinError : null,
          ),
          const SizedBox(height: 24),
          // Terms and Conditions checkbox
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) {
                  if (value == true) {
                    _showTermsAndConditions();
                  } else {
                    setState(() => _acceptedTerms = false);
                  }
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showTermsAndConditions,
                  child: Text(
                    l10n.registerTermsAndConditionsLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_acceptedTerms)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.registerTermsAndConditionsError,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && _acceptedTerms) {
                  context.read<AuthCubit>().register(
                    _emailController.text.trim(),
                    _nameController.text.trim(),
                    _passwordController.text.trim(),
                  );
                } else if (!_acceptedTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.registerTermsAndConditionsError),
                    ),
                  );
                }
              },
              child: Text(l10n.registerSubmit),
            ),
          ),
        ],
      ),
    );
  }
}
