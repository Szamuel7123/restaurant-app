import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'delivery_map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
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

  Future<void> _addNewAddress() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryMapScreen(
          initialLocation: LatLng(5.6037, -0.1870), // Accra coordinates
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      final address = await showDialog<DeliveryAddress>(
        context: context,
        builder: (context) => _AddressDetailsDialog(
          latitude: result.latitude,
          longitude: result.longitude,
        ),
      );

      if (address != null) {
        await _profileService.addAddress(address);
        await _loadProfile();
      }
    }
  }

  Future<void> _editAddress(DeliveryAddress address) async {
    final result = await showDialog<DeliveryAddress>(
      context: context,
      builder: (context) => _AddressDetailsDialog(address: address),
    );

    if (result != null) {
      await _profileService.updateAddress(result);
      await _loadProfile();
    }
  }

  Future<void> _deleteAddress(DeliveryAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete ${address.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _profileService.deleteAddress(address.id);
      await _loadProfile();
    }
  }

  Future<void> _setDefaultAddress(DeliveryAddress address) async {
    await _profileService.setDefaultAddress(address.id);
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please create a profile first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Book'),
      ),
      body: _profile!.addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No addresses saved'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addNewAddress,
                    icon: const Icon(Icons.add_location),
                    label: const Text('Add New Address'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _profile!.addresses.length,
              itemBuilder: (context, index) {
                final address = _profile!.addresses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          address.isDefault ? Icons.home : Icons.location_on,
                          color: address.isDefault ? Colors.deepOrange : null,
                        ),
                        title: Text(address.label),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(address.address),
                            if (address.additionalInfo != null)
                              Text(
                                address.additionalInfo!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            if (!address.isDefault)
                              const PopupMenuItem(
                                value: 'set_default',
                                child: Text('Set as Default'),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'set_default':
                                _setDefaultAddress(address);
                                break;
                              case 'edit':
                                _editAddress(address);
                                break;
                              case 'delete':
                                _deleteAddress(address);
                                break;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAddress,
        icon: const Icon(Icons.add_location),
        label: const Text('Add Address'),
      ),
    );
  }
}

class _AddressDetailsDialog extends StatefulWidget {
  final DeliveryAddress? address;
  final double? latitude;
  final double? longitude;

  const _AddressDetailsDialog({
    this.address,
    this.latitude,
    this.longitude,
  });

  @override
  State<_AddressDetailsDialog> createState() => _AddressDetailsDialogState();
}

class _AddressDetailsDialogState extends State<_AddressDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _additionalInfoController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label);
    _addressController = TextEditingController(text: widget.address?.address);
    _additionalInfoController = TextEditingController(
      text: widget.address?.additionalInfo,
    );
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label (e.g., Home, Work)',
                hintText: 'Enter a name for this address',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a label';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter the full address',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the address';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _additionalInfoController,
              decoration: const InputDecoration(
                labelText: 'Additional Info (Optional)',
                hintText: 'Enter any additional delivery instructions',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set as Default Address'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
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
              final address = DeliveryAddress(
                id: widget.address?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                label: _labelController.text,
                address: _addressController.text,
                latitude: widget.latitude ?? widget.address!.latitude,
                longitude: widget.longitude ?? widget.address!.longitude,
                isDefault: _isDefault,
                additionalInfo: _additionalInfoController.text.isEmpty
                    ? null
                    : _additionalInfoController.text,
              );
              Navigator.pop(context, address);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
