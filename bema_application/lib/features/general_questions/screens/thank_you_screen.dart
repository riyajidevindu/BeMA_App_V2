import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/features/general_questions/data/model/user_health_model.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bema_application/features/general_questions/providers/questioneer_provider.dart';

class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  bool _isSaving = false; // To show progress indicator

  // Function to save data to Firestore using UserHealthModel
  Future<void> _saveDataToFirestore(BuildContext context) async {
    setState(() {
      _isSaving = true;
    });

    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      // Handle the case where the user is not logged in
      print("User is not logged in.");
      return;
    }

    final String userId = currentUser.uid;

    // Access the QuestionnaireProvider data
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);

    // Create an instance of UserHealthModel from the provider data
    final userHealthData = UserHealthModel(
      userId: userId,
      age: questionnaireProvider.age ?? 0,
      height: double.tryParse(questionnaireProvider.heightValue ?? '0') ?? 0.0,
      heightUnit: questionnaireProvider.heightUnit,
      weight: double.tryParse(questionnaireProvider.weightValue ?? '0') ?? 0.0,
      weightUnit: questionnaireProvider.weightUnit,
      gender: questionnaireProvider.selectedGender ?? '',
      profession: questionnaireProvider.selectedOccupation ??
          questionnaireProvider.customOccupation ??
          '',
      hasDiabetes: questionnaireProvider.hasDiabetes ?? false,
      diabetesTreatmentYears: questionnaireProvider.diabetesDuration != null
          ? int.tryParse(questionnaireProvider.diabetesDuration!)
          : null,
      hasHighBloodPressure: questionnaireProvider.hasHypertension ?? false,
      highBloodPressureTreatmentYears:
          questionnaireProvider.hypertensionDuration != null
              ? int.tryParse(questionnaireProvider.hypertensionDuration!)
              : null,
      hasCholesterol: questionnaireProvider.hasCholesterol ?? false,
      cholesterolTreatmentYears:
          questionnaireProvider.cholesterolDuration != null
              ? int.tryParse(questionnaireProvider.cholesterolDuration!)
              : null,
      hasAllergies: questionnaireProvider.hasAllergies ?? false,
      allergyType: questionnaireProvider.allergiesDescription,
      hadSurgeries: questionnaireProvider.hasSurgeries ?? false,
      surgeryYear: questionnaireProvider.surgeryYear != null
          ? int.tryParse(questionnaireProvider.surgeryYear!)
          : null,
      surgeryType: questionnaireProvider.surgeryType,
      hasDisabilitiesOrSpecialNeeds:
          questionnaireProvider.hasDisability ?? false,
      disabilityDiscription: questionnaireProvider.disabilityDescription,
      hasFamilyMedicalHistory: questionnaireProvider.hasFamilyMedHis ?? false,
      familyMedicalHistoryDiscription: questionnaireProvider.familyMedHistory,
      smokes: questionnaireProvider.smokingStatus != null &&
          questionnaireProvider.smokingStatus != "no_never",
      smokingFrequency: questionnaireProvider.smokingCount,
      drinks: questionnaireProvider.alcoholStatus != null &&
          questionnaireProvider.alcoholStatus != "no_never",
      glassesPerWeek: questionnaireProvider.alcoholCount,
      exercises: questionnaireProvider.activeness != null &&
          questionnaireProvider.activeness!.isNotEmpty,
      favoriteExercise: questionnaireProvider.activeMode,
    );

    try {
      // Convert the UserHealthModel instance to a map and save it to Firestore
      await FirebaseFirestore.instance
          .collection('userBasicData')
          .doc(userId)
          .set(userHealthData.toMap());

      // Update the 'questionnaireCompleted' field to true in the 'AppUsers' collection
      await FirebaseFirestore.instance
          .collection('AppUsers')
          .doc(userId)
          .update({'questionnaireCompleted': true});

      showSuccessSnackBarMessage(context, 'Data saved successfully!');
      print('Data and questionnaire status saved successfully!');

      // Navigate to the home screen
      //context.goNamed(RouteNames.homeScreen);
      context.go('/${RouteNames.bottomNavigationBarScreen}', extra: 0); 
    } catch (e) {
      showErrorSnackBarMessage(context, 'Error saving data: $e');
      print('Error saving data: $e');
    } finally {
      setState(() {
        _isSaving = false; // Stop showing the progress indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double emojiSize = screenWidth * 0.2;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF), // Light blue background
      body: Column(
        children: [
          const SizedBox(height: 50),

          // Row for Back button and Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                // Back button inside a transparent circle
                GestureDetector(
                  onTap: () {
                    context.goNamed(RouteNames
                        .questionScreen19); // Adjust this route to the correct one
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.2), // Transparent background
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white, // White arrow color
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.025), // Space between back button and progress bar

                // Progress bar with increased width
                const Expanded(
                  child: LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.grey,
                    color: Colors.blue, // Progress bar color
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.08),
                    Text(
                      "🎉", // Celebration emoji
                      style: TextStyle(fontSize: emojiSize), // Emoji size
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    const Text(
                      "Thank you for sharing!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    const Text(
                      "We're excited to help you on your health journey!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.07),

                    // Continue button
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null // Disable button while saving
                          : () => _saveDataToFirestore(context), // Call Firestore save method
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Blue button color
                        minimumSize: const Size(double.infinity, 50), // Full-width button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Continue",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
