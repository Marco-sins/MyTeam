import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tfg1/data/repositories/team_repository.dart';
import 'package:tfg1/domain/entities/team.dart';
// Importa tu repositorio y modelos

void main() async {
  // 1. Asegurar que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Cargar variables de entorno (.env)
  await dotenv.load(fileName: ".env");

  // 3. Inicializar Supabase (Esto crea el Singleton)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 4. Instanciar el repositorio con el CLIENTE REAL
  // Supabase.instance.client es el que se conecta a internet
  TeamRepository userRepository = TeamRepository(Supabase.instance.client);

  runApp(MyApp(userRepository: userRepository));
}

class MyApp extends StatelessWidget {
  final TeamRepository userRepository;

  const MyApp({super.key, required this.userRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Supabase Real Insert')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // 5. ¡INSERTAR DE VERDAD!
              try {
                final result = await userRepository.addTeam(
                  Team(
                    name: 'Equipo de Prueba',
                    category: 'Sénior',
                    logoUrl: '',
                  ),
                );
                print(
                  '¡Insertado con éxito! Revisa tu Dashboard de Supabase. \n$result',
                );
              } catch (e) {
                print('Error al insertar: $e');
              }
            },
            child: const Text('Insertar en Base de Datos'),
          ),
        ),
      ),
    );
  }
}
