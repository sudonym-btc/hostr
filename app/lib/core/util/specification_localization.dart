import 'package:flutter/widgets.dart';
import 'package:hostr/_localization/app_localizations.dart';

import 'convert_to_title_case.dart';

String localizedSpecification(
  BuildContext context,
  String key, {
  num count = 0,
}) {
  return localizedSpecificationFromL10n(
    AppLocalizations.of(context)!,
    key,
    count: count,
  );
}

String localizedSpecificationFromL10n(
  AppLocalizations l10n,
  String key, {
  num count = 0,
}) {
  return switch (key) {
    'airconditioning' => l10n.specificationAirconditioning(count),
    'allows_pets' => l10n.specificationAllowsPets(count),
    'bathrooms' => l10n.specificationBathrooms(count),
    'bathtub' => l10n.specificationBathtub(count),
    'beds' => l10n.specificationBeds(count),
    'bedrooms' => l10n.specificationBedrooms(count),
    'max_guests' => l10n.specificationMaxGuests(count),
    'tv' => l10n.specificationTv(count),
    'crib' => l10n.specificationCrib(count),
    'tumble_dryer' => l10n.specificationTumbleDryer(count),
    'washer' => l10n.specificationWasher(count),
    'elevator' => l10n.specificationElevator(count),
    'free_parking' => l10n.specificationFreeParking(count),
    'gym' => l10n.specificationGym(count),
    'hair_dryer' => l10n.specificationHairDryer(count),
    'heating' => l10n.specificationHeating(count),
    'high_chair' => l10n.specificationHighChair(count),
    'wireless_internet' => l10n.specificationWirelessInternet(count),
    'iron' => l10n.specificationIron(count),
    'jacuzzi' => l10n.specificationJacuzzi(count),
    'kitchen' => l10n.specificationKitchen(count),
    'outlet_covers' => l10n.specificationOutletCovers(count),
    'pool' => l10n.specificationPool(count),
    'private_entrance' => l10n.specificationPrivateEntrance(count),
    'smoking_allowed' => l10n.specificationSmokingAllowed(count),
    'breakfast' => l10n.specificationBreakfast(count),
    'fireplace' => l10n.specificationFireplace(count),
    'smoke_detector' => l10n.specificationSmokeDetector(count),
    'essentials' => l10n.specificationEssentials(count),
    'shampoo' => l10n.specificationShampoo(count),
    'infants_allowed' => l10n.specificationInfantsAllowed(count),
    'children_allowed' => l10n.specificationChildrenAllowed(count),
    'hangers' => l10n.specificationHangers(count),
    'flat_smooth_pathway_to_front_door' =>
      l10n.specificationFlatSmoothPathwayToFrontDoor(count),
    'grab_rails_in_shower_and_toilet' =>
      l10n.specificationGrabRailsInShowerAndToilet(count),
    'oven' => l10n.specificationOven(count),
    'bbq' => l10n.specificationBbq(count),
    'balcony' => l10n.specificationBalcony(count),
    'patio' => l10n.specificationPatio(count),
    'dishwasher' => l10n.specificationDishwasher(count),
    'refrigerator' => l10n.specificationRefrigerator(count),
    'garden_or_backyard' => l10n.specificationGardenOrBackyard(count),
    'microwave' => l10n.specificationMicrowave(count),
    'coffee_maker' => l10n.specificationCoffeeMaker(count),
    'dishes_and_silverware' => l10n.specificationDishesAndSilverware(count),
    'stove' => l10n.specificationStove(count),
    'fire_extinguisher' => l10n.specificationFireExtinguisher(count),
    'carbon_monoxide_detector' => l10n.specificationCarbonMonoxideDetector(
      count,
    ),
    'luggage_dropoff_allowed' => l10n.specificationLuggageDropoffAllowed(count),
    'beach_essentials' => l10n.specificationBeachEssentials(count),
    'beachfront' => l10n.specificationBeachfront(count),
    'baby_monitor' => l10n.specificationBabyMonitor(count),
    'babysitter_recommendations' => l10n.specificationBabysitterRecommendations(
      count,
    ),
    'childrens_books_and_toys' => l10n.specificationChildrensBooksAndToys(
      count,
    ),
    'game_console' => l10n.specificationGameConsole(count),
    'street_parking' => l10n.specificationStreetParking(count),
    'paid_parking' => l10n.specificationPaidParking(count),
    'hot_water' => l10n.specificationHotWater(count),
    'lake_access' => l10n.specificationLakeAccess(count),
    'single_level_home' => l10n.specificationSingleLevelHome(count),
    'waterfront' => l10n.specificationWaterfront(count),
    'first_aid_kit' => l10n.specificationFirstAidKit(count),
    'handheld_shower_head' => l10n.specificationHandheldShowerHead(count),
    'home_step_free_access' => l10n.specificationHomeStepFreeAccess(count),
    'lock_on_bedroom_door' => l10n.specificationLockOnBedroomDoor(count),
    'mobile_hoist' => l10n.specificationMobileHoist(count),
    'path_to_entrance_lit_at_night' =>
      l10n.specificationPathToEntranceLitAtNight(count),
    'pool_hoist' => l10n.specificationPoolHoist(count),
    'ev_charger' => l10n.specificationEvCharger(count),
    'rollin_shower' => l10n.specificationRollinShower(count),
    'shower_chair' => l10n.specificationShowerChair(count),
    'tub_with_shower_bench' => l10n.specificationTubWithShowerBench(count),
    'wide_clearance_to_bed' => l10n.specificationWideClearanceToBed(count),
    'wide_clearance_to_shower_and_toilet' =>
      l10n.specificationWideClearanceToShowerAndToilet(count),
    'wide_hallway_clearance' => l10n.specificationWideHallwayClearance(count),
    'baby_bath' => l10n.specificationBabyBath(count),
    'changing_table' => l10n.specificationChangingTable(count),
    'room_darkening_shades' => l10n.specificationRoomDarkeningShades(count),
    'stair_gates' => l10n.specificationStairGates(count),
    'table_corner_guards' => l10n.specificationTableCornerGuards(count),
    'extra_pillows_and_blankets' => l10n.specificationExtraPillowsAndBlankets(
      count,
    ),
    'ski_in_ski_out' => l10n.specificationSkiInSkiOut(count),
    'window_guards' => l10n.specificationWindowGuards(count),
    'disabled_parking_spot' => l10n.specificationDisabledParkingSpot(count),
    'grab_rails_in_toilet' => l10n.specificationGrabRailsInToilet(count),
    'events_allowed' => l10n.specificationEventsAllowed(count),
    'common_spaces_shared' => l10n.specificationCommonSpacesShared(count),
    'bathroom_shared' => l10n.specificationBathroomShared(count),
    'security_cameras' => l10n.specificationSecurityCameras(count),
    _ => convertToTitleCase(key),
  };
}
