enum ExerciseType {
  squats,
  pushups,
  plank,
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final String thumbnailAsset;
  final String? videoUrl; // Local asset path or network URL
  final ExerciseType type;
  final String benefits;
  final String difficulty; // Easy, Medium, Hard

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailAsset,
    this.videoUrl,
    required this.type,
    required this.benefits,
    required this.difficulty,
  });

  // Predefined exercises
  static const Exercise squats = Exercise(
    id: 'squats',
    name: 'Squats',
    description: 'Build lower body strength and improve mobility',
    thumbnailAsset: 'assets/exercises/squats.png',
    videoUrl: 'assets/squat_guide.mp4',
    type: ExerciseType.squats,
    benefits: 'Strengthens legs, glutes, and core muscles',
    difficulty: 'Easy',
  );

  static const Exercise pushups = Exercise(
    id: 'pushups',
    name: 'Push-ups',
    description: 'Upper body strength and core stability',
    thumbnailAsset: 'assets/exercises/pushups.png',
    videoUrl: 'assets/push_up_guide.mp4',
    type: ExerciseType.pushups,
    benefits: 'Builds chest, shoulders, triceps, and core strength',
    difficulty: 'Medium',
  );

  static const Exercise plank = Exercise(
    id: 'plank',
    name: 'Plank',
    description: 'Core endurance and full-body stability',
    thumbnailAsset: 'assets/exercises/plank.png',
    videoUrl: 'assets/plank_guide.mp4',
    type: ExerciseType.plank,
    benefits: 'Strengthens core, improves posture and stability',
    difficulty: 'Easy',
  );

  // List of all available exercises
  static List<Exercise> get allExercises => [squats, pushups, plank];

  static Exercise? getById(String id) {
    try {
      return allExercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }

  static Exercise? getByType(ExerciseType type) {
    try {
      return allExercises.firstWhere((exercise) => exercise.type == type);
    } catch (e) {
      return null;
    }
  }
}
