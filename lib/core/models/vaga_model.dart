import 'package:cloud_firestore/cloud_firestore.dart';

class VagaModel {
  final String id;
  final String titulo;
  final String empresa;
  final String empresaId;
  final String tipo;
  final String local;
  final String valor;
  final String data;
  final String horario;
  final String descricao;
  final int quantidade;
  final double? lat;
  final double? lng;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VagaModel({
    required this.id,
    required this.titulo,
    required this.empresa,
    required this.empresaId,
    required this.tipo,
    required this.local,
    required this.valor,
    required this.data,
    required this.horario,
    required this.descricao,
    required this.quantidade,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAtiva => status == 'ativa';

  bool get hasLocation => lat != null && lng != null;

  factory VagaModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return VagaModel(
      id: doc.id,
      titulo: data['titulo']?.toString() ?? '',
      empresa: data['empresa']?.toString() ?? '',
      empresaId: data['empresaId']?.toString() ?? '',
      tipo: data['tipo']?.toString() ?? '',
      local: data['local']?.toString() ?? '',
      valor: data['valor']?.toString() ?? '',
      data: data['data']?.toString() ?? '',
      horario: data['horario']?.toString() ?? '',
      descricao: data['descricao']?.toString() ?? '',
      quantidade: _parseInt(data['quantidade']),
      lat: _parseDouble(data['lat']),
      lng: _parseDouble(data['lng']),
      status: data['status']?.toString() ?? 'ativa',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'empresa': empresa,
      'empresaId': empresaId,
      'tipo': tipo,
      'local': local,
      'valor': valor,
      'data': data,
      'horario': horario,
      'descricao': descricao,
      'quantidade': quantidade,
      'lat': lat,
      'lng': lng,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }
}
