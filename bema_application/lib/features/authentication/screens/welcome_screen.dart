import 'package:bema_application/common/widgets/buttons/custom_outline_buttons.dart';
import 'package:bema_application/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/welcome_background.png'),
              fit: BoxFit
                  .cover, 
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              SizedBox(
              height: screenHeight * 0.15,
            ),
             const Text('As your BeMa',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color.fromARGB(255, 3, 16, 159),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5)),
            SizedBox(
              height: screenHeight * 0.66,
            ),
                CustomOutLineButton(
                buttonName: 'Get Started',
                onClick: () {
                  context.goNamed(RouteNames.loginScreen);
                }),
                SizedBox(height: screenHeight * 0.03),
           
          ],
        )
      ]),
    );
  }
}
