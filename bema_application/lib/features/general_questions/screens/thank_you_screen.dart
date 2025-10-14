import 'dart:ui';
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

class _ThankYouScreenState extends State<ThankYouScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _colorAnimation1 = ColorTween(
      begin: Colors.lightBlue.shade200,
      end: Colors.purple.shade200,
    ).animate(_animationController);

    _colorAnimation2 = ColorTween(
      begin: Colors.purple.shade200,
      end: Colors.lightBlue.shade200,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveDataToFirestore(BuildContext context) async {
    setState(() {
      _isSaving = true;
    });

    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final String userId = currentUser.uid;
    final questionnaireProvider =
        Provider.of<QuestionnaireProvider>(context, listen: false);

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
      await FirebaseFirestore.instance
          .collection('userBasicData')
          .doc(userId)
          .set(userHealthData.toMap());

      await FirebaseFirestore.instance
          .collection('AppUsers')
          .doc(userId)
          .update({'questionnaireCompleted': true});

      showSuccessSnackBarMessage(context, 'Data saved successfully!');
      context.go('/${RouteNames.bottomNavigationBarScreen}', extra: 0);
    } catch (e) {
      showErrorSnackBarMessage(context, 'Error saving data: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_colorAnimation1.value!, _colorAnimation2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildStrokedText("🎉 Thank You! 🎉", screenWidth * 0.08),
                const SizedBox(height: 20),
                Text(
                  "We're excited to help you on your health journey!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _isSaving ? null : () => _saveDataToFirestore(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.purple.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Let's Get Started!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokedText(String text, double fontSize,
      {bool isSelected = true}) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
