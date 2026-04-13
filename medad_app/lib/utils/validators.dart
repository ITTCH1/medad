/// Utility class for form validation
class Validators {
  /// Validate phone number (Yemen format)
  /// Accepts formats: 123456789, +967123456789, 0123456789
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم الجوال';
    }

    // Remove spaces and special characters
    String cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '').trim();

    // Check if it starts with + and has valid format
    if (cleaned.startsWith('+')) {
      if (!RegExp(r'^\+967[0-9]{7,9}$').hasMatch(cleaned)) {
        return 'رقم الجوال يجب أن يكون بصيغة صحيحة (مثال: +967123456789)';
      }
    } else {
      // Local format (7-9 digits)
      if (!RegExp(r'^[0-9]{7,9}$').hasMatch(cleaned)) {
        return 'رقم الجوال يجب أن يكون بين 7 و 9 أرقام';
      }
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }

    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الاسم';
    }

    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }

    if (value.length > 50) {
      return 'الاسم طويل جداً';
    }

    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  /// Validate price
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال السعر';
    }

    double? price = double.tryParse(value.trim());
    if (price == null || price <= 0) {
      return 'السعر يجب أن يكون رقم موجب';
    }

    if (price > 1000000000) {
      return 'السعر غير منطقي';
    }

    return null;
  }

  /// Validate title
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال العنوان';
    }

    if (value.trim().length < 5) {
      return 'العنوان يجب أن يكون 5 أحرف على الأقل';
    }

    if (value.length > 100) {
      return 'العنوان طويل جداً (حد أقصى 100 حرف)';
    }

    return null;
  }

  /// Validate description
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الوصف';
    }

    if (value.trim().length < 10) {
      return 'الوصف يجب أن يكون 10 أحرف على الأقل';
    }

    if (value.length > 2000) {
      return 'الوصف طويل جداً (حد أقصى 2000 حرف)';
    }

    return null;
  }

  /// Validate location
  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الموقع';
    }

    if (value.trim().length < 2) {
      return 'الموقع يجب أن يكون حرفين على الأقل';
    }

    return null;
  }

  /// Sanitize input (remove HTML tags and trim)
  static String sanitizeInput(String value) {
    // Remove HTML tags
    String sanitized = value.replaceAll(RegExp(r'<[^>]*>'), '');
    // Trim whitespace
    sanitized = sanitized.trim();
    // Limit length
    if (sanitized.length > 5000) {
      sanitized = sanitized.substring(0, 5000);
    }
    return sanitized;
  }

  /// Validate OTP code (6 digits)
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رمز التحقق';
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'رمز التحقق يجب أن يكون 6 أرقام';
    }

    return null;
  }

  /// Validate category
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء اختيار التصنيف';
    }

    return null;
  }
}
