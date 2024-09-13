//import 'dart:io';
import 'package:bema_application/features/authentication/data/models/login_result.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_storage/firebase_storage.dart';



class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //final _firebaseStorage = FirebaseStorage.instance;

  // Store user
  Future<AuthResult> storeUser(User firebaseUser, String name) async {
    UserModel user = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      name: name,
      // contact: number,
      // photoUrl: photoUrl,
      // location: location,
    );

    try {
      await _firestore
          .collection('AppUsers')
          .doc(firebaseUser.uid)
          .set(user.toJson());
      return AuthResult(isSuccess: true, message: 'User Registered');
    } catch (e) {
      return AuthResult(
          isSuccess: false, message: 'Failed to register user: $e');
    }
  }

  //update profile img

  // Future<String?> uploadProfileImage(File? image, String email) async {
  //   if (image == null) {
  //     print("Image is null");
  //     return null;
  //   }

  //   try {
  //     // Load the image into memory
  //     img.Image? imageFile = img.decodeImage(image.readAsBytesSync());

  //     img.Image resizedImage = img.copyResize(imageFile!, width: 200);

  //     // Compress the image and convert it back to a File
  //     final compressedImage = File(image.path)
  //       ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

  //     String imageName = '${email}profile';
  //     Reference storageRef =
  //         _firebaseStorage.ref().child('profile_images/$imageName.jpg');

  //     try {
  //       await storageRef.getMetadata();
  //       // Image exists, delete it
  //       await storageRef.delete();
  //       print("Old image deleted");
  //     } catch (e) {
  //       // The image does not exist, or there was an error accessing metadata
  //       print("Image does not exist or error: $e");
  //     }

  //     // Upload the new image
  //     UploadTask uploadTask = storageRef.putFile(compressedImage);
  //     TaskSnapshot snapshot = await uploadTask.whenComplete(() {
  //       print("Upload complete");
  //     });

  //     String downloadUrl = await snapshot.ref.getDownloadURL();
  //     print("Download URL: $downloadUrl");
  //     return downloadUrl;
  //   } catch (e) {
  //     print("Error uploading image: $e");
  //     return null;
  //   }
  // }

  // //forgot password
  // Future<AuthResult> forgotPassword(String email) async {
  //   try {
  //     await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  //     return AuthResult(isSuccess: true, message: 'Password reset email sent');
  //   } on FirebaseAuthException catch (e) {
  //     return AuthResult(
  //         isSuccess: false,
  //         message: e.message ??
  //             'An error occurred while sending the password reset email');
  //   }
  // }
}
