// lib/features/logs/domain/log_item.dart
import 'package:equatable/equatable.dart';

class LogItem extends Equatable {
  const LogItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.archived,
    this.unit,
    this.color,
  });

  final String id;
  final String name;
  final String? unit;
  final int? color;
  final DateTime createdAt;
  final bool archived;

  LogItem copyWith({String? name, String? unit, int? color, bool? archived}) => LogItem(
        id: id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        color: color ?? this.color,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
      };

  factory LogItem.fromMap(Map<String, Object?> m) => LogItem(
        id: m['id'] as String,
        name: m['name'] as String,
        unit: m['unit'] as String?,
        color: m['color'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        archived: (m['archived'] as int) == 1,
      );

  @override
  List<Object?> get props => [id, name, unit, color, createdAt, archived];
}