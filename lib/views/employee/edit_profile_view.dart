import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';
import 'request_notifications.dart';

/// Lets an employee propose changes to their own profile. Nothing is applied
/// until HR approves the request.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _gender;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _department;
  late final TextEditingController _position;
  late DateTime _birthdate;
  Uint8List? _newPhoto;

  /// The freshest profile we have. EditProfileViewModel is created once in
  /// EmployeeShell, so its own `user` goes stale after HR approves a change;
  /// AuthViewModel keeps `user` live via a Firestore listener.
  AppUser get _current =>
      context.read<AuthViewModel>().user ??
      context.read<EditProfileViewModel>().user;

  @override
  void initState() {
    super.initState();
    final u = _current;
    _firstName = TextEditingController(text: u.firstName);
    _middleName = TextEditingController(text: u.middleName ?? '');
    _lastName = TextEditingController(text: u.lastName);
    _gender = TextEditingController(text: u.gender);
    _phone = TextEditingController(text: u.phone);
    _address = TextEditingController(text: u.address);
    _department = TextEditingController(text: u.department);
    _position = TextEditingController(text: u.position);
    _birthdate = u.birthdate;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _gender.dispose();
    _phone.dispose();
    _address.dispose();
    _department.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 480,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _newPhoto = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the camera/gallery.')),
        );
      }
    }
  }

  /// Only fields that actually differ from the current profile are sent.
  Map<String, dynamic> _collectChanges() {
    final u = _current;
    final changes = <String, dynamic>{};

    void diff(String key, String current, String next) {
      if (next.trim() != current) changes[key] = next.trim();
    }

    diff('firstName', u.firstName, _firstName.text);
    diff('middleName', u.middleName ?? '', _middleName.text);
    diff('lastName', u.lastName, _lastName.text);
    diff('gender', u.gender, _gender.text);
    diff('phone', u.phone, _phone.text);
    diff('address', u.address, _address.text);
    diff('department', u.department, _department.text);
    diff('position', u.position, _position.text);

    final same = _birthdate.year == u.birthdate.year &&
        _birthdate.month == u.birthdate.month &&
        _birthdate.day == u.birthdate.day;
    if (!same) changes['birthdate'] = Timestamp.fromDate(_birthdate);

    if (_newPhoto != null) changes['photoBase64'] = base64Encode(_newPhoto!);

    return changes;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<EditProfileViewModel>();
    final ok = await vm.submit(_collectChanges());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to HR for approval.')),
      );
      Navigator.of(context).pop();
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _field(String label, TextEditingController c,
      {bool required = true, TextInputType? type, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        enabled: enabled,
        keyboardType: type,
        validator: required ? _required : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _photoPicker(AppUser u, bool locked) {
    ImageProvider? image;
    if (_newPhoto != null) {
      image = MemoryImage(_newPhoto!);
    } else if (u.hasPhoto) {
      image = MemoryImage(base64Decode(u.photoBase64!));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: image,
            child: image == null ? Text(u.initials) : null,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: locked ? null : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed:
                    locked ? null : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();
    final locked = vm.pending != null || vm.submitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: !vm.loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // What the "My QR" badge is counting: pending + resolved requests.
                const RequestNotifications(),

                _photoPicker(
                    context.watch<AuthViewModel>().user ?? vm.user, locked),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field('First name', _firstName, enabled: !locked),
                      _field('Middle name (optional)', _middleName,
                          required: false, enabled: !locked),
                      _field('Last name', _lastName, enabled: !locked),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: locked ? null : _pickBirthdate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Birthdate',
                              suffixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                                DateFormat('MMMM d, y').format(_birthdate)),
                          ),
                        ),
                      ),
                      _field('Gender', _gender, enabled: !locked),
                      _field('Phone', _phone,
                          type: TextInputType.phone, enabled: !locked),
                      _field('Address', _address, enabled: !locked),
                      _field('Department', _department, enabled: !locked),
                      _field('Position', _position, enabled: !locked),
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(vm.error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ),
                      FilledButton(
                        onPressed: locked ? null : _submit,
                        child: vm.submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Submit for approval'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
