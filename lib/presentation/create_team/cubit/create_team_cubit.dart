import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:football_manager/domain/usecase/team/create_team_use_case.dart';
import 'package:football_manager/domain/usecase/team/upload_team_logo_use_case.dart';

import 'create_team_state.dart';

class CreateTeamCubit extends Cubit<CreateTeamState> {
  final CreateTeamUseCase createTeamUseCase;
  final UploadTeamLogoUseCase uploadTeamLogoUseCase;

  CreateTeamCubit(this.createTeamUseCase, this.uploadTeamLogoUseCase)
    : super(CreateTeamInitial());

  Future<void> createTeam(
    String teamName,
    String category, {
    Uint8List? logoBytes,
    String? logoFileName,
  }) async {
    emit(CreateTeamLoading());

    String? logoUrl;
    if (logoBytes != null && logoFileName != null) {
      final uploadResult = await uploadTeamLogoUseCase(logoBytes, logoFileName);
      if (isClosed) return;
      var uploadFailed = false;
      uploadResult.fold(
        (failure) {
          uploadFailed = true;
          emit(CreateTeamError(failure.message));
        },
        (url) {
          logoUrl = url;
        },
      );
      if (uploadFailed) return;
    }

    final result = await createTeamUseCase(
      Team(name: teamName, category: category, logoUrl: logoUrl),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(CreateTeamError(failure.message)),
      (_) => emit(CreateTeamSuccess()),
    );
  }
}
