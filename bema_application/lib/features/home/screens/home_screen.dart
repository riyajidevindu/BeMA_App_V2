import 'dart:ui';
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/features/daily_suggestions/data/services/task_service.dart';
import 'package:bema_application/features/workout_plan/data/services/workout_service.dart';
import 'package:bema_application/features/home/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String greetingMessage = 'Good Day'; // Default greeting
  String formattedDate = ""; // To hold the formatted date
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Task and Workout stats
  final TaskService _taskService = TaskService();
  final WorkoutService _workoutService = WorkoutService();
  int _totalTasks = 0;
  int _completedTasks = 0;
  bool _hasTasks = false;
  bool _isLoadingTasks = true;

  int _totalWorkouts = 0;
  int _completedWorkouts = 0;
  bool _hasWorkouts = false;
  bool _isLoadingWorkouts = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/tasks.png'), context);
    precacheImage(const AssetImage('assets/relax.png'), context);
    precacheImage(const AssetImage('assets/score.png'), context);
  }

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
    _setGreetingMessage(); // Set the appropriate greeting message
    _setFormattedDate(); // Set the formatted date
    _animationController.forward();
    _loadTasksAndWorkouts(); // Load task and workout stats
  }

  /// Load tasks and workouts statistics
  Future<void> _loadTasksAndWorkouts() async {
    await Future.wait([
      _loadTaskStats(),
      _loadWorkoutStats(),
    ]);
  }

  /// Load task statistics
  Future<void> _loadTaskStats() async {
    try {
      setState(() => _isLoadingTasks = true);

      final tasks = await _taskService.fetchUserTasks([]);

      if (tasks.isNotEmpty) {
        setState(() {
          _hasTasks = true;
          _totalTasks = tasks.length;
          _completedTasks = tasks.where((task) => task.completed).length;
        });
      } else {
        setState(() {
          _hasTasks = false;
        });
      }
    } catch (e) {
      print("Error loading tasks: $e");
      setState(() => _hasTasks = false);
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }

  /// Load workout statistics
  Future<void> _loadWorkoutStats() async {
    try {
      setState(() => _isLoadingWorkouts = true);

      final workouts = await _workoutService.fetchUserWorkoutPlans([]);

      if (workouts.isNotEmpty) {
        setState(() {
          _hasWorkouts = true;
          _totalWorkouts = workouts.length;
          _completedWorkouts =
              workouts.where((workout) => workout.completed).length;
        });
      } else {
        setState(() {
          _hasWorkouts = false;
        });
      }
    } catch (e) {
      print("Error loading workouts: $e");
      setState(() => _hasWorkouts = false);
    } finally {
      setState(() => _isLoadingWorkouts = false);
    }
  }

  /// Sets the greeting message based on the current time
  void _setGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greetingMessage = 'Good Morning';
    } else if (hour < 17) {
      greetingMessage = 'Good Afternoon';
    } else if (hour < 21) {
      greetingMessage = 'Good Evening';
    } else {
      greetingMessage = 'Good Night';
    }
  }

  /// Sets the formatted date based on the current date
  void _setFormattedDate() {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daySuffix = _getDaySuffix(
        dayOfMonth); // Get the correct day suffix (e.g., 1st, 2nd)
    final formattedDay = DateFormat('EEEE')
        .format(now); // Get the day of the week (e.g., Monday)

    setState(() {
      formattedDate = "$dayOfMonth$daySuffix $formattedDay";
    });
  }

  /// Helper function to determine the correct suffix for the day
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildLoadingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.7),
              ),
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final userName = authProvider.user?.name ?? 'User';
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomAppBar(), // Custom AppBar from previous screen
        automaticallyImplyLeading: false, // Remove the back arrow
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(0.1),
                      alignment: FractionalOffset.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(
                                16.0), // Padding inside the box
                            margin: const EdgeInsets.only(
                                bottom: 20.0,
                                top: 20), // Space around the box if needed
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AnimatedTextKit(
                                  key: ValueKey<String>(userName),
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      "$greetingMessage, $userName!",
                                      textStyle: const TextStyle(
                                        fontSize: 22,
                                        color: Color.fromARGB(255, 3, 112, 3),
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Color.fromARGB(
                                                255, 235, 226, 132),
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                      speed: const Duration(milliseconds: 100),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  isRepeatingAnimation: false,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formattedDate, // Dynamically set date here
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(179, 5, 19, 215),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Section - Tasks and Workouts
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Title
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, bottom: 12),
                                  child: Text(
                                    'Today\'s Overview',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: primaryColor.withOpacity(0.5),
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Summary Cards Row
                                Row(
                                  children: [
                                    // Tasks Summary Card
                                    Expanded(
                                      child: _isLoadingTasks
                                          ? _buildLoadingCard()
                                          : _hasTasks
                                              ? SummaryCard(
                                                  icon: Icons
                                                      .check_circle_outline,
                                                  title: 'Daily Tasks',
                                                  mainText:
                                                      '$_completedTasks/$_totalTasks',
                                                  subText: 'Completed today',
                                                  primaryColor:
                                                      const Color(0xFF4CAF50),
                                                  secondaryColor:
                                                      const Color(0xFF81C784),
                                                  onTap: () {
                                                    context.push(
                                                      '/${RouteNames.bottomNavigationBarScreen}',
                                                      extra: 1,
                                                    );
                                                  },
                                                )
                                              : SummaryCard(
                                                  icon:
                                                      Icons.assignment_outlined,
                                                  title: 'Daily Tasks',
                                                  mainText: 'No tasks yet',
                                                  subText: '',
                                                  primaryColor:
                                                      const Color(0xFF4CAF50),
                                                  secondaryColor:
                                                      const Color(0xFF81C784),
                                                  showGetButton: true,
                                                  buttonText: 'Get Tasks',
                                                  onTap: () {
                                                    context.push(
                                                      '/${RouteNames.bottomNavigationBarScreen}',
                                                      extra: 1,
                                                    );
                                                  },
                                                ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Workouts Summary Card
                                    Expanded(
                                      child: _isLoadingWorkouts
                                          ? _buildLoadingCard()
                                          : _hasWorkouts
                                              ? SummaryCard(
                                                  icon: Icons.fitness_center,
                                                  title: 'Workouts',
                                                  mainText:
                                                      '$_completedWorkouts/$_totalWorkouts',
                                                  subText: 'Exercises done',
                                                  primaryColor:
                                                      const Color(0xFFFF9800),
                                                  secondaryColor:
                                                      const Color(0xFFFFB74D),
                                                  onTap: () {
                                                    context.push(
                                                      '/${RouteNames.bottomNavigationBarScreen}',
                                                      extra: 1,
                                                    );
                                                  },
                                                )
                                              : SummaryCard(
                                                  icon: Icons.fitness_center,
                                                  title: 'Workouts',
                                                  mainText: 'No plan yet',
                                                  subText: '',
                                                  primaryColor:
                                                      const Color(0xFFFF9800),
                                                  secondaryColor:
                                                      const Color(0xFFFFB74D),
                                                  showGetButton: true,
                                                  buttonText: 'Get Plan',
                                                  onTap: () {
                                                    context.push(
                                                      '/${RouteNames.bottomNavigationBarScreen}',
                                                      extra: 1,
                                                    );
                                                  },
                                                ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: primaryColor.withOpacity(0.5),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Three tiles in one row
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCompactCard(
                                    avatar: const CircleAvatar(
                                      radius: 22,
                                      backgroundImage:
                                          AssetImage('assets/tasks.png'),
                                    ),
                                    title: "Daily Task",
                                    subtitle: "Health Guide",
                                    color: Colors.lightBlueAccent,
                                    onTap: () {
                                      context.push(
                                          '/${RouteNames.bottomNavigationBarScreen}',
                                          extra: 1);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildCompactCard(
                                    avatar: const CircleAvatar(
                                      radius: 22,
                                      backgroundImage:
                                          AssetImage('assets/relax.png'),
                                    ),
                                    title: "Relax",
                                    subtitle: "Mind & Body",
                                    color: Colors.orange,
                                    onTap: () {
                                      context.push(
                                          '/${RouteNames.bottomNavigationBarScreen}',
                                          extra: 2);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildCompactCard(
                                    avatar: const CircleAvatar(
                                      radius: 22,
                                      backgroundImage:
                                          AssetImage('assets/score.png'),
                                    ),
                                    title: "Points",
                                    subtitle: "Your Progress",
                                    color: Colors.lightBlue,
                                    onTap: () {
                                      context.push(
                                          '/${RouteNames.bottomNavigationBarScreen}',
                                          extra: 3);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactCard({
    required Widget avatar,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 105, // Slightly reduced width
            constraints: const BoxConstraints(minHeight: 135, maxWidth: 125),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar with background
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: avatar,
                  ),
                  const SizedBox(height: 6),
                  // Title - with proper constraints
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black45,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle - with proper constraints
                  Flexible(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
