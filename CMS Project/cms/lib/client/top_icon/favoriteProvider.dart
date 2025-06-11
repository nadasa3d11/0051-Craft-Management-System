import 'package:flutter/material.dart';
import 'package:herfa/Shared%20Files/databaseHelper.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<int> _favoriteProductIds = [];

  List<int> get favoriteProductIds => _favoriteProductIds;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _apiService.fetchFavorites();
      _favoriteProductIds = favorites.map((product) => product.productId).toList();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        throw Exception('No Internet Connection. Please check your connection and try again.');
      }
      throw Exception('Error loading favorites: $e');
    }
  }

  Future<void> addFavorite(int productId) async {
    try {
      await _apiService.addToFavourite(productId);
      if (!_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.add(productId);
        notifyListeners();
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        throw Exception('No Internet Connection. Please check your connection and try again.');
      }
      throw Exception('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(int productId) async {
    try {
      await _apiService.removeFromFavourite(productId);
      _favoriteProductIds.remove(productId);
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        throw Exception('No Internet Connection. Please check your connection and try again.');
      }
      throw Exception('Error removing favorite: $e');
    }
  }

  bool isFavorite(int productId) {
    return _favoriteProductIds.contains(productId);
  }

  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }
}