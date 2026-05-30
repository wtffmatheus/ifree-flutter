import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_validators.dart';
import '../../jobs/data/vaga_repository.dart';

class CreateVacancyScreen extends StatefulWidget {
  const CreateVacancyScreen({super.key});

  @override
  State<CreateVacancyScreen> createState() => _CreateVacancyScreenState();
}

class _CreateVacancyScreenState extends State<CreateVacancyScreen> {
  final VagaRepository _repository = VagaRepository();

  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _localController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();
  final _horarioController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _quantidadeController = TextEditingController(text: '1');

  String _tipo = 'Garçom';
  bool _saving = false;

  final List<String> _tipos = const [
    'Garçom',
    'Auxiliar',
    'Pizzaiolo',
    'Barista',
    'Chapeiro',
    'Atendente',
    'Outro',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _localController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    _horarioController.dispose();
    _descricaoController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar('FaÃƒÂ§a login para criar uma vaga.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final empresa =
          userData['companyName']?.toString().trim().isNotEmpty == true
          ? userData['companyName'].toString()
          : userData['name']?.toString().trim().isNotEmpty == true
          ? userData['name'].toString()
          : user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Empresa';

      await _repository.criarVaga(
        titulo: _tituloController.text,
        empresa: empresa,
        empresaId: user.uid,
        tipo: _tipo,
        local: _localController.text,
        valor: AppValidators.normalizeMoney(_valorController.text),
        data: _dataController.text,
        horario: _horarioController.text,
        descricao: _descricaoController.text,
        quantidade: int.parse(_quantidadeController.text.trim()),
      );

      if (!mounted) return;

      _showSnackBar('Vaga criada com sucesso.');

      context.pop();
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceAll('Exception: ', '');

      _showSnackBar(
        message.isEmpty ? 'Não foi possível criar a vaga.' : message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar vaga'), centerTitle: false),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Dados principais',
                icon: Icons.work_rounded,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'TÃƒÂ­tulo da vaga',
                      prefixIcon: Icon(Icons.title_rounded),
                      hintText: 'Ex: Garçom para evento',
                    ),
                    validator: (value) => AppValidators.minLength(
                      value,
                      4,
                      message: 'Informe um tÃƒÂ­tulo vÃƒÂ¡lido.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _tipos
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _tipo = value;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _localController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'Ex: Centro, Sorocaba - SP',
                    ),
                    validator: (value) => AppValidators.minLength(
                      value,
                      3,
                      message: 'Informe o local da vaga.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Data, horÃƒÂ¡rio e pagamento',
                icon: Icons.event_rounded,
                children: [
                  TextFormField(
                    controller: _dataController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      hintText: 'Ex: AmanhÃƒÂ£, 20/06, SÃƒÂ¡bado...',
                    ),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      message: 'Informe a data.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _horarioController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'HorÃƒÂ¡rio',
                      prefixIcon: Icon(Icons.access_time_rounded),
                      hintText: 'Ex: 08:00 ÃƒÂ s 17:00',
                    ),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      message: 'Informe o horÃƒÂ¡rio.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valorController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor da diária',
                      prefixIcon: Icon(Icons.payments_rounded),
                      hintText: 'Ex: 120,00',
                    ),
                    validator: AppValidators.money,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantidadeController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de vagas',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    validator: AppValidators.positiveInt,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Descrição',
                icon: Icons.description_outlined,
                children: [
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrição da vaga',
                      alignLabelWithHint: true,
                      hintText:
                          'Explique as atividades, requisitos e observaÃƒÂ§ÃƒÂµes importantes.',
                    ),
                    validator: (value) => AppValidators.minLength(
                      value,
                      10,
                      message: 'Descreva melhor a vaga.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Publicando...' : 'Publicar vaga'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.post_add_rounded, color: Colors.white, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Publique uma vaga clara para receber bons candidatos.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
