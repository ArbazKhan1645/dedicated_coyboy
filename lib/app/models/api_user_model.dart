// app/models/user_model.dart
class ApiUserModel {
  final String id;
  final String username;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String url;
  final String description;
  final String link;
  final String locale;
  final String nickname;
  final String slug;
  final List<String> roles;
  final DateTime registeredDate;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> extraCapabilities;
  final Map<String, String> avatarUrls;
  final Map<String, dynamic>? meta;
  final List<dynamic> acf;
  final bool isSuperAdmin;

  ApiUserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.url,
    required this.description,
    required this.link,
    required this.locale,
    required this.nickname,
    required this.slug,
    required this.roles,
    required this.registeredDate,
    required this.capabilities,
    required this.extraCapabilities,
    required this.avatarUrls,
     this.meta,
    required this.acf,
    required this.isSuperAdmin,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    return ApiUserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      locale: json['locale'] ?? 'en_US',
      nickname: json['nickname'] ?? '',
      slug: json['slug'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      registeredDate: DateTime.tryParse(json['registered_date'] ?? '') ?? DateTime.now(),
      capabilities: Map<String, dynamic>.from(json['capabilities'] ?? {}),
      extraCapabilities: Map<String, dynamic>.from(json['extra_capabilities'] ?? {}),
      avatarUrls: Map<String, String>.from(json['avatar_urls'] ?? {}),
      // meta: Map<String, dynamic>.from(json['meta'] ?? {}),
      acf: List<dynamic>.from(json['acf'] ?? []),
      isSuperAdmin: json['is_super_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'url': url,
      'description': description,
      'link': link,
      'locale': locale,
      'nickname': nickname,
      'slug': slug,
      'roles': roles,
      'registered_date': registeredDate.toIso8601String(),
      'capabilities': capabilities,
      'extra_capabilities': extraCapabilities,
      'avatar_urls': avatarUrls,
      'meta': meta,
      'acf': acf,
      'is_super_admin': isSuperAdmin,
    };
  }

  String get displayName => name.isNotEmpty ? name : username;
  String get photoURL => avatarUrls['96'] ?? avatarUrls['48'] ?? avatarUrls['24'] ?? '';
  
  ApiUserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? url,
    String? description,
    String? link,
    String? locale,
    String? nickname,
    String? slug,
    List<String>? roles,
    DateTime? registeredDate,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? extraCapabilities,
    Map<String, String>? avatarUrls,
    Map<String, dynamic>? meta,
    List<dynamic>? acf,
    bool? isSuperAdmin,
  }) {
    return ApiUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      url: url ?? this.url,
      description: description ?? this.description,
      link: link ?? this.link,
      locale: locale ?? this.locale,
      nickname: nickname ?? this.nickname,
      slug: slug ?? this.slug,
      roles: roles ?? this.roles,
      registeredDate: registeredDate ?? this.registeredDate,
      capabilities: capabilities ?? this.capabilities,
      extraCapabilities: extraCapabilities ?? this.extraCapabilities,
      avatarUrls: avatarUrls ?? this.avatarUrls,
      meta: meta ?? this.meta,
      acf: acf ?? this.acf,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }
}