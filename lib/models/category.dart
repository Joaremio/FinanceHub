import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' ou 'expense'
  final int colorValue;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.icon,
  });

  Color get color => Color(colorValue);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      colorValue: int.tryParse(json['colorValue'].toString()) ?? 0xFF607D8B,
      icon: json['icon'] ?? 'category',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'colorValue': colorValue,
      'icon': icon,
    };
  }

  // Categorias padrão
  static List<CategoryModel> get defaults => [
    CategoryModel(
      id: '1',
      name: 'Salário',
      type: 'income',
      colorValue: 0xFF4CAF50,
      icon: 'work',
    ),
    CategoryModel(
      id: '2',
      name: 'Freelance',
      type: 'income',
      colorValue: 0xFF2196F3,
      icon: 'laptop',
    ),
    CategoryModel(
      id: '3',
      name: 'Investimentos',
      type: 'income',
      colorValue: 0xFF9C27B0,
      icon: 'trending_up',
    ),
    CategoryModel(
      id: '4',
      name: 'Alimentação',
      type: 'expense',
      colorValue: 0xFFFF5722,
      icon: 'restaurant',
    ),
    CategoryModel(
      id: '5',
      name: 'Transporte',
      type: 'expense',
      colorValue: 0xFFFF9800,
      icon: 'directions_car',
    ),
    CategoryModel(
      id: '6',
      name: 'Moradia',
      type: 'expense',
      colorValue: 0xFF795548,
      icon: 'home',
    ),
    CategoryModel(
      id: '7',
      name: 'Saúde',
      type: 'expense',
      colorValue: 0xFFF44336,
      icon: 'health_and_safety',
    ),
    CategoryModel(
      id: '8',
      name: 'Lazer',
      type: 'expense',
      colorValue: 0xFF00BCD4,
      icon: 'sports_esports',
    ),
    CategoryModel(
      id: '9',
      name: 'Educação',
      type: 'expense',
      colorValue: 0xFF3F51B5,
      icon: 'school',
    ),
    CategoryModel(
      id: '10',
      name: 'Outros',
      type: 'expense',
      colorValue: 0xFF607D8B,
      icon: 'more_horiz',
    ),
  ];
}
