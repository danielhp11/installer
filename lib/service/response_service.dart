// region Login View Model

class ApiResAuthentication{
  // final String access_token;
  // final String token_type;
  final String name;
  final bool user_rol;
  final int id;

  ApiResAuthentication({
    // required this.access_token,
    // required this.token_type,
    required this.user_rol,
    required this.name,
    required this.id
  });

  factory ApiResAuthentication.fromJson(Map<String, dynamic> json) {
    return ApiResAuthentication(
      // access_token: json['access_token'] ,
      // token_type: json['token_type'],
        user_rol: json['user_rol'],
        name: json['full_name'],
        id: json["id"]
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
  final List<ItemEvidence> evidences;

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
    required this.evidences
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
      history: json['history'] != null && json['history'] is List
          ? List<ItemHistory>.from(
          (json['history'] as List).map((x) => ItemHistory.fromJson(x)))
          : [],
      evidences: json['evidences'] != null && json['evidences'] is List
          ? List<ItemEvidence>.from(
          (json['evidences'] as List).map((x) => ItemEvidence.fromJson(x)))
          : [],
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

class ItemEvidence {
  final String imageUrl;
  final String phase;
  final int sequence;
  final String status;
  final int id;
  final int ticketId;
  final String createdAt;

  ItemEvidence({
    required this.imageUrl,
    required this.phase,
    required this.sequence,
    required this.status,
    required this.id,
    required this.ticketId,
    required this.createdAt,
  });

  factory ItemEvidence.fromJson(Map<String, dynamic> json) {
    return ItemEvidence(
      imageUrl: json['imageUrl']?.toString() ?? '',
      phase: json['phase']?.toString() ?? '',
      sequence: json['sequence'] is int ? json['sequence'] : int.tryParse(json['sequence']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ticketId: json['ticketId'] is int ? json['ticketId'] : int.tryParse(json['ticketId']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
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
