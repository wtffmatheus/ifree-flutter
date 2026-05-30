import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vaga_repository.dart';

final vagaRepositoryProvider = Provider<VagaRepository>((ref) {
  return VagaRepository();
});
