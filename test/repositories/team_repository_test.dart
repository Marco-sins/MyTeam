import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    // Inyectamos el cliente "trucado" en el repositorio
    datasource = TeamRemoteDatasource(supabase);
    repository = TeamRepository(datasource);
  });

  test(
    'Debería retornar Right(unit) cuando el equipo se inserta correctamente',
    () async {
      debugPrint("Iniciando test de inserción de equipo...");
      // Usamos el timestamp para que el nombre sea siempre único
      final team = Team(name: 'Team 1', category: 'Sénior', logoUrl: '');
      debugPrint("Intentando agregar el equipo: ${team.name}");

      final result = await repository.createTeam(team);

      debugPrint("Insetado el equipo, resultado: $result");

      // Verificamos que sea Right
      expect(result.isRight(), true);
    },
  );

  test(
    'Debería retornar Left(Failure) con mensaje cariñoso cuando el nombre ya existe',
    () async {
      // 1. Preparamos un nombre fijo para forzar el error
      const duplicateName = 'F.C. Repetido';
      final team = Team(name: duplicateName, category: 'Sénior');

      // 2. Insertamos la primera vez (puede que ya exista, no nos importa el resultado)
      await repository.createTeam(team);

      // 3. Intentamos insertar de nuevo el mismo nombre
      final result = await repository.createTeam(team);

      // 4. Verificamos que sea Left y contenga nuestro mensaje del Handler
      expect(result.isLeft(), true);

      result.fold((failure) {
        // Aquí compruebas que tu mensaje "cariñoso" está funcionando
        if (kDebugMode) {
          print('Mensaje capturado: ${failure.message}');
        }
        expect(failure.message, contains('ya existe'));
      }, (_) => fail('Debería haber fallado por nombre duplicado'));
    },
  );
}
