import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/image_upload_service.dart';
import '../../auth/data/auth_repository.dart';

class ProfileRestaurantPage extends StatefulWidget {
  const ProfileRestaurantPage({super.key});

  @override
  State<ProfileRestaurantPage> createState() => _ProfileRestaurantPageState();
}

class _ProfileRestaurantPageState extends State<ProfileRestaurantPage> {
  final AuthRepository _authRepository = AuthRepository();
  final ImageUploadService _imageUploadService = ImageUploadService();

  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _uploadingPhoto = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _responsibleController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final data = await _authRepository.getUserData(user.uid);

      if (!mounted) return;

      _companyNameController.text =
          data?['companyName']?.toString() ??
          data?['name']?.toString() ??
          user.displayName ??
          '';

      _responsibleController.text =
          data?['responsibleName']?.toString() ??
          data?['responsible']?.toString() ??
          '';

      _phoneController.text = data?['phone']?.toString() ?? '';
      _addressController.text =
          data?['address']?.toString() ?? data?['city']?.toString() ?? '';
      _descriptionController.text = data?['description']?.toString() ?? '';
      _typeController.text =
          data?['establishmentType']?.toString() ??
          data?['type']?.toString() ??
          '';
      _photoUrlController.text =
          data?['photoUrl']?.toString() ?? user.photoURL ?? '';

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSnackBar(
        'Não foi possível carregar o perfil da empresa.',
        isError: true,
      );
    }
  }

  Future<void> _pickCompanyPhoto() async {
    final user = _user;

    if (user == null) {
      _showSnackBar('FaÃƒÂ§a login para alterar a foto.', isError: true);
      return;
    }

    setState(() {
      _uploadingPhoto = true;
    });

    try {
      final photoUrl = await _imageUploadService.pickAndUploadProfileImage(
        uid: user.uid,
      );

      if (!mounted) return;

      if (photoUrl == null) {
        _showSnackBar('Nenhuma imagem selecionada.');
        return;
      }

      _photoUrlController.text = photoUrl;

      await _authRepository.createOrUpdateUserData(user.uid, {
        'photoUrl': photoUrl,
        'role': 'company',
      });

      if (!mounted) return;

      setState(() {});

      _showSnackBar('Foto da empresa atualizada.');
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível atualizar a foto.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;

    if (user == null) {
      _showSnackBar('FaÃƒÂ§a login para editar o perfil.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final companyName = _companyNameController.text.trim();

    try {
      await user.updateDisplayName(companyName);

      await _authRepository.createOrUpdateUserData(user.uid, {
        'name': companyName,
        'companyName': companyName,
        'responsibleName': _responsibleController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'establishmentType': _typeController.text.trim(),
        'photoUrl': _photoUrlController.text.trim(),
        'role': 'company',
        'profileComplete':
            companyName.isNotEmpty &&
            _phoneController.text.trim().isNotEmpty &&
            _addressController.text.trim().isNotEmpty,
      });

      if (!mounted) return;

      setState(() {
        _editing = false;
      });

      _showSnackBar('Perfil da empresa atualizado com sucesso.');
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Não foi possível salvar o perfil da empresa.',
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você precisarÃƒÂ¡ fazer login novamente para acessar o iFree.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _authRepository.signOut();
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
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('FaÃƒÂ§a login para acessar o perfil da empresa.'),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final email = user.email ?? 'E-mail não informado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil da empresa'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _editing = !_editing;
                    });
                  },
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
            tooltip: _editing ? 'Cancelar ediÃƒÂ§ÃƒÂ£o' : 'Editar',
          ),
          if (_editing)
            IconButton(
              onPressed: _saving ? null : _saveProfile,
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Salvar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CompanyHeader(
              name: _companyNameController.text.trim().isEmpty
                  ? 'Empresa'
                  : _companyNameController.text.trim(),
              email: email,
              photoUrl: _photoUrlController.text.trim(),
              uploadingPhoto: _uploadingPhoto,
              onPickPhoto: _pickCompanyPhoto,
            ),
            const SizedBox(height: 18),
            if (_editing)
              _EditCompanyForm(
                companyNameController: _companyNameController,
                responsibleController: _responsibleController,
                phoneController: _phoneController,
                addressController: _addressController,
                descriptionController: _descriptionController,
                typeController: _typeController,
                photoUrlController: _photoUrlController,
                saving: _saving,
                onChanged: () => setState(() {}),
              )
            else
              _CompanyInfoView(
                type: _typeController.text,
                responsible: _responsibleController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                description: _descriptionController.text,
              ),
            const SizedBox(height: 18),
            if (_editing)
              FilledButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _editing = true;
                  });
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar perfil'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;

  const _CompanyHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.uploadingPhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ImageProvider? image;

    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        final base64Data = photoUrl.split(',').last;
        image = MemoryImage(base64Decode(base64Data));
      } else {
        image = NetworkImage(photoUrl);
      }
    }

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
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: image,
                child: image == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'E',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: uploadingPhoto ? null : onPickPhoto,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: uploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.camera_alt_rounded,
                            color: colorScheme.primary,
                            size: 17,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCompanyForm extends StatelessWidget {
  final TextEditingController companyNameController;
  final TextEditingController responsibleController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController descriptionController;
  final TextEditingController typeController;
  final TextEditingController photoUrlController;
  final bool saving;
  final VoidCallback onChanged;

  const _EditCompanyForm({
    required this.companyNameController,
    required this.responsibleController,
    required this.phoneController,
    required this.addressController,
    required this.descriptionController,
    required this.typeController,
    required this.photoUrlController,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Dados da empresa',
          icon: Icons.storefront_rounded,
          children: [
            TextFormField(
              controller: companyNameController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Nome do restaurante/empresa',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome da empresa.';
                }

                return null;
              },
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: photoUrlController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'URL da logo/foto',
                prefixIcon: Icon(Icons.image_outlined),
                hintText:
                    'Ou toque na cÃƒÂ¢mera da foto para enviar do dispositivo',
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: typeController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Tipo de estabelecimento',
                prefixIcon: Icon(Icons.category_outlined),
                hintText: 'Restaurante, pizzaria, cafeteria...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: responsibleController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'ResponsÃƒÂ¡vel',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Contato e endereÃƒÂ§o',
          icon: Icons.contact_phone_rounded,
          children: [
            TextFormField(
              controller: phoneController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'EndereÃƒÂ§o / cidade',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Descrição',
          icon: Icons.description_outlined,
          children: [
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Sobre a empresa',
                alignLabelWithHint: true,
                hintText: 'Conte um pouco sobre o estabelecimento...',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompanyInfoView extends StatelessWidget {
  final String type;
  final String responsible;
  final String phone;
  final String address;
  final String description;

  const _CompanyInfoView({
    required this.type,
    required this.responsible,
    required this.phone,
    required this.address,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sobre a empresa',
      icon: Icons.info_outline_rounded,
      children: [
        _InfoTile(
          icon: Icons.category_outlined,
          title: 'Tipo',
          value: type.trim().isEmpty ? 'Não informado' : type.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.person_outline_rounded,
          title: 'ResponsÃƒÂ¡vel',
          value: responsible.trim().isEmpty
              ? 'Não informado'
              : responsible.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.phone_outlined,
          title: 'Telefone',
          value: phone.trim().isEmpty ? 'Não informado' : phone.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.location_on_outlined,
          title: 'EndereÃƒÂ§o',
          value: address.trim().isEmpty ? 'Não informado' : address.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.description_outlined,
          title: 'Descrição',
          value: description.trim().isEmpty
              ? 'Nenhuma descrição adicionada.'
              : description.trim(),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
