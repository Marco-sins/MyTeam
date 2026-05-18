import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/data/datasource/team_remote_datasource.dart';
import 'package:football_manager/data/repositories/team_repository.dart';
import 'package:football_manager/domain/entities/team.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';

void main() async {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient supabase;
  late TeamRemoteDatasource datasource;
  late TeamRepository repository;
  await dotenv.load(fileName: ".env");

  setUp(() {
    mockHttpClient = MockSupabaseHttpClient();
    supabase = SupabaseClient(
      dotenv.env['SUPABASE_URL'] ?? '',
      dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      httpClient: mockHttpClient,
    );
    datasource = TeamRemoteDatasource(supabase);
    repository = TeamRepository(datasource);
  });

  test('Devuelve Right(unit) cuando el equipo se crea correctamente', () async {
    final team = Team(name: 'Team 1', category: 'Sénior', logoUrl: '');

    final result = await repository.createTeam(team);

    expect(result.isRight(), true);
  });

  test(
    'Devuelve Left(Failure) cuando se intenta obtener equipos sin sesión activa',
    () async {
      final result = await repository.getTeams();

      expect(result.isLeft(), true);

      result.fold((failure) {
        expect(failure.message.toLowerCase(), contains('authenticated'));
      }, (_) => fail('Debería haber fallado sin usuario autenticado'));
    },
  );
}
