class LoginRequest {
  LoginRequest({required this.phone, required this.pin});

  final String phone;
  final String pin;

  Map<String, dynamic> toJson() => {'phone': phone, 'pin': pin};
}
