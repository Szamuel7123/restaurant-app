import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DeliveryMapScreen extends StatefulWidget {
  final LatLng initialLocation;
  const DeliveryMapScreen({super.key, required this.initialLocation});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  late GoogleMapController _mapController;
  late LatLng _selectedLocation;
  bool _loadingLocation = true;
  String? _locationError;
  bool _permissionChecked = false;
  final TextEditingController _searchController = TextEditingController();
  String _currentAddress = '';
  bool _isSearching = false;
  Set<Marker> _markers = {};
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(5.6037, -0.1870), // Accra coordinates
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _initialCameraPosition = CameraPosition(
      target: _selectedLocation,
      zoom: 15.0,
    );
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _locationError =
            'Location permission denied. Please allow location access in your device settings.';
        _loadingLocation = false;
        _permissionChecked = true;
      });
      return;
    }
    await _initLocation();
    setState(() {
      _permissionChecked = true;
    });
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _selectedLocation = widget.initialLocation;
          _locationError =
              'Location services are disabled. Using default location.';
          _loadingLocation = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _loadingLocation = false;
        _updateMarkers();
      });
      _getAddressFromLatLng(_selectedLocation);
    } catch (e) {
      setState(() {
        _selectedLocation = widget.initialLocation;
        _locationError = 'Could not get location. Using default location.';
        _loadingLocation = false;
      });
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _getAddressFromLatLng(newPosition);
            });
          },
        ),
      };
    });
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        final newPosition = LatLng(location.latitude, location.longitude);
        setState(() {
          _selectedLocation = newPosition;
          _updateMarkers();
        });
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 15.0),
        );
        _getAddressFromLatLng(newPosition);
      } else {
        throw Exception('Location not found');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not found. Please try another search.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _initLocation,
            tooltip: 'Use current location',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for any location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _searchLocation,
                ),
              ),
              // Map
              Expanded(
                child: _loadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: _initialCameraPosition,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onTap: (position) {
                          setState(() {
                            _selectedLocation = position;
                            _updateMarkers();
                          });
                          _getAddressFromLatLng(position);
                        },
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: true,
                      ),
              ),
            ],
          ),
          // Loading Overlay
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_locationError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Address Display
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_currentAddress),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _selectedLocation);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
