class BusinessProfile {
  final String businessName;
  final String address;
  final String phone;
  final String invoiceFooter;

  BusinessProfile({
    required this.businessName,
    required this.address,
    required this.phone,
    required this.invoiceFooter,
  });

  BusinessProfile copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? invoiceFooter,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
    );
  }
}
