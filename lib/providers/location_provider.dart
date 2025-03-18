import 'package:flutter/material.dart';
import '../services/api_services.dart';

enum LoadingStatus { initial, loading, loaded, error }

class LocationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State variables
  List<String> _locations = [];
  List<String> _shopFloors = [];
  String? _selectedLocation;
  String? _selectedShopFloor;
  String? _errorMessage;
  LoadingStatus _locationStatus = LoadingStatus.initial;
  LoadingStatus _shopFloorStatus = LoadingStatus.initial;

  // Getters
  List<String> get locations => _locations;
  List<String> get shopFloors => _shopFloors;
  String? get selectedLocation => _selectedLocation;
  String? get selectedShopFloor => _selectedShopFloor;
  String? get errorMessage => _errorMessage;
  bool get isLoadingLocations => _locationStatus == LoadingStatus.loading;
  bool get isLoadingShopFloors => _shopFloorStatus == LoadingStatus.loading;
  bool get canProceed => _selectedLocation != null && _selectedShopFloor != null;

  // Set selected location
  void setSelectedLocation(String? location) {
    _selectedLocation = location;
    _selectedShopFloor = null;
    _shopFloors = [];
    
    if (location != null) {
      fetchShopFloors(location);
    }
    
    notifyListeners();
  }

  // Set selected shop floor
  void setSelectedShopFloor(String? shopFloor) {
    _selectedShopFloor = shopFloor;
    notifyListeners();
  }

  // Fetch locations from API
  Future<void> fetchLocations() async {
    _locationStatus = LoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.getLocations();
    
    if (response.success) {
      _locations = response.data ?? [];
      _locationStatus = LoadingStatus.loaded;
    } else {
      _locationStatus = LoadingStatus.error;
      _errorMessage = response.error;
    }
    
    notifyListeners();
  }

  // Fetch shop floors for a specific location
  Future<void> fetchShopFloors(String location) async {
    _shopFloorStatus = LoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final response = await _apiService.getShopFloors(location);
    
    if (response.success) {
      _shopFloors = response.data ?? [];
      _shopFloorStatus = LoadingStatus.loaded;
    } else {
      _shopFloorStatus = LoadingStatus.error;
      _errorMessage = response.error;
    }
    
    notifyListeners();
  }

  // Reset error message
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Reset all state (e.g., when navigating away)
  void reset() {
    _selectedLocation = null;
    _selectedShopFloor = null;
    _errorMessage = null;
    _shopFloors = [];
    notifyListeners();
  }
}