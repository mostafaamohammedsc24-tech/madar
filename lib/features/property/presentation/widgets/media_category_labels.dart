import '../../../../core/localization/app_localizations.dart';
import '../../domain/enums/media_category.dart';

extension MediaCategoryLabels on AppLocalizations {
  String labelForMediaCategory(MediaCategory category) {
    switch (category) {
      case MediaCategory.exterior:
        return exterior;
      case MediaCategory.livingRoom:
        return livingRoom;
      case MediaCategory.kitchen:
        return kitchen;
      case MediaCategory.bedroom:
        return bedroom;
      case MediaCategory.masterBedroom:
        return masterBedroom;
      case MediaCategory.bathroom:
        return bathrooms;
      case MediaCategory.garden:
        return garden;
      case MediaCategory.pool:
        return pool;
      case MediaCategory.garage:
        return garage;
      case MediaCategory.roof:
        return roof;
      case MediaCategory.view:
        return viewLabel;
      case MediaCategory.street:
        return street;
      case MediaCategory.commercialArea:
        return commercialArea;
      case MediaCategory.land:
        return landArea;
      case MediaCategory.building:
        return buildingDetails;
      case MediaCategory.floorPlan:
        return floorPlan;
      case MediaCategory.document:
        return documents;
      case MediaCategory.renovationBefore:
        return renovationBefore;
      case MediaCategory.renovationAfter:
        return renovationAfter;
      case MediaCategory.other:
        return otherLabel;
    }
  }
}
