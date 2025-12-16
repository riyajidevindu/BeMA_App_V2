import '../models/exercise.dart';
import 'exercise_logic.dart';
import 'squats_logic.dart';
import 'pushups_logic.dart';

class ExerciseLogicFactory {
  static ExerciseLogic createLogic(ExerciseType type) {
    switch (type) {
      case ExerciseType.squats:
        return SquatsLogic();
      case ExerciseType.pushups:
        return PushupsLogic();
      case ExerciseType.plank:
        // TODO: Implement PlankLogic when ready
        return SquatsLogic(); // Temporary fallback
    }
  }

  static ExerciseLogic? createLogicFromId(String exerciseId) {
    final exercise = Exercise.getById(exerciseId);
    if (exercise == null) return null;
    return createLogic(exercise.type);
  }
}
