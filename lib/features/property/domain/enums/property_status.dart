/// Listing / market status for a property.
enum PropertyStatus {
  forSale,
  forRent,
  rentToOwn,
  mortgage,
  sold,
  pending,
  reserved,
  underReview,
  offMarket,
  investment;

  static PropertyStatus fromString(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'sale':
      case 'for_sale':
      case 'for-sale':
        return PropertyStatus.forSale;
      case 'rent':
      case 'for_rent':
      case 'for-rent':
        return PropertyStatus.forRent;
      case 'rent_to_own':
      case 'rent-to-own':
      case 'lease_to_own':
      case 'lto':
        return PropertyStatus.rentToOwn;
      case 'mortgage':
        return PropertyStatus.mortgage;
      case 'sold':
        return PropertyStatus.sold;
      case 'pending':
        return PropertyStatus.pending;
      case 'reserved':
        return PropertyStatus.reserved;
      case 'under_review':
      case 'under-review':
        return PropertyStatus.underReview;
      case 'off_market':
      case 'off-market':
        return PropertyStatus.offMarket;
      case 'investment':
        return PropertyStatus.investment;
      default:
        return PropertyStatus.forSale;
    }
  }

  String get wireValue {
    switch (this) {
      case PropertyStatus.forSale:
        return 'sale';
      case PropertyStatus.forRent:
        return 'rent';
      case PropertyStatus.rentToOwn:
        return 'rent_to_own';
      case PropertyStatus.mortgage:
        return 'mortgage';
      case PropertyStatus.sold:
        return 'sold';
      case PropertyStatus.pending:
        return 'pending';
      case PropertyStatus.reserved:
        return 'reserved';
      case PropertyStatus.underReview:
        return 'under_review';
      case PropertyStatus.offMarket:
        return 'off_market';
      case PropertyStatus.investment:
        return 'investment';
    }
  }
}
