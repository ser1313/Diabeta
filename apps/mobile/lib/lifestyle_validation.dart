String? validateMealEntry(String name, String rawCarbs) {
  final mealName = name.trim();
  if (mealName.isEmpty) return 'Introduce el nombre de la comida.';
  if (mealName.length > 200) return 'El nombre de la comida no puede superar 200 caracteres.';
  final normalizedCarbs = rawCarbs.trim().replaceAll(',', '.');
  if (normalizedCarbs.isEmpty) return null;
  final carbs = double.tryParse(normalizedCarbs);
  if (carbs == null || !carbs.isFinite || carbs < 0 || carbs > 1000) {
    return 'Los carbohidratos deben estar entre 0 y 1000 g.';
  }
  return null;
}

String? validateActivityEntry(String type, String rawMinutes) {
  final activityType = type.trim();
  if (activityType.isEmpty) return 'Introduce el tipo de actividad.';
  if (activityType.length > 100) return 'El tipo de actividad no puede superar 100 caracteres.';
  final duration = int.tryParse(rawMinutes.trim());
  if (duration == null || duration < 1 || duration > 1440) {
    return 'Los minutos deben estar entre 1 y 1440.';
  }
  return null;
}
