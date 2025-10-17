import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import '../models/exercise.dart';
import '../models/exercise_step.dart';
import 'package:bema_application/routes/route_names.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _exerciseColor {
    switch (widget.exercise.type) {
      case ExerciseType.squats:
        return Colors.blue;
      case ExerciseType.pushups:
        return Colors.orange;
      case ExerciseType.plank:
        return Colors.green;
    }
  }

  IconData get _exerciseIcon {
    switch (widget.exercise.type) {
      case ExerciseType.squats:
        return Icons.fitness_center;
      case ExerciseType.pushups:
        return Icons.self_improvement;
      case ExerciseType.plank:
        return Icons.airline_seat_flat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStepGuide =
        ExerciseGuide.getGuideByExerciseName(widget.exercise.name) != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomAppBar(showBackButton: true),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Exercise Header
                      _buildExerciseHeader(),
                      const SizedBox(height: 30),

                      // Exercise Description
                      _buildDescriptionCard(),
                      const SizedBox(height: 25),

                      // Options Title
                      _buildStrokedText('How would you like to learn?', 20),
                      const SizedBox(height: 20),

                      // Step-by-Step Guide Option
                      if (hasStepGuide) ...[
                        _buildOptionCard(
                          icon: Icons.list_alt,
                          title: 'Step-by-Step Guide',
                          description:
                              'Learn with detailed images and instructions for each step',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.stepByStepGuideScreen,
                              arguments: widget.exercise,
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                      ],

                      // Video Guide Option
                      if (widget.exercise.videoUrl != null) ...[
                        _buildOptionCard(
                          icon: Icons.play_circle_filled,
                          title: 'Video Guide',
                          description:
                              'Watch a demonstration video showing proper form',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.videoGuideScreen,
                              arguments: widget.exercise,
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                      ],

                      // Start AI Coach Option
                      _buildOptionCard(
                        icon: Icons.camera_alt,
                        title: 'Start AI Coach',
                        description:
                            'Get real-time feedback with AI-powered pose detection',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.poseCoachScreen,
                            arguments: widget.exercise,
                          );
                        },
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth > 600 ? 100.0 : 80.0;
    final padding = screenWidth > 600 ? 24.0 : 16.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _exerciseColor.withOpacity(0.4),
                _exerciseColor.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Exercise Icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: _exerciseColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _exerciseIcon,
                  size: iconSize * 0.5,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenWidth > 600 ? 20 : 15),

              // Exercise Name
              _buildStrokedText(
                  widget.exercise.name, screenWidth > 600 ? 28 : 24),
              SizedBox(height: screenWidth > 600 ? 10 : 8),

              // Difficulty Badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 16 : 12,
                    vertical: screenWidth > 600 ? 8 : 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(widget.exercise.difficulty),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDifficultyIcon(widget.exercise.difficulty),
                      size: screenWidth > 600 ? 18 : 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.exercise.difficulty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _exerciseColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _exerciseColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStrokedText('About This Exercise', 18),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                widget.exercise.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.exercise.benefits,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth > 600 ? 65.0 : 55.0;
    final padding = screenWidth > 600 ? 20.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: isHighlighted
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.6),
                        color.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHighlighted
                    ? color.withOpacity(0.8)
                    : Colors.white.withOpacity(0.4),
                width: isHighlighted ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHighlighted
                      ? color.withOpacity(0.4)
                      : Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.6),
                        color.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: iconSize * 0.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: screenWidth > 600 ? 16 : 12),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 17 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 13 : 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: screenWidth > 600 ? 20 : 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.trending_up;
      case 'hard':
        return Icons.whatshot;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildStrokedText(String text, double fontSize) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
