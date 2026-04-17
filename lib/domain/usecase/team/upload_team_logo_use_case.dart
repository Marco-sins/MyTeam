import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:football_manager/core/errors/failure/failure.dart';
import 'package:football_manager/domain/repositories/i_team_repository.dart';

class UploadTeamLogoUseCase {
  final ITeamRepository _teamRepository;

  UploadTeamLogoUseCase(this._teamRepository);

  Future<Either<Failure, String>> call(Uint8List bytes, String fileName) {
    return _teamRepository.uploadLogo(bytes, fileName);
  }
}
