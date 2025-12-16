
import 'package:bema_application/common/config/colors.dart';
import 'package:bema_application/common/validations.dart';
import 'package:bema_application/common/widgets/api_results.dart';
import 'package:bema_application/common/widgets/app_bar.dart';
import 'package:bema_application/common/widgets/buttons/background_back_button.dart';
import 'package:bema_application/common/widgets/buttons/custom_elevation_buttons.dart';
import 'package:bema_application/common/widgets/buttons/custom_outline_buttons.dart';
import 'package:bema_application/common/widgets/snackbar%20messages/snackbar_message.dart';
import 'package:bema_application/common/widgets/text_feilds/text_feild_underline.dart';
import 'package:bema_application/features/authentication/data/models/profile_service.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:animated_background/animated_background.dart';
import 'package:bema_application/features/authentication/providers/authentication_provider.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with TickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  bool isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }
  

  Future<void> getUserDetails() async {
    UserModel? user =
        await profileService.getUser(FirebaseAuth.instance.currentUser!.uid);
    if (user != null) {
      nameController.text = user.name;
      emailController.text = user.email;
    }
  }

  Future<void> updateUser() async {
    if (!context.mounted) return;
    ApiResult result = await profileService.updateUser(
      firebaseUser: FirebaseAuth.instance.currentUser!,
      name: nameController.text,
    );

    if (result.isSuccess) {
      showSuccessSnackBarMessage(context, 'Profile updated successfully');
      await Provider.of<AuthenticationProvider>(context, listen: false)
          .refreshUser();
      context.go('/${RouteNames.bottomNavigationBarScreen}', extra: 0);
    } else {
      showErrorSnackBarMessage(context, 'Profile update failed');
    }
    await getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomAppBar(
          showBackButton: true,
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.lightBlue.shade100,
        child: AnimatedBackground(
          behaviour: RandomParticleBehaviour(
            options: const ParticleOptions(
              baseColor: Colors.white,
              spawnOpacity: 0.0,
              opacityChangeRate: 0.25,
              minOpacity: 0.1,
              maxOpacity: 0.4,
              spawnMinSpeed: 30.0,
              spawnMaxSpeed: 70.0,
              spawnMinRadius: 7.0,
              spawnMaxRadius: 15.0,
              particleCount: 50,
            ),
          ),
          vsync: this,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: height * 0.12),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    CustomTextFieldUB(
                      controller: nameController,
                      prefixIcon: Icons.person,
                      labelText: 'Name',
                      hintText: 'Joe',
                      validation: nameValidation,
                      inputType: TextInputType.text,
                      isObscureText: false,
                      enabled: true,
                      textColor: Colors.black,
                    ),
                    CustomTextFieldUB(
                      controller: emailController,
                      prefixIcon: Icons.email,
                      labelText: 'Email',
                      hintText: 'joe@gmail.com',
                      validation: emailValidation,
                      inputType: TextInputType.emailAddress,
                      enabled: false,
                      isObscureText: false,
                      textColor: Colors.black,
                    ),
                    SizedBox(height: height * 0.3),
                    CustomElevationBtn(
                      buttonName: 'Save Changes',
                      onClick: () async {
                        setState(() {
                          isSubmitting = true;
                        });
                        if (_formKey.currentState!.validate()) {
                          await updateUser();
                        }
                        setState(() {
                          isSubmitting = false;
                        });
                      },
                      isSubmitting: isSubmitting,
                    ),
                    SizedBox(height: height * 0.015),
                    CustomOutLineButton(
                      buttonName: 'Discard',
                      onClick: () {
                        context.go('/${RouteNames.bottomNavigationBarScreen}',
                            extra: 0);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
