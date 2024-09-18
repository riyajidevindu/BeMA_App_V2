# BeMA - Behavioural Monitoring App

## Project Overview

**Project Name:** BeMA  
**Description:** BeMA is a mobile application that aims to improve users' health and well-being by offering personalized health tips, reminders, and daily updates based on their needs. It leverages advanced technologies like facial recognition and natural language processing to analyze users' emotional states and provide real-time, personalized advice via a chatbot to boost mood and overall wellness.

The app combines tracking physical health with emotional support to offer a comprehensive solution to feeling better and living healthier.

## Problem Statement

In today's fast-paced world, many people struggle to maintain a balance between their physical and mental health. Stress is often the root cause of many health issues, but it goes unnoticed until it becomes a serious problem. Most health apps focus solely on physical activity or offer generic wellness tips, failing to provide personalized emotional support or real-time stress monitoring.

## Solution

BeMA solves this issue by taking a holistic approach to health and wellness. The app monitors not only physical health but also emotional well-being through advanced facial recognition and natural language processing technologies. Based on this real-time emotional analysis, the app delivers personalized health tips, stress-relief techniques, and mood-improving advice via a chatbot.

Key features include:
- **Daily Health Reminders:** Customizable notifications for water intake, exercise, and body check-ups.
- **Emotion Monitoring:** Real-time tracking of emotional states through facial recognition.
- **Personalized Recommendations:** Tailored health advice based on user data and emotional status.
- **Chatbot:** An interactive chatbot that offers emotional support and health advice in a friendly, conversational manner.
- **Marking System:** Gamified features like points and badges to encourage users to follow health tips and stay engaged.

## Target Audience

BeMA is designed for:
- **Busy Professionals:** Those needing quick and effective ways to manage health and stress.
- **Students:** Individuals seeking to manage stress and maintain a healthy lifestyle during their studies.
- **Individuals Seeking Emotional Support:** People looking for help with mood management and emotional well-being.
- **Health Enthusiasts:** Users who want tailored advice for tracking and improving their health.

## Core Features

1. **User Data Collection:**
   - Basic registration details
   - Age, weight, and medical history
   - Family medical history, allergies, smoking/alcohol habits, and exercise routines

2. **Daily Health Reminders:**
   - Sleep time, exercise, water intake, and body check-up reminders tailored to user demographics

3. **Emotion Monitoring:**
   - Real-time facial recognition technology to track emotional states

4. **Personalized Health Recommendations:**
   - Health advice based on user data and real-time emotional analysis

5. **Disease Monitoring:**
   - Continuous tracking of health conditions with personalized suggestions

6. **Chatbot:**
   - Provides emotional support, health advice, and stress-relief techniques in real time

7. **Marking System:**
   - Engages users through a points or badge system for completing tasks and following health tips

## Social and Economic Impact

### Social Impacts:
- **Improved Mental Health:** Emotional support and personalized suggestions help users manage stress, anxiety, and mood.
- **Healthier Lifestyles:** Personalized health recommendations encourage users to adopt healthier habits.
- **Increased Awareness:** The app educates users about their physical and emotional health, empowering them to take control of their well-being.
- **Stronger Community Support:** Recognizing and managing emotions fosters better relationships.
- **Accessible Health Guidance:** Users can access health advice and emotional support anytime, making it easier to seek help when needed.

### Economic Impacts:
- **Reduced Healthcare Costs:** Promoting preventive care reduces the need for expensive treatments.
- **Increased Productivity:** Healthier, emotionally balanced users are likely to be more productive.
- **Cost-Effective Emotional Support:** The app offers affordable mental health support alternatives.
- **Boost to Health Tech Industry:** The integration of AI for personalized care drives innovation and growth in health tech.

## Future Enhancements

1. **Health Test Report Analysis:** Adding functionality to analyze health test reports for more accurate recommendations.
2. **Advanced Disease Monitoring:** Enhanced disease-specific monitoring and updates with AI-driven suggestions.
3. **Live Doctor Interactions:** Real-time consultations with medical professionals for immediate health concerns.

## Technology Stack

### Chatbot (Llama and RAG Bots)

- **Llama 3 Fine-Tuning:** The chatbot and RAG bot are fine-tuned using health-specific datasets to provide personalized, accurate health advice.
  - **Prompt Engineering:** Used to improve the model's accuracy.
  - **Supervised Fine-Tuning (SFT):** Health-related data annotated for safety and helpfulness.
  - **Reinforcement Learning from Human Feedback (RLHF):** Model improvement based on user feedback.
  
- **RAG Bot:** Retrieves personalized data from user-stored routines and relevant PDFs to assist in daily routines.

### System-Level Safeguards

1. **Input and Output Safeguards:** Filters and classifiers ensure queries remain safe, and harmful or misleading content is blocked.
2. **Transparency and Reporting Mechanisms:** A feedback system allows users to report incorrect or harmful advice, with transparency about how the chatbot handles data and safeguards recommendations.

## Feedback and Reporting

BeMA includes a feedback system:
- **Thumbs Up/Down Rating:** Simple rating system to evaluate the accuracy of health recommendations.
- **Detailed Feedback Forms:** Allows users to report incorrect advice and help improve future suggestions.

## Figma Design

You can view our Figma design here: [BeMA Figma Design](https://www.figma.com/design/UmLbhzpPvPWPexRwt8lRSg/Main-Mobile-UI?node-id=191-2540&node-type=frame&t=w0IHJdAzCTintH7K-0)

## Project Setup Instructions

### Prerequisites

Before starting, ensure you have the following installed on your machine:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VSCode (or any IDE supporting Flutter)
- Xcode (for iOS development)

### Step 1: Clone the Repository



© 2024 BeMA. All rights reserved.
