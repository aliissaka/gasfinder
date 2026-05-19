class RegisterRetailerRequest {
  RegisterRetailerRequest({
    required this.ownerPhone,
    required this.pin,
    this.ownerName,
    required this.shopName,
    required this.shopPhone,
    required this.shopLatitude,
    required this.shopLongitude,
    this.shopAddress,
  });

  final String ownerPhone;
  final String pin;
  final String? ownerName;
  final String shopName;
  final String shopPhone;
  final double shopLatitude;
  final double shopLongitude;
  final String? shopAddress;

  Map<String, dynamic> toJson() => {
        'ownerPhone': ownerPhone,
        'pin': pin,
        'ownerName': ownerName,
        'shopName': shopName,
        'shopPhone': shopPhone,
        'shopLatitude': shopLatitude,
        'shopLongitude': shopLongitude,
        'shopAddress': shopAddress,
      };
}
