import 'dart:ui';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String mainText;
  final String subText;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;
  final bool showGetButton;
  final String? buttonText;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.mainText,
    required this.subText,
    required this.primaryColor,
    required this.secondaryColor,
    this.onTap,
    this.showGetButton = false,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive calculations
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    // Responsive sizes
    final minHeight = isSmallScreen ? 130.0 : (isMediumScreen ? 150.0 : 170.0);
    final cardPadding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);
    final iconContainerPadding =
        isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
    final iconSize = isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 28.0);
    final titleFontSize = isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
    final mainTextFontSize =
        isSmallScreen ? 24.0 : (isMediumScreen ? 32.0 : 38.0);
    final subTextFontSize =
        isSmallScreen ? 11.0 : (isMediumScreen ? 13.0 : 15.0);
    final emptyIconSize = isSmallScreen ? 32.0 : (isMediumScreen ? 40.0 : 48.0);
    final buttonPaddingH =
        isSmallScreen ? 14.0 : (isMediumScreen ? 20.0 : 24.0);
    final buttonPaddingV = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
    final buttonIconSize =
        isSmallScreen ? 14.0 : (isMediumScreen ? 18.0 : 20.0);
    final buttonTextSize =
        isSmallScreen ? 11.0 : (isMediumScreen ? 13.0 : 15.0);
    final spacing = isSmallScreen ? 8.0 : (isMediumScreen ? 12.0 : 16.0);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  secondaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Title Row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconContainerPadding),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),

                  // Main Text
                  if (!showGetButton) ...[
                    Text(
                      mainText,
                      style: TextStyle(
                        fontSize: mainTextFontSize,
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
                    const SizedBox(height: 4),
                    Text(
                      subText,
                      style: TextStyle(
                        fontSize: subTextFontSize,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  // Get Button for empty state
                  if (showGetButton) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: emptyIconSize,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mainText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subTextFontSize,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: spacing),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.8),
                                  secondaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: buttonIconSize,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    buttonText ?? 'Get Now',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: buttonTextSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
