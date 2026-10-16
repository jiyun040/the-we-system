import 'package:shared_preferences/shared_preferences.dart';

const _adminModeRestoreUserKey = 'admin_mode_restore_user_id';

Future<void> rememberAdminModeForRefresh(String userId) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(_adminModeRestoreUserKey, userId);
}

Future<bool> shouldOfferAdminModeAfterRefresh(String userId) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getString(_adminModeRestoreUserKey) == userId;
}

Future<void> clearAdminModeRefreshIntent() async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.remove(_adminModeRestoreUserKey);
}
