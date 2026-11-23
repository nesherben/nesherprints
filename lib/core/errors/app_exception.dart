/// Error esperable cuya [message] se puede mostrar tal cual al usuario
/// (regla de negocio incumplida, dato que ya no existe…).
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
