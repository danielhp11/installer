// region Login View Model
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
  final String id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String status;
  final String technicianName;
  final String unitId;
  final String? company;
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
    this.company,
    this.history,
  });

  factory ApiResTicket.fromJson(Map<String, dynamic> json) {
    return ApiResTicket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      technicianName: json['technicianName'] ?? '',
      unitId: json['unitId'] ?? '',
      company: json['company'], // nullable
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
  final String id;
  final String ticketId;

  ItemHistory({
    required this.status,
    required this.notes,
    required this.changedBy,
    required this.id,
    required this.ticketId,
  });

  factory ItemHistory.fromJson(Map<String, dynamic> json) {
    return ItemHistory(
      status: json['status'] ?? '',
      notes: json['notes'] ?? '',
      changedBy: json['changedBy'] ?? '',
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
    );
  }
}

// endregion List Ticket Vew Model