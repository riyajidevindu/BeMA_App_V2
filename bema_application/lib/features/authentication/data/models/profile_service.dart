import 'dart:io';

import 'package:bema_application/common/widgets/api_results.dart';
import 'package:bema_application/features/authentication/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  // Get user by ID
  Future<UserModel?> getUser(String id) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('AppUsers').doc(id).get();

      if (userSnapshot.exists) {
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null) {
          return UserModel.fromJson(userData);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error occurred while fetching user: $e');
      return null;
    }
  }

  // Update user
  Future<ApiResult> updateUser(
      {required User firebaseUser,
      required String name,
      }) async {
    UserModel user = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      name: name,
    );

    try {
      await _firestore
          .collection('AppUsers')
          .doc(firebaseUser.uid)
          .update(user.toJson());
      return ApiResult(isSuccess: true, message: 'User Updated');
    } catch (e) {
      return ApiResult(isSuccess: false, message: 'Failed to update user: $e');
    }
  }

}
