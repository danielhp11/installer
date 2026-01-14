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