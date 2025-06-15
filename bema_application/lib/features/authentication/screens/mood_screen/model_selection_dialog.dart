import 'package:flutter/material.dart';

class ModelSelectionDialog extends StatelessWidget {
  final List<String> modelPaths;
  final Function(String) onModelSelected;

  // Mapping of model file names to descriptive names
  final Map<String, String> modelNames = {
    'girl.glb': 'Ema',
    'white_cartoon_dog.glb': 'BeMA Puppy',
    'professor_einstein.glb': 'Professor Einstein',
  };

  ModelSelectionDialog({
    Key? key,
    required this.modelPaths,
    required this.onModelSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: Colors.black, width: 3.0), // Black cloud border
      ),
      backgroundColor: Colors.white,
      title: const Text(
        'Meet Your Chatting Friend!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'Select a model to chat with. This model will assist you in answering your questions.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ...modelPaths.map((modelPath) {
              final modelName = modelNames[modelPath.split('/').last] ?? 'Unknown';
              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  leading: Icon(Icons.model_training, color: Colors.blueAccent),
                  title: Text(
                    modelName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                  onTap: () {
                    onModelSelected(modelPath);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}