import 'package:flutter/material.dart';

// ── Colores del nuevo diseño (fondo blanco, tarjetas oscuras) ───────────────
const kPrimary      = Color(0xFF4ECDC4); // Teal acento
const kBackground   = Color(0xFFFFFFFF); // Fondo blanco
const kSurface      = Color(0xFF1C1C1E); // Fondo de tarjetas oscuras
const kCard         = Color(0xFF1C1C1E); // Tarjetas
const kCardElevated = Color(0xFF232325); // Ligeramente más claro
const kCardDark2    = Color(0xFF2C2C2E); // Inputs, sliders
const kDivider      = Color(0xFF2C2C2E); // Divisor

// Textos (legacy) - usados en toda la app
const kText         = Color(0xFF1C1C1E); // Texto principal (sobre fondo blanco)
const kTextSub      = Color(0xFF6E6E73); // Texto secundario (gris medio)
const kTextMuted    = Color(0xFFAEAEB2); // Texto muy claro / deshabilitado

// Textos específicos para tarjetas oscuras (por si se usan directamente)
const kTextOnCard   = Color(0xFFFFFFFF); // Blanco sobre tarjetas
const kTextSubOnCard= Color(0xFFA1A1A6); // Gris claro sobre tarjetas
const kTextMutedOnCard= Color(0xFF6E6E73); // Muted sobre tarjetas

// ── Constantes legacy adicionales (para compatibilidad total) ───────────────
const kPrimaryLight = Color(0xFF2C2C2E); // Fondo de inputs (gris oscuro)
const kCardDark     = Color(0xFF232325); // Versión más clara de tarjeta
const kShadow       = Color(0x1A000000); // Sombra suave (10% negro)

// ── Sombras (opcional, si se usan directamente) ─────────────────────────────
const kNeumorphicShadows = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x0DFFFFFF), blurRadius: 4, offset: Offset(0, 2), spreadRadius: -1),
];