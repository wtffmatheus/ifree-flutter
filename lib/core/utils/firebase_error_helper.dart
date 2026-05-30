import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHelper {
  static String authMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-disabled':
          return 'Esta conta foi desativada.';
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
          return 'Senha incorreta.';
        case 'invalid-credential':
          return 'E-mail ou senha inválidos.';
        case 'email-already-in-use':
          return 'Este e-mail já está em uso.';
        case 'weak-password':
          return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
        case 'operation-not-allowed':
          return 'Este método de login não está habilitado no Firebase.';
        case 'network-request-failed':
          return 'Erro de conexão. Verifique sua internet.';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
        default:
          return error.message ?? 'Erro de autenticação.';
      }
    }

    final message = error.toString();

    if (message.contains('Login cancelado')) {
      return 'Login cancelado.';
    }

    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
