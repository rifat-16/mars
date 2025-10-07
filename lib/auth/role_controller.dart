import 'package:shared_preferences/shared_preferences.dart';

class RoleController {
  // 🔹 User role get function
  static Future<String?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('position');
  }

  // 🔹 Role check functions
  static Future<bool> isOwner() async {
    String? role = await getUserRole();
    return role == 'Owner';
  }

  static Future<bool> isManager() async {
    String? role = await getUserRole();
    return role == 'Manager';
  }

  static Future<bool> isMPO() async {
    String? role = await getUserRole();
    return role == 'MPO';
  }

  // 🔹 Access permissions
  static Future<bool> canEdit() async {
    String? role = await getUserRole();
    return role == 'Owner' || role == 'Manager';
  }

  static Future<bool> canDelete() async {
    String? role = await getUserRole();
    return role == 'Owner';
  }

  static Future<bool> canView() async {
    return true; // everyone can view
  }
}