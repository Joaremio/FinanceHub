import 'package:flutter/material.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
  });

  final String id;
  final String name;
  final int colorValue;
  final String icon;

  Color get color => Color(colorValue);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      colorValue: int.tryParse(json['colorValue']?.toString() ?? '') ?? 0xFF607D8B,
      icon: json['icon']?.toString() ?? 'category',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'icon': icon,
    };
  }
}
