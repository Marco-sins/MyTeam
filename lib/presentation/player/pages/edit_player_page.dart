import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/update_player_use_case.dart';

class EditPlayerPage extends StatefulWidget {
  final Team team;
  final Player player;
  final AuthUser currentUser;
  final UpdatePlayerUseCase updatePlayerUseCase;

  const EditPlayerPage({
    super.key,
    required this.team,
    required this.player,
    required this.currentUser,
    required this.updatePlayerUseCase,
  });

  @override
  State<EditPlayerPage> createState() => _EditPlayerPageState();
}

class _EditPlayerPageState extends State<EditPlayerPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _numberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late List<PlayerPosition> _selectedPositions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.player.firstName);
    _lastNameController = TextEditingController(
      text: widget.player.lastName ?? '',
    );
    _numberController = TextEditingController(
      text: widget.player.number?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: widget.player.phone ?? '');
    _emailController = TextEditingController(text: widget.player.email ?? '');
    _selectedPositions = List<PlayerPosition>.from(
      widget.player.positions ?? const [],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _positionLabel(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.portero:
        return 'Portero';
      case PlayerPosition.central:
        return 'Central';
      case PlayerPosition.centralDerecho:
        return 'Central derecho';
      case PlayerPosition.centralIzquierdo:
        return 'Central izquierdo';
      case PlayerPosition.lateralIzquierdo:
        return 'Lateral izquierdo';
      case PlayerPosition.lateralDerecho:
        return 'Lateral derecho';
      case PlayerPosition.mediocentro:
        return 'Mediocentro';
      case PlayerPosition.mediocentroDerecho:
        return 'Mediocentro derecho';
      case PlayerPosition.mediocentroIzquierdo:
        return 'Mediocentro izquierdo';
      case PlayerPosition.mediocentroDefensivo:
        return 'Mediocentro defensivo';
      case PlayerPosition.mediocentroOfensivo:
        return 'Mediocentro ofensivo';
      case PlayerPosition.extremoDerecho:
        return 'Extremo derecho';
      case PlayerPosition.extremoIzquierdo:
        return 'Extremo izquierdo';
      case PlayerPosition.interiorDerecho:
        return 'Interior derecho';
      case PlayerPosition.interiorIzquierdo:
        return 'Interior izquierdo';
      case PlayerPosition.pivote:
        return 'Pivote';
      case PlayerPosition.delanteroCentro:
        return 'Delantero centro';
      case PlayerPosition.mediapunta:
        return 'Mediapunta';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final numberText = _numberController.text.trim();
    final number = numberText.isEmpty ? null : int.tryParse(numberText);

    setState(() {
      _isLoading = true;
    });

    final updatedPlayer = Player(
      id: widget.player.id,
      teamId: widget.player.teamId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      number: number,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      positions: _selectedPositions.isEmpty
          ? null
          : List.of(_selectedPositions),
      stats: widget.player.stats,
    );

    final result = await widget.updatePlayerUseCase(
      updatedPlayer,
      widget.currentUser,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jugador actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar jugador'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Editar jugador de ${widget.team.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Introduce el nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dorsal (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isNotEmpty && !text.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Posiciones',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PlayerPosition>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar posición',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: null,
                    items: PlayerPosition.values
                        .map(
                          (p) => DropdownMenuItem<PlayerPosition>(
                            value: p,
                            child: Text(_positionLabel(p)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      if (_selectedPositions.contains(value)) return;
                      setState(() {
                        _selectedPositions.add(value);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final pos in _selectedPositions)
                        Chip(
                          label: Text(_positionLabel(pos)),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              _selectedPositions.remove(pos);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'GUARDAR CAMBIOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
