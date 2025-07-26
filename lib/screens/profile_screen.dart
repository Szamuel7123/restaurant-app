import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'address_book_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfileService _profileService;
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initProfileService();
  }

  Future<void> _initProfileService() async {
    final prefs = await SharedPreferences.getInstance();
    _profileService = UserProfileService(prefs);
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final profile = await _profileService.getProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  Future<void> _editProfile() async {
    if (_profile == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: _profile!),
    );

    if (result != null) {
      final updatedProfile = _profile!.copyWith(
        name: result['name'],
        email: result['email'],
        phone: result['phone'],
      );

      await _profileService.updateProfile(updatedProfile);
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No profile found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (context) => const _EditProfileDialog(),
                  );

                  if (result != null) {
                    final newProfile = UserProfile(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: result['name']!,
                      email: result['email']!,
                      phone: result['phone']!,
                    );

                    await _profileService.saveProfile(newProfile);
                    await _loadProfile();
                  }
                },
                child: const Text('Create Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profile!.profileImage != null
                        ? NetworkImage(_profile!.profileImage!)
                        : null,
                    child: _profile!.profileImage == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    _profile!.email,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Sections
            _buildSection(
              title: 'Personal Information',
              children: [
                _buildInfoTile('Phone', _profile!.phone),
                _buildInfoTile('Email', _profile!.email),
              ],
            ),
            const SizedBox(height: 16),

            // Address Book
            _buildSection(
              title: 'Address Book',
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Manage Addresses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressBookScreen(),
                      ),
                    );
                  },
                ),
                if (_profile!.addresses.isNotEmpty)
                  ..._profile!.addresses
                      .where((addr) => addr.isDefault)
                      .map((addr) => ListTile(
                            leading: const Icon(Icons.home),
                            title: Text(addr.label),
                            subtitle: Text(addr.address),
                          )),
              ],
            ),
            const SizedBox(height: 16),

            // Order History
            _buildSection(
              title: 'Orders',
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Order History'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Preferences
            _buildSection(
              title: 'Preferences',
              children: [
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  value: _profile!.preferences['emailNotifications'] ?? false,
                  onChanged: (value) async {
                    await _profileService.updatePreferences({
                      'emailNotifications': value,
                    });
                    await _loadProfile();
                  },
                ),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  value: _profile!.preferences['smsNotifications'] ?? false,
                  onChanged: (value) async {
                    await _profileService.updatePreferences({
                      'smsNotifications': value,
                    });
                    await _loadProfile();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserProfile? profile;

  const _EditProfileDialog({this.profile});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name);
    _emailController = TextEditingController(text: widget.profile?.email);
    _phoneController = TextEditingController(text: widget.profile?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
