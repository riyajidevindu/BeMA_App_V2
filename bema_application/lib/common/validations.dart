String? emailValidation(value) {
  if (value == null || value.isEmpty) {
    return "Please Enter the Email";
  } else {
    // Basic email format validation using a regular expression
    String emailRegex = r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
    RegExp regex = RegExp(emailRegex);

    if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }
}

String? passwordValidation(value) {
  if (value == null || value.isEmpty) {
    return "Please Enter the Password";
  } else if (value.length < 6) {
    return "Password must be at least 6 characters long";
  } else {
    return null;
  }
}

String? confirmPasswordValidation(value) {
  if (value == null || value.isEmpty) {
    return "Please Enter the Confirm Password";
  } else if (value.length < 6) {
    return "Password must be at least 6 characters long";
  } else {
    return null;
  }
}

//name validation
String? nameValidation(value) {
  if (value == null || value.isEmpty) {
    return "Please Enter the Name";
  } else {
    return null;
  }
}

//common feild validation
String? commonValidation(value) {
  if (value == null || value.isEmpty) {
    return "Please fill the field";
  } else {
    return null;
  }
}

String? nullValueValidation(value) {
  if (value == null || value.isEmpty) {
    return "Please Enter the Value";
  } else {
    return null;
  }
}
