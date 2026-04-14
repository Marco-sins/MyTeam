import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';
import 'package:football_manager/presentation/create_team/cubit/create_team_cubit.dart';
import 'package:football_manager/presentation/create_team/cubit/create_team_state.dart';
import 'package:football_manager/presentation/home/cubit/home_cubit.dart';

class AddTeamPage extends StatefulWidget {
  const AddTeamPage({super.key});

  @override
  State<AddTeamPage> createState() => _AddTeamPageState();
}

class _AddTeamPageState extends State<AddTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  PlatformFile? _selectedLogoFile;
  String _selectedCategory = 'Senior';

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      setState(() {
        _selectedLogoFile = file;
        _logoController.text = file.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo equipo')),
      body: BlocListener<CreateTeamCubit, CreateTeamState>(
        listener: (context, state) {
          if (state is CreateTeamSuccess) {
            // Refrescar lista de equipos del Home al crear uno nuevo
            context.read<HomeCubit>().fetchTeams();
            // Refrescar también los teamRoles del usuario para que sea admin
            // del nuevo equipo (y pueda, por ejemplo, borrarlo o gestionarlo).
            context.read<AuthCubit>().checkUserSession();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Equipo creado correctamente'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          }
          if (state is CreateTeamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_soccer_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Datos del equipo',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del equipo',
                        prefixIcon: Icon(Icons.shield_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Introduce un nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Categoría
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                      ),
                      items:
                          [
                                'Prebenjamín',
                                'Benjamín',
                                'Alevín',
                                'Infantil',
                                'Cadete',
                                'Juvenil',
                                'Senior',
                              ]
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                    ),
                    const SizedBox(height: 16),
                    // Logo (opcional) - selector de imagen
                    Text(
                      'Logo del equipo (opcional)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        _selectedLogoFile == null
                            ? 'Seleccionar imagen'
                            : _logoController.text,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _pickLogo,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<CreateTeamCubit, CreateTeamState>(
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state is CreateTeamLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      if (mounted) {
                                        context
                                            .read<CreateTeamCubit>()
                                            .createTeam(
                                              _nameController.text.trim(),
                                              _selectedCategory,
                                            );
                                      }
                                    }
                                  },
                            child: state is CreateTeamLoading
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  )
                                : const Text('Guardar equipo'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
