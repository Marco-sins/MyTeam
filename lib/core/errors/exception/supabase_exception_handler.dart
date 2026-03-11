import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg1/core/errors/failure/failure.dart';
import 'package:tfg1/core/errors/failure/server_failure.dart';
import 'package:tfg1/core/errors/failure/validation_failure.dart';

class SupabaseExceptionHandler {
  static Failure handleException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Duplicidad
        return ValidationFailure('Este registro ya existe. Intenta con un nombre o valor diferente.');
      case '23503': // Violación de clave foránea
        return ValidationFailure('No se puede realizar esta acción porque otros datos dependen de este registro.');
      case '23502': // Falta campo NOT NULL
        return ValidationFailure('Faltan datos obligatorios. Por favor, rellena todos los campos.');
      case '22P02': // Tipo de dato incorrecto 
        return ValidationFailure('El formato de algún dato no es válido. Revisa los números y fechas.');
      case '22001': // Texto demasiado largo
        return ValidationFailure('Has escrito demasiado texto en uno de los campos.');
      case '23514': // Check constraint violada
        return ValidationFailure('Los datos introducidos no cumplen con las reglas del equipo.');
      default:
        return ServerFailure('Algo ha salido mal en el servidor. Por favor, inténtalo más tarde.');
    }
  }
}