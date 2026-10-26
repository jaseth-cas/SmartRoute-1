import 'package:flutter/material.dart';

/// Paleta de colores Neumórfica & Minimalista para SmartRoute
/// Basada en la guía de diseño Quivox y la paleta de 5 tonos:
/// - #B80C09 (Carmesí Profundo / Alerta / Inasistencias)
/// - #0B4F6C (Azul Petróleo Profundo / Marca Principal)
/// - #01BAEF` (Cian Vibrante / Acentos Eléctricos / Activo)
/// - #FBFBFF (Ghost White / Base Neumórfica Suave)
/// - #040F16 (Negro Obsidiana / Texto Alto Contraste / Pastillas Oscuras)
class SmartColors {
  // Paleta Oficial
  static const Color primaryCrimson = Color(0xFFB80C09); // #B80C09
  static const Color deepBlue = Color(0xFF0B4F6C);       // #0B4F6C
  static const Color deepPetrol = deepBlue;              // Alias de paleta
  static const Color vibrantCyan = Color(0xFF01BAEF);     // #01BAEF
  static const Color electricCyan = vibrantCyan;         // Alias de paleta
  static const Color ghostWhite = Color(0xFFFBFBFF);      // #FBFBFF
  static const Color deepBlack = Color(0xFF040F16);       // #040F16

  // Tonos Neumórficos derivados para relieve (Luz y Sombra)
  static const Color neuBackground = Color(0xFFF0F3F8);   // Fondo base suave para que resalte la luz
  static const Color neuSurface = Color(0xFFFBFBFF);      // Superficie de tarjetas
  static const Color neuSurfaceDark = Color(0xFF040F16);  // Pastillas y botones negros de alto contraste
  static const Color neuLightShadow = Color(0xFFFFFFFF);  // Reflejo de luz superior izquierdo
  static const Color neuDarkShadow = Color(0x1A0B4F6C);   // Sombra suave inferior derecha
  static const Color neuInset = Color(0xFFE9EDF5);        // Fondo hundido para inputs y medidores
  static const Color neuBorder = Color(0xFFE2E8F0);       // Borde técnico sutil
  static const Color neuDivider = Color(0xFFE6EBF2);

  // Compatibilidad semántica con el resto del proyecto
  static const Color smartBlue = deepBlue;
  static const Color smartDarkBlue = Color(0xFF073347);
  static const Color smartLightBlue = Color(0xFFE5F7FD); // Tint suave con cian
  
  static const Color smartGreen = Color(0xFF00A896);    // Verde azulado armonizado
  static const Color smartLightGreen = Color(0xFFE6F8F5);
  
  static const Color smartBackground = neuBackground;
  static const Color smartSurface = neuSurface;
  
  static const Color smartText = deepBlack;
  static const Color smartGray = Color(0xFF6B7F91);
  static const Color smartLightGray = Color(0xFFDFE6EE);
  static const Color smartBorder = neuBorder;
  
  static const Color smartRed = primaryCrimson;
  static const Color smartLightRed = Color(0xFFFDE8E8);
  
  static const Color smartYellow = Color(0xFFF59E0B);
  static const Color smartLightYellow = Color(0xFFFEF3C7);

  // Compatibilidad Kotlin / Material
  static const Color purple80 = Color(0xFFD0BCFF);
  static const Color purpleGrey80 = Color(0xFFCCC2DC);
  static const Color pink80 = Color(0xFFEFB8C8);
  static const Color purple40 = Color(0xFF6650a4);
  static const Color purpleGrey40 = Color(0xFF625b71);
  static const Color pink40 = Color(0xFF7d5260);
}
