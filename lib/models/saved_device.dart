class SavedDevice {
  final String ip;
  final String name;
  final DateTime lastSeen;

  const SavedDevice({
    required this.ip,
    required this.name,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'name': name,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory SavedDevice.fromJson(Map<String, dynamic> json) => SavedDevice(
        ip: json['ip'] as String,
        name: json['name'] as String,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
      );

  SavedDevice copyWith({String? name, DateTime? lastSeen}) => SavedDevice(
        ip: ip,
        name: name ?? this.name,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}
