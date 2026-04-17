import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_player_repository.dart';

/// Elimina del bucket de Supabase una foto si la URL pertenece a nuestro storage.
class DeleteStoredPlayerPhotoUseCase {
  final IPlayerRepository _playerRepository;

  DeleteStoredPlayerPhotoUseCase(this._playerRepository);

  Future<Either<Failure, Unit>> call(String? publicUrl) {
    return _playerRepository.deleteStoredPlayerPhoto(publicUrl);
  }
}
