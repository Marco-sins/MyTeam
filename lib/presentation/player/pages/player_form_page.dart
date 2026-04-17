import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/domain/entities/auth_user.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';
import 'package:football_manager/domain/entities/player.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/player/add_new_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/delete_stored_player_photo_use_case.dart';
import 'package:football_manager/domain/usecase/player/update_player_use_case.dart';
import 'package:football_manager/domain/usecase/player/upload_player_photo_use_case.dart';
import 'package:football_manager/presentation/player/widgets/player_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlayerFormPage extends StatefulWidget {
  final Team team;
  final AuthUser currentUser;
  final AddNewPlayerUseCase? addNewPlayerUseCase;
  final UpdatePlayerUseCase? updatePlayerUseCase;
  final Player? initialPlayer;

  const PlayerFormPage({
    super.key,
    required this.team,
    required this.currentUser,
    this.addNewPlayerUseCase,
    this.updatePlayerUseCase,
    this.initialPlayer,
  });

  bool get isEdit => initialPlayer != null;

  @override
  State<PlayerFormPage> createState() => _PlayerFormPageState();
}

class _PlayerFormPageState extends State<PlayerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _numberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late List<PlayerPosition> _selectedPositions;
  bool _isLoading = false;

  Uint8List? _pickedImageBytes;
  String? _pickedFileName;
  bool _removeExistingPhoto = false;

  @override
  void initState() {
    super.initState();
    final player = widget.initialPlayer;
    _firstNameController = TextEditingController(text: player?.firstName ?? '');
    _lastNameController = TextEditingController(text: player?.lastName ?? '');
    _numberController = TextEditingController(
      text: player?.number?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: player?.phone ?? '');
    _emailController = TextEditingController(text: player?.email ?? '');
    _selectedPositions = List<PlayerPosition>.from(
      player?.positions ?? const [],
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

  Player _previewPlayer() {
    final base = widget.initialPlayer;
    final first = _firstNameController.text.trim().isEmpty
        ? (base?.firstName ?? 'Jugador')
        : _firstNameController.text.trim();
    final lastRaw = _lastNameController.text.trim();
    final last = lastRaw.isEmpty ? base?.lastName : lastRaw;
    final numberText = _numberController.text.trim();
    final number =
        numberText.isEmpty ? base?.number : int.tryParse(numberText);

    return Player(
      id: base?.id ?? 0,
      teamId: base?.teamId ?? widget.team.id,
      firstName: first,
      lastName: last,
      number: number,
      imgUrl: (_pickedImageBytes != null || _removeExistingPhoto)
          ? null
          : base?.imgUrl,
    );
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedFileName = file.name;
      _removeExistingPhoto = false;
    });
  }

  void _clearPhoto() {
    setState(() {
      _pickedImageBytes = null;
      _pickedFileName = null;
      _removeExistingPhoto = true;
    });
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

  Player _playerFromForm({
    required String? imgUrl,
    int? idOverride,
  }) {
    final base = widget.initialPlayer;
    final numberText = _numberController.text.trim();
    final number = numberText.isEmpty ? null : int.tryParse(numberText);

    return Player(
      id: idOverride ?? base?.id ?? 0,
      teamId: base?.teamId ?? widget.team.id,
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
      imgUrl: imgUrl,
      positions: _selectedPositions.isEmpty
          ? null
          : List.of(_selectedPositions),
      stats: base?.stats,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final isEdit = widget.isEdit;
    final base = widget.initialPlayer;
    final uploadPhoto = context.read<UploadPlayerPhotoUseCase>();
    final deleteStoredPhoto = context.read<DeleteStoredPlayerPhotoUseCase>();
    final updatePlayerUseCase =
        widget.updatePlayerUseCase ?? context.read<UpdatePlayerUseCase>();

    String? errorMessage;
    final String? previousUrl = base?.imgUrl;

    if (isEdit) {
      final useCase = widget.updatePlayerUseCase;
      if (useCase == null) {
        errorMessage = 'UpdatePlayerUseCase no proporcionado';
      } else {
        String? targetImgUrl = previousUrl;
        if (_removeExistingPhoto && _pickedImageBytes == null) {
          targetImgUrl = null;
        }

        if (_pickedImageBytes != null) {
          final uploadResult = await uploadPhoto(
            bytes: _pickedImageBytes!,
            fileName: _pickedFileName ?? 'foto.jpg',
            teamId: widget.team.id,
            playerId: base!.id,
          );
          uploadResult.fold(
            (f) => errorMessage = f.message,
            (url) => targetImgUrl = url,
          );
        }

        if (errorMessage == null) {
          final player = _playerFromForm(imgUrl: targetImgUrl);
          final result = await useCase(player, widget.currentUser);
          result.fold((f) => errorMessage = f.message, (_) {});
          if (errorMessage == null &&
              previousUrl != null &&
              previousUrl.isNotEmpty &&
              previousUrl != targetImgUrl) {
            await deleteStoredPhoto(previousUrl);
          }
        }
      }
    } else {
      final useCase =
          widget.addNewPlayerUseCase ?? context.read<AddNewPlayerUseCase>();
      final playerNoPhoto = _playerFromForm(imgUrl: null);
      final createResult = await useCase(playerNoPhoto, widget.currentUser);

      Player? created;
      createResult.fold(
        (f) => errorMessage = f.message,
        (p) => created = p,
      );

      if (errorMessage == null &&
          created != null &&
          _pickedImageBytes != null) {
        final uploadResult = await uploadPhoto(
          bytes: _pickedImageBytes!,
          fileName: _pickedFileName ?? 'foto.jpg',
          teamId: widget.team.id,
          playerId: created!.id,
        );
        String? url;
        uploadResult.fold(
          (f) => errorMessage = f.message,
          (u) => url = u,
        );
        if (errorMessage == null && url != null) {
          final withPhoto = _playerFromForm(imgUrl: url, idOverride: created!.id);
          final updateResult =
              await updatePlayerUseCase(withPhoto, widget.currentUser);
          updateResult.fold((f) => errorMessage = f.message, (_) {});
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit ? 'Jugador actualizado con éxito' : 'Jugador creado con éxito',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;
    final hasPhoto = widget.initialPlayer?.imgUrl != null &&
        widget.initialPlayer!.imgUrl!.trim().isNotEmpty;
    final showClear = _pickedImageBytes != null || (!_removeExistingPhoto && hasPhoto);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? AppLocalizations.of(context)!.screenEditPlayer
              : AppLocalizations.of(context)!.screenAddPlayer,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                          Icon(
                            isEdit ? Icons.edit : Icons.person_add_alt,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEdit
                                  ? 'Editar jugador de ${widget.team.name}'
                                  : 'Nuevo jugador en ${widget.team.name}',
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
                    Center(
                      child: Column(
                        children: [
                          PlayerAvatar(
                            player: _previewPlayer(),
                            radius: 48,
                            previewBytes: _pickedImageBytes,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _pickPhoto,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Elegir foto'),
                              ),
                              if (showClear) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _isLoading ? null : _clearPhoto,
                                  child: const Text('Quitar foto'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _firstNameController,
                      onChanged: (_) => setState(() {}),
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
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Apellidos (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _numberController,
                      onChanged: (_) => setState(() {}),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEdit ? 'GUARDAR CAMBIOS' : 'GUARDAR JUGADOR',
                                style: const TextStyle(
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
      ),
    );
  }
}
