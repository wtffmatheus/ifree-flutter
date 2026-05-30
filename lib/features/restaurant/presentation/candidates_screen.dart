import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../chat/data/chat_repository.dart';
import '../../chat/presentation/chat_page.dart';
import '../../jobs/data/vaga_repository.dart';

class CandidatesScreen extends StatefulWidget {
  final String vagaId;

  const CandidatesScreen({super.key, required this.vagaId});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final VagaRepository _repository = VagaRepository();
  final ChatRepository _chatRepository = ChatRepository();

  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos'), centerTitle: false),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _repository.watchCandidaturas(widget.vagaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Text('Não foi possível carregar os candidatos.'),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Text('Nenhum candidato ainda.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return _CandidateCard(
                data: data,
                updating: _updating,
                onApprove: () =>
                    _updateStatus(freelancerId: doc.id, status: 'aprovado'),
                onReject: () =>
                    _updateStatus(freelancerId: doc.id, status: 'recusado'),
                onChat: () => _openChat(doc.id, data),
                onFinishAndRate: data['status']?.toString() == 'aprovado'
                    ? () => _finishAndRate(doc.id, data)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openChat(String freelancerId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final vaga = await _repository.getVagaById(widget.vagaId);

    if (vaga == null || !mounted) return;

    final freelancerName =
        data['freelancerName']?.toString().trim().isNotEmpty == true
        ? data['freelancerName'].toString()
        : 'Freelancer';

    final conversationId = await _chatRepository.createOrGetConversation(
      vagaId: widget.vagaId,
      empresaId: user.uid,
      freelancerId: freelancerId,
      empresaName: vaga.empresa,
      freelancerName: freelancerName,
      vagaTitulo: vaga.titulo,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatPage(conversationId: conversationId, title: freelancerName),
      ),
    );
  }

  Future<void> _updateStatus({
    required String freelancerId,
    required String status,
  }) async {
    setState(() {
      _updating = true;
    });

    try {
      await _repository.atualizarStatusCandidatura(
        vagaId: widget.vagaId,
        freelancerId: freelancerId,
        status: status,
      );

      if (!mounted) return;

      _showSnackBar(
        status == 'aprovado' ? 'Candidato aprovado.' : 'Candidato recusado.',
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível atualizar o candidato.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Future<void> _finishAndRate(
    String freelancerId,
    Map<String, dynamic> data,
  ) async {
    final result = await showDialog<_RatingResult>(
      context: context,
      builder: (context) {
        return const _RatingDialog();
      },
    );

    if (result == null) return;

    setState(() {
      _updating = true;
    });

    try {
      await _repository.finalizarJobComAvaliacao(
        vagaId: widget.vagaId,
        freelancerId: freelancerId,
        rating: result.rating,
        comment: result.comment,
      );

      if (!mounted) return;

      _showSnackBar('Job finalizado e avaliação enviada.');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceAll('Exception: ', '');

      _showSnackBar(
        message.isEmpty ? 'Não foi possível finalizar o job.' : message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool updating;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onChat;
  final VoidCallback? onFinishAndRate;

  const _CandidateCard({
    required this.data,
    required this.updating,
    required this.onApprove,
    required this.onReject,
    required this.onChat,
    required this.onFinishAndRate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final name = data['freelancerName']?.toString().trim().isNotEmpty == true
        ? data['freelancerName'].toString()
        : 'Freelancer';

    final email = data['freelancerEmail']?.toString() ?? '';
    final phone = data['freelancerPhone']?.toString() ?? '';
    final city = data['freelancerCity']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'em_analise';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          if (email.isNotEmpty) ...[const SizedBox(height: 8), Text(email)],
          if (phone.isNotEmpty || city.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text([phone, city].where((e) => e.isNotEmpty).join(' ââ‚¬Â¢ ')),
          ],
          const SizedBox(height: 14),
          if (updating)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Chat'),
                ),
                if (status == 'em_analise') ...[
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Recusar'),
                  ),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Aprovar'),
                  ),
                ],
                if (onFinishAndRate != null)
                  FilledButton.icon(
                    onPressed: onFinishAndRate,
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Finalizar e avaliar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Finalizar e avaliar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nota: ${_rating.toStringAsFixed(1)}'),
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 8,
            label: _rating.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ComentÃƒÂ¡rio',
              hintText: 'Ex: Chegou no horÃƒÂ¡rio e trabalhou muito bem.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _RatingResult(rating: _rating, comment: _commentController.text),
            );
          },
          child: const Text('Finalizar'),
        ),
      ],
    );
  }
}

class _RatingResult {
  final double rating;
  final String comment;

  const _RatingResult({required this.rating, required this.comment});
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final color = switch (normalized) {
      'aprovado' => Colors.green,
      'recusado' => Colors.red,
      'concluido' => Colors.blue,
      'cancelada_pelo_freelancer' => Colors.blueGrey,
      _ => Colors.orange,
    };

    final label = switch (normalized) {
      'aprovado' => 'Aprovado',
      'recusado' => 'Recusado',
      'concluido' => 'ConcluÃƒÂ­do',
      'cancelada_pelo_freelancer' => 'Cancelada',
      _ => 'Em análise',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
