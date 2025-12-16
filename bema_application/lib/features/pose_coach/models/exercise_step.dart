class ExerciseStep {
  final int stepNumber;
  final String title;
  final String description;
  final String imageAsset;
  final List<String> keyPoints;

  const ExerciseStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.keyPoints = const [],
  });
}

class ExerciseGuide {
  final String exerciseName;
  final String overview;
  final List<ExerciseStep> steps;
  final List<String> commonMistakes;
  final List<String> safetyTips;

  const ExerciseGuide({
    required this.exerciseName,
    required this.overview,
    required this.steps,
    this.commonMistakes = const [],
    this.safetyTips = const [],
  });

  // Predefined guide for Squats
  static final ExerciseGuide squatsGuide = ExerciseGuide(
    exerciseName: 'Squats',
    overview:
        'Squats are a fundamental compound exercise that targets your lower body, primarily working your quadriceps, hamstrings, and glutes. When performed correctly, squats also engage your core and improve overall stability.',
    steps: [
      ExerciseStep(
        stepNumber: 1,
        title: 'Starting Position',
        description:
            'Stand tall with your feet shoulder-width apart, toes slightly turned out, and arms relaxed by your sides.',
        imageAsset: 'assets/squat_step_01.png',
        keyPoints: [
          'Feet shoulder-width apart',
          'Toes slightly turned out',
          'Arms relaxed by sides',
          'Stand tall and straight',
        ],
      ),
      ExerciseStep(
        stepNumber: 2,
        title: 'Preparation (Engage Core)',
        description:
            'Tighten your core and keep your chest up. Slowly begin to bend your knees as if you\'re about to sit down.',
        imageAsset: 'assets/squat_step_02.png',
        keyPoints: [
          'Engage your core muscles',
          'Keep chest lifted',
          'Begin bending knees',
          'Imagine sitting down',
        ],
      ),
      ExerciseStep(
        stepNumber: 3,
        title: 'Lowering Phase (Half Squat)',
        description:
            'Lower your hips halfway down. Keep your back straight, knees over your toes, and heels flat on the ground.',
        imageAsset: 'assets/squat_step_03.png',
        keyPoints: [
          'Hips lower halfway',
          'Back stays straight',
          'Knees over toes',
          'Heels flat on ground',
        ],
      ),
      ExerciseStep(
        stepNumber: 4,
        title: 'Bottom Position (Full Squat)',
        description:
            'Bend your knees until your thighs are parallel to the floor. Keep your chest lifted and your weight on your heels.',
        imageAsset: 'assets/squat_step_04.png',
        keyPoints: [
          'Thighs parallel to floor',
          'Chest remains lifted',
          'Weight on heels',
          'Maintain balance',
        ],
      ),
      ExerciseStep(
        stepNumber: 5,
        title: 'Upward Phase (Return to Start)',
        description:
            'Push through your heels to stand back up, straightening your legs and returning to the starting position.',
        imageAsset: 'assets/squat_step_01.png',
        keyPoints: [
          'Push through heels',
          'Straighten legs',
          'Return to start',
          'Controlled movement',
        ],
      ),
    ],
    commonMistakes: [
      'Knees caving inward - Keep knees aligned with toes',
      'Leaning too far forward - Keep chest up and back straight',
      'Not going deep enough - Aim for thighs parallel to floor',
      'Lifting heels off ground - Keep weight on heels',
      'Rounding the back - Maintain neutral spine throughout',
    ],
    safetyTips: [
      'Warm up properly before starting',
      'Start with bodyweight before adding resistance',
      'Listen to your body and stop if you feel pain',
      'Maintain proper breathing (inhale down, exhale up)',
      'Focus on form over speed or quantity',
    ],
  );

  // Predefined guide for Push-ups
  static final ExerciseGuide pushupsGuide = ExerciseGuide(
    exerciseName: 'Push-ups',
    overview:
        'Push-ups are a classic upper body exercise that primarily targets your chest, shoulders, and triceps. They also engage your core and help build functional strength for everyday activities.',
    steps: [
      ExerciseStep(
        stepNumber: 1,
        title: 'Starting Position (High Plank)',
        description:
            'Start in a high plank with your arms straight, hands under your shoulders, and your body forming a straight line from head to heels.',
        imageAsset: 'assets/logo.png', // Using placeholder as no push-up images
        keyPoints: [
          'Arms straight and strong',
          'Hands under shoulders',
          'Body in straight line',
          'Core engaged',
        ],
      ),
      ExerciseStep(
        stepNumber: 2,
        title: 'Lowering Phase (Halfway Down)',
        description:
            'Bend your elbows and lower your chest halfway toward the mat. Keep your hands firmly on the floor and your body straight.',
        imageAsset: 'assets/logo.png',
        keyPoints: [
          'Elbows bend gradually',
          'Chest lowers halfway',
          'Hands firm on floor',
          'Body stays straight',
        ],
      ),
      ExerciseStep(
        stepNumber: 3,
        title: 'Bottom Position (Fully Lowered)',
        description:
            'Lower yourself until your chest is just above the mat. Keep your elbows bent and your body straight from head to heels.',
        imageAsset: 'assets/logo.png',
        keyPoints: [
          'Chest near the mat',
          'Elbows bent at 90°',
          'Body remains straight',
          'Don\'t let hips sag',
        ],
      ),
      ExerciseStep(
        stepNumber: 4,
        title: 'Upward Phase (Return to Start)',
        description:
            'Push through your palms to straighten your arms and lift your body back up to the plank position. Keep your core tight and your back straight.',
        imageAsset: 'assets/logo.png',
        keyPoints: [
          'Push through palms',
          'Straighten arms fully',
          'Core stays tight',
          'Return to plank',
        ],
      ),
    ],
    commonMistakes: [
      'Hips sagging - Keep core engaged and body straight',
      'Flaring elbows too wide - Keep elbows at 45° angle',
      'Not going low enough - Lower until chest nearly touches ground',
      'Head dropping - Keep neck neutral and aligned',
      'Rushing reps - Focus on controlled movement',
    ],
    safetyTips: [
      'Start with knee push-ups if needed',
      'Keep your core engaged throughout',
      'Breathe steadily (inhale down, exhale up)',
      'Stop if you feel shoulder pain',
      'Maintain proper form over quantity',
    ],
  );

  // Predefined guide for Plank
  static final ExerciseGuide plankGuide = ExerciseGuide(
    exerciseName: 'Plank',
    overview:
        'The plank is an isometric core exercise that builds strength and endurance throughout your entire body. It targets your abs, back, shoulders, and glutes while improving posture and stability.',
    steps: [
      ExerciseStep(
        stepNumber: 1,
        title: 'Starting Position (Preparation)',
        description:
            'Start on your hands and knees. Place your hands directly under your shoulders and extend your legs back one at a time. Keep your toes on the mat.',
        imageAsset: 'assets/plank_step_01.png',
        keyPoints: [
          'Hands under shoulders',
          'Start on hands and knees',
          'Extend legs back',
          'Toes on the mat',
        ],
      ),
      ExerciseStep(
        stepNumber: 2,
        title: 'Full Plank Hold (Active Position)',
        description:
            'Straighten your body from head to heels. Engage your core, tighten your glutes, and keep your neck neutral. Your body should form a straight line.',
        imageAsset: 'assets/plank_step_02.png',
        keyPoints: [
          'Body in straight line',
          'Core fully engaged',
          'Glutes tightened',
          'Neck stays neutral',
        ],
      ),
      ExerciseStep(
        stepNumber: 3,
        title: 'Maintain and Breathe (Sustain the Hold)',
        description:
            'Hold this position steadily. Keep your body firm, breathe evenly, and focus on not letting your hips sag or rise.',
        imageAsset: 'assets/plank_step_03.png',
        keyPoints: [
          'Hold position steady',
          'Breathe evenly',
          'Don\'t let hips sag',
          'Don\'t raise hips up',
        ],
      ),
      ExerciseStep(
        stepNumber: 4,
        title: 'Rest Position (Release)',
        description:
            'Gently lower your knees to the mat and sit back into a relaxed position. Take a few deep breaths to recover before the next round.',
        imageAsset: 'assets/plank_step_04.png',
        keyPoints: [
          'Lower knees gently',
          'Sit back to rest',
          'Take deep breaths',
          'Recover fully',
        ],
      ),
    ],
    commonMistakes: [
      'Hips sagging down - Engage core and lift hips to neutral',
      'Hips too high - Lower hips to create straight line',
      'Looking up or down - Keep neck neutral, look at floor',
      'Holding breath - Breathe steadily throughout',
      'Shoulders hunched - Keep shoulders away from ears',
    ],
    safetyTips: [
      'Start with shorter hold times and build up',
      'Keep breathing - never hold your breath',
      'Listen to your body and rest when needed',
      'Try forearm plank if wrists hurt',
      'Focus on quality over duration',
    ],
  );

  static ExerciseGuide? getGuideByExerciseName(String name) {
    switch (name.toLowerCase()) {
      case 'squats':
        return squatsGuide;
      case 'push-ups':
      case 'pushups':
        return pushupsGuide;
      case 'plank':
        return plankGuide;
      default:
        return null;
    }
  }
}
