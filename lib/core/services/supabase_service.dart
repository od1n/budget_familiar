import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabase => Supabase.instance.client;

extension SupabaseClientX on SupabaseClient {
  String get currentUserId {
    final userId = auth.currentUser?.id;
    if (userId == null) throw const AuthException('No hay sesión activa.');
    return userId;
  }

  bool get isAuthenticated => auth.currentUser != null;
}
