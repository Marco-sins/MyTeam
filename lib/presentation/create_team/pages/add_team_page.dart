import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/presentation/home/bloc/home_cubit.dart';
import 'package:tfg1/presentation/auth/bloc/auth_cubit.dart';
import '../../create_team/bloc/create_team_cubit.dart';
import '../../create_team/bloc/create_team_state.dart';

class AddTeamPage extends StatefulWidget {
  const AddTeamPage({super.key});

  @override
  State<AddTeamPage> createState() => _AddTeamPageState();
}

class _AddTeamPageState extends State<AddTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  String? _selectedLogoPath;
  String _selectedCategory = 'Senior';

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      setState(() {
        _selectedLogoPath = file.path ?? file.name;
        _logoController.text = file.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Equipo')),
      body: BlocListener<CreateTeamCubit, CreateTeamState>(
        listener: (context, state) {
          if (state is CreateTeamSuccess) {
            // Refrescar lista de equipos del Home al crear uno nuevo
            context.read<HomeCubit>().fetchTeams();
            // Refrescar también los teamRoles del usuario para que sea admin
            // del nuevo equipo (y pueda, por ejemplo, borrarlo o gestionarlo).
            context.read<AuthCubit>().checkUserSession();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Equipo creado con éxito'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
          if (state is CreateTeamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
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
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.sports_soccer, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Información del Equipo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Equipo',
                        prefixIcon: const Icon(Icons.shield_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Introduce un nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Categoría
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
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
                        _selectedLogoPath == null
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
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            onPressed: state is CreateTeamLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      context
                                          .read<CreateTeamCubit>()
                                          .createTeam(
                                            _nameController.text.trim(),
                                            _selectedCategory,
                                            _selectedLogoPath,
                                          );
                                    }
                                  },
                            child: state is CreateTeamLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'GUARDAR EQUIPO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
