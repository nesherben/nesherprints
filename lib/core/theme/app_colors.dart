import 'package:flutter/material.dart';

class AppColors {
  // Colores Principales (Brand)
  static const Color primary = Color(0xFF00ADB5); // Un cyan/teal moderno
  static const Color secondary = Color(0xFF393E46); // Gris oscuro
  static const Color background = Color(
    0xFF222831,
  ); // Fondo principal muy oscuro
  static const Color surface = Color(
    0xFF2D333B,
  ); // Fondo para tarjetas/paneles (un poco más claro)
  static const Color border = Color(
    0xFF393E46,
  ); // Para bordes y divisores (gris oscuro)
  // Colores de Texto
  static const Color textMain = Color(0xFFEEEEEE); // Blanco humo
  static const Color textMuted = Color(
    0xFF9E9E9E,
  ); // Gris para texto secundario

  // Colores Semánticos (Para tus Status de Pedidos)
  static const Color statusCompletado = Color(0xFF4CAF50); // Verde
  static const Color statusEnProceso = Color(0xFFFF9800); // Naranja
  static const Color statusReservado = Color(0xFF2196F3); // Azul
  static const Color statusBorrador = Color(0xFF9E9E9E); // Gris
  static const Color statusEnviado = Color(0xFF9C27B0); // Morado
  static const Color statusCancelado = Color(0xFFF44336); // Rojo

  // Colores para alertas de Inventario
  static const Color alertBajoStock = Color(0xFFFF5252); // Rojo brillante
  static const Color stockSaludable = Color(0xFF69F0AE); // Verde menta
}
