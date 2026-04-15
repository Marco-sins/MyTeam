import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/i_repositories/i_player_repository.dart';

class UploadPlayerPhotoUseCase {
  final IPlayerRepository _playerRepository;

  UploadPlayerPhotoUseCase(this._playerRepository);

  Future<Either<Failure, String>> call({
    required Uint8List bytes,
    required String fileName,
    required int teamId,
    int? playerId,
  }) {
    return _playerRepository.uploadPlayerPhoto(
      bytes: bytes,
      fileName: fileName,
      teamId: teamId,
      playerId: playerId,
    );
  }
}
