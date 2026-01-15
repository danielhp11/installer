// region Login View Model
import 'package:http/http.dart' as http;

class ApiResAuthentication{
  final String access_token;
  final String token_type;
  final bool user_rol;

  ApiResAuthentication({
    required this.access_token,
    required this.token_type,
    required this.user_rol,
  });

  factory ApiResAuthentication.fromJson(Map<String, dynamic> json) {
    return ApiResAuthentication(
      access_token: json['access_token'] ,
      token_type: json['token_type'],
      user_rol: json['user_rol'],
    );
  }

}
// endregion Login View Model

// region List Ticket Vew Model
class ApiResTicket {
  final int id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String status;
  final String technicianName;
  final String unitId;
  final String? company;
  final String? create_at;
  final List<ItemHistory>? history;

  ApiResTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.status,
    required this.technicianName,
    required this.unitId,
    this.create_at,
    this.company,
    this.history,
  });

  factory ApiResTicket.fromJson(Map<String, dynamic> json) {
    return ApiResTicket(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      technicianName: json['technicianName']?.toString() ?? '',
      unitId: json['unitId']?.toString() ?? '',
      company: json['company']?.toString(),
      create_at: (json['create_at'] ?? json['createdAt'])?.toString(),
      history: json['history'] != null
          ? List<ItemHistory>.from(
          (json['history'] as List).map((x) => ItemHistory.fromJson(x)))
          : null,
    );
  }
}

class ItemHistory {
  final String status;
  final String notes;
  final String changedBy;
  final int id;
  final int ticketId;

  ItemHistory({
    required this.status,
    required this.notes,
    required this.changedBy,
    required this.id,
    required this.ticketId,
  });

  factory ItemHistory.fromJson(Map<String, dynamic> json) {
    return ItemHistory(
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      changedBy: json['changedBy']?.toString() ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ticketId: json['ticketId'] is int ? json['ticketId'] : int.tryParse(json['ticketId']?.toString() ?? '0') ?? 0,
    );
  }
}

// endregion List Ticket Vew Model

// region Installer
class ApiResInstaller{
  final int id;
  final String email;
  final String full_name;
  final String status;
  final String role;

  ApiResInstaller({
    required this.id,
    required this.email,
    required this.full_name,
    required this.status,
    required this.role,
  });

  factory ApiResInstaller.fromJson(Map<String, dynamic> json) {
    return ApiResInstaller(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      email: json['email']?.toString() ?? '',
      full_name: json['full_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

}
// endregion Installer

// region Units Busmen
class UnitBusmen {
  final int id;
  final Map<String, dynamic> attributes;
  final int groupId;
  final String name;
  final String uniqueId;
  final String status;
  final String lastUpdate;
  final int positionId;
  final String phone;
  final String model;
  final String contact;
  final String category;
  final bool disabled;

  UnitBusmen({
    required this.id,
    required this.attributes,
    required this.groupId,
    required this.name,
    required this.uniqueId,
    required this.status,
    required this.lastUpdate,
    required this.positionId,
    required this.phone,
    required this.model,
    required this.contact,
    required this.category,
    required this.disabled,  });

  factory UnitBusmen.fromJson(Map<String, dynamic> json) {
    return UnitBusmen(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      groupId: json['groupId'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      uniqueId: json['uniqueId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastUpdate: json['lastUpdate']?.toString() ?? '',
      positionId: json['positionId'] as int? ?? 0,
      phone: json['phone']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      disabled: json['disabled'] is bool ? json['disabled'] : (json['disabled']?.toString() == 'true'),
    );
  }
}

class UnitTemsa {
  final int id;
  final Map<String, dynamic> attributes;
  final int groupId;
  final String name;
  final String uniqueId;
  final String status;
  final String lastUpdate;
  final int positionId;
  final String phone;
  final String model;
  final String contact;
  final String category;
  final bool disabled;

  UnitTemsa({
    required this.id,
    required this.attributes,
    required this.groupId,
    required this.name,
    required this.uniqueId,
    required this.status,
    required this.lastUpdate,
    required this.positionId,
    required this.phone,
    required this.model,
    required this.contact,
    required this.category,
    required this.disabled,
  });

  factory UnitTemsa.fromJson(Map<String, dynamic> json) {
    return UnitTemsa(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      groupId: json['groupId'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      uniqueId: json['uniqueId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastUpdate: json['lastUpdate']?.toString() ?? '',
      positionId: json['positionId'] as int? ?? 0,
      phone: json['phone']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      disabled: json['disabled'] is bool ? json['disabled'] : (json['disabled']?.toString() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attributes': attributes,
      'groupId': groupId,
      'name': name,
      'uniqueId': uniqueId,
      'status': status,
      'lastUpdate': lastUpdate,
      'positionId': positionId,
      'phone': phone,
      'model': model,
      'contact': contact,
      'category': category,
      'disabled': disabled,
    };
  }
}

// endregion Units Busmen

// region Units Temsa
// endregion Units Temsa
