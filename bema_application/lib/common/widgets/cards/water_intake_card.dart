import 'package:flutter/material.dart';

class WaterIntakeCard extends StatefulWidget {
  final double totalWaterGoal; // Total water intake goal in milliliters
  final double currentProgress; // Current water intake progress
  final Function(double) onProgressUpdate; // Updated to pass the drink amount

  const WaterIntakeCard({
    Key? key,
    required this.totalWaterGoal,
    required this.currentProgress,
    required this.onProgressUpdate, // Accept the callback with drink amount
  }) : super(key: key);

  @override
  _WaterIntakeCardState createState() => _WaterIntakeCardState();
}

class _WaterIntakeCardState extends State<WaterIntakeCard> {
  double currentWaterProgress = 0.0; // Track the current water progress
  double selectedAmount = 250.0; // Default amount for water intake (in milliliters)
  String selectedDrink = "Water"; // Default drink type

  final Map<String, Map<String, dynamic>> drinkOptions = {
    "Water": {"icon": Icons.local_drink, "amount": 250.0},
    "Tea": {"icon": Icons.emoji_food_beverage, "amount": 200.0},
    "Coffee": {"icon": Icons.coffee, "amount": 150.0},
    "Juice": {"icon": Icons.local_bar, "amount": 180.0}, // Added Juice option
  };

  @override
  void initState() {
    super.initState();
    currentWaterProgress = widget.currentProgress; // Initialize progress from passed value
  }

  // Function to update progress based on selected drink
  void _updateProgress() {
    setState(() {
      currentWaterProgress += selectedAmount;
      if (currentWaterProgress > widget.totalWaterGoal) {
        currentWaterProgress = widget.totalWaterGoal; // Cap the progress at the goal
      }

      // Trigger the Firestore update by calling the callback and passing selectedAmount
      widget.onProgressUpdate(selectedAmount);
    });
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = (currentWaterProgress / widget.totalWaterGoal) * 100.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Water Intake",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),

            // Circular progress bar with percentage
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: currentWaterProgress / widget.totalWaterGoal,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      drinkOptions[selectedDrink]!['icon'],
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Drink selection buttons with icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: drinkOptions.keys.map((drink) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDrink = drink;
                      selectedAmount = drinkOptions[drink]!['amount'];
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        drinkOptions[drink]!['icon'],
                        size: 40,
                        color: selectedDrink == drink ? Colors.blueAccent : Colors.grey,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        drink,
                        style: TextStyle(
                          fontSize: 16,
                          color: selectedDrink == drink ? Colors.blueAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Button to add progress or show completed status
            currentWaterProgress >= widget.totalWaterGoal
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : FloatingActionButton.extended(
                    onPressed: _updateProgress,
                    label: Text('Add ${selectedAmount.toInt()} mL'),
                    icon: const Icon(Icons.add),
                    backgroundColor: Colors.blueAccent,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
