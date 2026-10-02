import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

/// HR fills this in to create an employee's account for them. Mirrors the
/// old self-registration form, but submits through
/// AuthViewModel.addEmployeeAsAdmin so HR's own session is unaffected.
class AddEmployeeView extends StatefulWidget {
  const AddEmployeeView({super.key});

  @override
  State<AddEmployeeView> createState() => _AddEmployeeViewState();
}

class _AddEmployeeViewState extends State<AddEmployeeView> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _birthdateText = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _department = TextEditingController();
  final _position = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  DateTime? _birthdate;
  String? _gender;
  bool _obscure = true;
  Uint8List? _photoBytes;
  String? _photoError;

  static const _genders = ['Female', 'Male', 'Prefer not to say'];

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _middleName,
      _lastName,
      _birthdateText,
      _phone,
      _address,
      _department,
      _position,
      _email,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 16, now.month, now.day),
      helpText: 'Select birthdate',
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
        _birthdateText.text = DateFormat('MMMM d, y').format(picked);
      });
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 480,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoError = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the camera/gallery.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_photoBytes == null) {
      setState(() => _photoError = 'A profile photo is required');
    }
    if (!_formKey.currentState!.validate() || _photoBytes == null) return;
    final vm = context.read<AuthViewModel>();
    final email = _email.text.trim();
    final ok = await vm.addEmployeeAsAdmin(
      email: email,
      password: _password.text,
      firstName: _firstName.text,
      middleName: _middleName.text,
      lastName: _lastName.text,
      birthdate: _birthdate!,
      gender: _gender!,
      phone: _phone.text,
      address: _address.text,
      department: _department.text,
      position: _position.text,
      photoBase64: base64Encode(_photoBytes!),
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created for $email. Share the email and password '
            'with the employee.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add employee')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This creates the employee's login. Their personal QR "
                  'code is generated automatically — give them the email '
                  'and password below so they can sign in.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _photoBytes != null
                            ? MemoryImage(_photoBytes!)
                            : null,
                        child: _photoBytes == null
                            ? const Icon(Icons.person_outline, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Camera'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ],
                      ),
                      if (_photoError != null) ...[
                        const SizedBox(height: 6),
                        Text(_photoError!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ],
                  ),
                ),
                _section('Personal information'),
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) => _required(v, 'First name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _middleName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Middle name (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) => _required(v, 'Last name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _birthdateText,
                  readOnly: true,
                  onTap: _pickBirthdate,
                  decoration: const InputDecoration(
                    labelText: 'Birthdate',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (_) =>
                      _birthdate == null ? 'Birthdate is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) => v == null ? 'Select a gender' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (v) => _required(v, 'Phone number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Home address'),
                  validator: (v) => _required(v, 'Address'),
                ),
                _section('Work information'),
                TextFormField(
                  controller: _department,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Department'),
                  validator: (v) => _required(v, 'Department'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _position,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Position / job title'),
                  validator: (v) => _required(v, 'Position'),
                ),
                _section('Login credentials'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Temporary password',
                    helperText: 'Share this with the employee so they can '
                        'sign in and change it later.',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Use at least 6 characters'
                      : null,
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 14),
                  Text(vm.error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: vm.loading ? null : _submit,
                  child: vm.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Create employee account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
