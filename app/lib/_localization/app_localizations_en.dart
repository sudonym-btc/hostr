// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hostr';

  @override
  String get host => 'Host';

  @override
  String get guest => 'Guest';

  @override
  String get go => 'Go';

  @override
  String get when => 'When?';

  @override
  String get where => 'Where?';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get proceed => 'Proceed';

  @override
  String get loading => 'Loading';

  @override
  String get hostMode => 'Host Mode';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get selectDates => 'Select Dates';

  @override
  String get requestBooking => 'Request';

  @override
  String get hostedBy => 'hosted by';

  @override
  String get escrow => 'Escrow';

  @override
  String get useEscrow => 'Use Escrow';

  @override
  String get selectEscrow => 'Select Escrow';

  @override
  String get payUpfront => 'Pay Upfront';

  @override
  String get publicKey => 'Public Key';

  @override
  String get privateKey => 'Private Key';

  @override
  String get evmAddress => 'EVM address';

  @override
  String get evmPrivateKey => 'EVM private key';

  @override
  String get connect => 'Connect';

  @override
  String get connected => 'Connected';

  @override
  String get connectedTo => 'Connected to';

  @override
  String get paymentCompleted => 'Payment completed';

  @override
  String get ok => 'Ok';

  @override
  String get paste => 'Paste';

  @override
  String get copy => 'Copy';

  @override
  String get scan => 'Scan';

  @override
  String get send => 'Send';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get wallet => 'Wallet';

  @override
  String get connectWallet => 'Connect Wallet';

  @override
  String get leaveATip => 'Leave a tip?';

  @override
  String get reserve => 'Reserve';

  @override
  String get upcomingReservations => 'Upcoming Reservations';

  @override
  String get reservationRequest => 'Reservation request';

  @override
  String get reservationOffer => 'Reservation offer';

  @override
  String get youSentReservationRequest => 'You sent a reservation request';

  @override
  String get receivedReservationRequest => 'Received reservation offer';

  @override
  String get useEscrowOrNot =>
      'Would you like to use an escrow to settle this transfer?';

  @override
  String get myListings => 'My Listings';

  @override
  String get conversations => 'Conversations';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get accept => 'Accept';

  @override
  String get accepted => 'Accepted';

  @override
  String get refund => 'Refund';

  @override
  String get publish => 'Publish';

  @override
  String get tip => 'Tip';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get zap => 'Zap';

  @override
  String get zapUs => 'Zap us';

  @override
  String get search => 'Search';

  @override
  String get trips => 'Trips';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get pay => 'Pay';

  @override
  String get inbox => 'Inbox';

  @override
  String get yourListings => 'Your Listings';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentCommentLabel => 'Comment';

  @override
  String get paymentCommentHint => 'Add a note';

  @override
  String get processingPayment => 'Processing payment...';

  @override
  String get payInvoiceTitle => 'Pay Invoice';

  @override
  String get payInvoiceSubtitle => 'Pay this lightning invoice to continue';

  @override
  String get invoiceExpired => 'Expired';

  @override
  String get completePaymentInConnectedWallet =>
      'Please complete the payment in your connected wallet';

  @override
  String get paymentCompleteTitle => 'Payment Complete';

  @override
  String get paymentFailedTitle => 'Payment Failed';

  @override
  String get paymentFailed =>
      'Something went wrong with your payment. Please try again.';

  @override
  String get paymentMethodTitle => 'Payment method';

  @override
  String get payDirectly => 'Pay directly';

  @override
  String get openWallet => 'Open wallet';

  @override
  String get swapTitle => 'Swap';

  @override
  String get swapConfirmSubtitle => 'Please confirm to proceed with the swap.';

  @override
  String get swapFailedMessage => 'Swap failed.';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get swapProgressTitle => 'Swap Progress';

  @override
  String get swapStatusWaitingForTransactionConfirm =>
      'Waiting for transaction to confirm...';

  @override
  String get swapStatusInvoicePaidWaitingForTransaction =>
      'Invoice paid, waiting for funds...';

  @override
  String get swapStatusFundedClaiming => 'Swap funded, claiming...';

  @override
  String get swapStatusClaimedFinalising => 'Swap claimed, finalising...';

  @override
  String get swapStatusClaimTxInMempool => 'Claim transaction in mempool...';

  @override
  String get swapStatusRequestCreated => 'Swap request created...';

  @override
  String get swapStatusInvoiceCreatedProcessing =>
      'Invoice created, processing...';

  @override
  String get swapStatusFundedWaitingForPayment =>
      'Swap funded, waiting for payment...';

  @override
  String get swapStatusProcessingRefund => 'Processing refund...';

  @override
  String get swapStatusProcessingYourSwap => 'Processing your swap...';

  @override
  String get swapCompleteTitle => 'Swap Complete';

  @override
  String get swapCompleteSubtitle =>
      'Your swap has been completed successfully.';

  @override
  String get swapFailedTitle => 'Swap Failed';

  @override
  String get withdrawFundsTitle => 'Withdraw Funds';

  @override
  String get continueButton => 'Continue';

  @override
  String get swapRefundedTitle => 'Swap Refunded';

  @override
  String get swapRefundedSubtitle => 'Swap refunded successfully.';

  @override
  String get retryButton => 'Retry';

  @override
  String swapOutExternalInvoiceInstructions(int sats) {
    return 'Create a Lightning invoice for exactly $sats sats in your wallet and paste it below.';
  }

  @override
  String get lightningInvoiceLabel => 'Lightning Invoice';

  @override
  String get lightningInvoiceHint => 'lnbc…';

  @override
  String get pasteLightningInvoiceRequired =>
      'Please paste a Lightning invoice.';

  @override
  String get blockedDates => 'Blocked Dates';

  @override
  String get noBlockedDates => 'No blocked dates.';

  @override
  String get blockDates => 'Block Dates';

  @override
  String get reviewMessageLabel => 'Message';

  @override
  String get reviewHint => 'Tell others about your stay';

  @override
  String get reviewRatingLabel => 'Rating';

  @override
  String get reviewRequired => 'Review is required';

  @override
  String get ratingMustBeBetween1And5 => 'Rating must be between 1 and 5';

  @override
  String get perDayLabel => ' / day ';

  @override
  String get clear => 'Clear';

  @override
  String get errorLabel => 'Error';

  @override
  String get registerPeriodicBackgroundAppRefreshIos =>
      'Register Periodic Background App Refresh (iOS)';

  @override
  String get registerBackgroundProcessingTaskIos =>
      'Register BackgroundProcessingTask (iOS)';

  @override
  String get refreshStats => 'Refresh stats';

  @override
  String get workmanagerNotInitialized => 'Workmanager not initialized';

  @override
  String get workmanagerNotInitializedMessage =>
      'Workmanager is not initialized, please initialize';

  @override
  String get noPermission => 'No permission';

  @override
  String get negotiable => 'Negotiable';

  @override
  String get start => 'start';

  @override
  String get end => 'end';

  @override
  String get addImage => 'Add Image';

  @override
  String get dev => 'Dev';

  @override
  String get swapIn => 'Swap in';

  @override
  String get bolt11 => 'Bolt11';

  @override
  String errorWithDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get nsec => 'nsec';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String copiedH3Indexes(int count) {
    return 'Copied $count H3 indexes';
  }

  @override
  String get copyH3Indexes => 'Copy H3 indexes';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelReservation => 'Cancel Reservation';

  @override
  String get noWalletConnected => 'No wallet connected';

  @override
  String get errorLoadingEscrows => 'Error loading escrows';

  @override
  String get noCompatibleEscrowsFound => 'No compatible escrows found';

  @override
  String get estimatingFees => 'Estimating fees...';

  @override
  String get close => 'Close';

  @override
  String get publicKeyCopied => 'Public key copied';

  @override
  String get actionNotImplementedYet => 'Action not implemented yet';

  @override
  String couldNotConnectNwcProvider(String details) {
    return 'Could not connect to NWC provider: $details';
  }

  @override
  String timelineEventType(String type) {
    return 'Timeline Event $type';
  }

  @override
  String get boltz => 'Boltz';

  @override
  String get rootstock => 'Rootstock';

  @override
  String get connectAppToWallet => 'Connect app to wallet';

  @override
  String get uriCopiedToClipboard => 'URI copied to clipboard';

  @override
  String get copyWords => 'Copy words';

  @override
  String get recoveryWordsCopied => 'Recovery words copied';

  @override
  String get done => 'Done';

  @override
  String labelCopied(String label) {
    return '$label copied';
  }

  @override
  String get withdraw => 'Withdraw';

  @override
  String get noItems => 'No items';

  @override
  String get unknownMessageType => 'Unknown message type';

  @override
  String get noProfileSetUpYet => 'No profile set up yet';

  @override
  String get setupYourProfile => 'Set up your profile';

  @override
  String get youMightWantToJotThisDown => 'You might want to jot this down';

  @override
  String get mnemonic => 'Mnemonic';

  @override
  String get startFlutterBackgroundService =>
      'Start the Flutter background service';

  @override
  String get frequencyLabel => 'Frequency:';

  @override
  String get minutes15 => '15 minutes';

  @override
  String get minutes30 => '30 minutes';

  @override
  String get hour1 => '1 hour';

  @override
  String get cancelAll => 'Cancel All';

  @override
  String get noEscrowsTrustedYet => 'No escrows trusted yet';

  @override
  String errorGeneric(String details) {
    return 'Something went wrong: $details';
  }

  @override
  String searchResultCount(int count, String hasMore) {
    String _temp0 = intl.Intl.selectLogic(hasMore, {'true': '+', 'other': ''});
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'results',
      one: 'result',
    );
    return '$count$_temp0 $_temp1';
  }

  @override
  String get reviewsLabel => 'reviews';

  @override
  String get staysLabel => 'stays';

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
      zero: '0 reviews',
    );
    return '$_temp0';
  }

  @override
  String stayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stays',
      one: '1 stay',
      zero: '0 stays',
    );
    return '$_temp0';
  }

  @override
  String specificationAirconditioning(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Air conditioning',
      one: 'Air conditioning',
      zero: 'Air conditioning',
    );
    return '$_temp0';
  }

  @override
  String specificationAllowsPets(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pets allowed',
      one: 'Pets allowed',
      zero: 'Pets allowed',
    );
    return '$_temp0';
  }

  @override
  String specificationBathrooms(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bathrooms',
      one: '1 bathroom',
      zero: 'Bathrooms',
    );
    return '$_temp0';
  }

  @override
  String specificationBathtub(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bathtubs',
      one: '1 bathtub',
      zero: 'Bathtubs',
    );
    return '$_temp0';
  }

  @override
  String specificationBeds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beds',
      one: '1 bed',
      zero: 'Beds',
    );
    return '$_temp0';
  }

  @override
  String specificationBedrooms(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bedrooms',
      one: '1 bedroom',
      zero: 'Bedrooms',
    );
    return '$_temp0';
  }

  @override
  String specificationMaxGuests(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests max',
      one: '1 guest max',
      zero: 'Max guests',
    );
    return '$_temp0';
  }

  @override
  String specificationTv(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count TVs',
      one: '1 TV',
      zero: 'TV',
    );
    return '$_temp0';
  }

  @override
  String specificationCrib(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cribs',
      one: 'Crib',
      zero: 'Crib',
    );
    return '$_temp0';
  }

  @override
  String specificationTumbleDryer(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tumble dryers',
      one: 'Tumble dryer',
      zero: 'Tumble dryer',
    );
    return '$_temp0';
  }

  @override
  String specificationWasher(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Washers',
      one: 'Washer',
      zero: 'Washer',
    );
    return '$_temp0';
  }

  @override
  String specificationElevator(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Elevators',
      one: 'Elevator',
      zero: 'Elevator',
    );
    return '$_temp0';
  }

  @override
  String specificationFreeParking(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Free parking',
      one: 'Free parking',
      zero: 'Free parking',
    );
    return '$_temp0';
  }

  @override
  String specificationGym(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gyms',
      one: 'Gym',
      zero: 'Gym',
    );
    return '$_temp0';
  }

  @override
  String specificationHairDryer(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hair dryers',
      one: 'Hair dryer',
      zero: 'Hair dryer',
    );
    return '$_temp0';
  }

  @override
  String specificationHeating(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heating',
      one: 'Heating',
      zero: 'Heating',
    );
    return '$_temp0';
  }

  @override
  String specificationHighChair(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'High chairs',
      one: 'High chair',
      zero: 'High chair',
    );
    return '$_temp0';
  }

  @override
  String specificationWirelessInternet(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wi-Fi',
      one: 'Wi-Fi',
      zero: 'Wi-Fi',
    );
    return '$_temp0';
  }

  @override
  String specificationIron(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Irons',
      one: 'Iron',
      zero: 'Iron',
    );
    return '$_temp0';
  }

  @override
  String specificationJacuzzi(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jacuzzis',
      one: 'Jacuzzi',
      zero: 'Jacuzzi',
    );
    return '$_temp0';
  }

  @override
  String specificationKitchen(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kitchens',
      one: 'Kitchen',
      zero: 'Kitchen',
    );
    return '$_temp0';
  }

  @override
  String specificationOutletCovers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Outlet covers',
      one: 'Outlet cover',
      zero: 'Outlet covers',
    );
    return '$_temp0';
  }

  @override
  String specificationPool(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pools',
      one: 'Pool',
      zero: 'Pool',
    );
    return '$_temp0';
  }

  @override
  String specificationPrivateEntrance(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Private entrances',
      one: 'Private entrance',
      zero: 'Private entrance',
    );
    return '$_temp0';
  }

  @override
  String specificationSmokingAllowed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Smoking allowed',
      one: 'Smoking allowed',
      zero: 'Smoking allowed',
    );
    return '$_temp0';
  }

  @override
  String specificationBreakfast(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Breakfast',
      one: 'Breakfast',
      zero: 'Breakfast',
    );
    return '$_temp0';
  }

  @override
  String specificationFireplace(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fireplaces',
      one: 'Fireplace',
      zero: 'Fireplace',
    );
    return '$_temp0';
  }

  @override
  String specificationSmokeDetector(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Smoke detectors',
      one: 'Smoke detector',
      zero: 'Smoke detector',
    );
    return '$_temp0';
  }

  @override
  String specificationEssentials(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Essentials',
      one: 'Essentials',
      zero: 'Essentials',
    );
    return '$_temp0';
  }

  @override
  String specificationShampoo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shampoo',
      one: 'Shampoo',
      zero: 'Shampoo',
    );
    return '$_temp0';
  }

  @override
  String specificationInfantsAllowed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Infants allowed',
      one: 'Infants allowed',
      zero: 'Infants allowed',
    );
    return '$_temp0';
  }

  @override
  String specificationChildrenAllowed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Children allowed',
      one: 'Children allowed',
      zero: 'Children allowed',
    );
    return '$_temp0';
  }

  @override
  String specificationHangers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hangers',
      one: 'Hanger',
      zero: 'Hangers',
    );
    return '$_temp0';
  }

  @override
  String specificationFlatSmoothPathwayToFrontDoor(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Flat, smooth pathways to front door',
      one: 'Flat, smooth pathway to front door',
      zero: 'Flat, smooth pathway to front door',
    );
    return '$_temp0';
  }

  @override
  String specificationGrabRailsInShowerAndToilet(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grab rails in shower and toilet',
      one: 'Grab rail in shower and toilet',
      zero: 'Grab rails in shower and toilet',
    );
    return '$_temp0';
  }

  @override
  String specificationOven(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ovens',
      one: 'Oven',
      zero: 'Oven',
    );
    return '$_temp0';
  }

  @override
  String specificationBbq(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'BBQs',
      one: 'BBQ',
      zero: 'BBQ',
    );
    return '$_temp0';
  }

  @override
  String specificationBalcony(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Balconies',
      one: 'Balcony',
      zero: 'Balcony',
    );
    return '$_temp0';
  }

  @override
  String specificationPatio(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Patios',
      one: 'Patio',
      zero: 'Patio',
    );
    return '$_temp0';
  }

  @override
  String specificationDishwasher(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dishwashers',
      one: 'Dishwasher',
      zero: 'Dishwasher',
    );
    return '$_temp0';
  }

  @override
  String specificationRefrigerator(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Refrigerators',
      one: 'Refrigerator',
      zero: 'Refrigerator',
    );
    return '$_temp0';
  }

  @override
  String specificationGardenOrBackyard(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gardens or backyards',
      one: 'Garden or backyard',
      zero: 'Garden or backyard',
    );
    return '$_temp0';
  }

  @override
  String specificationMicrowave(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Microwaves',
      one: 'Microwave',
      zero: 'Microwave',
    );
    return '$_temp0';
  }

  @override
  String specificationCoffeeMaker(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Coffee makers',
      one: 'Coffee maker',
      zero: 'Coffee maker',
    );
    return '$_temp0';
  }

  @override
  String specificationDishesAndSilverware(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dishes and silverware',
      one: 'Dishes and silverware',
      zero: 'Dishes and silverware',
    );
    return '$_temp0';
  }

  @override
  String specificationStove(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stoves',
      one: 'Stove',
      zero: 'Stove',
    );
    return '$_temp0';
  }

  @override
  String specificationFireExtinguisher(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fire extinguishers',
      one: 'Fire extinguisher',
      zero: 'Fire extinguisher',
    );
    return '$_temp0';
  }

  @override
  String specificationCarbonMonoxideDetector(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Carbon monoxide detectors',
      one: 'Carbon monoxide detector',
      zero: 'Carbon monoxide detector',
    );
    return '$_temp0';
  }

  @override
  String specificationLuggageDropoffAllowed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Luggage drop-off allowed',
      one: 'Luggage drop-off allowed',
      zero: 'Luggage drop-off allowed',
    );
    return '$_temp0';
  }

  @override
  String specificationBeachEssentials(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Beach essentials',
      one: 'Beach essentials',
      zero: 'Beach essentials',
    );
    return '$_temp0';
  }

  @override
  String specificationBeachfront(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Beachfront',
      one: 'Beachfront',
      zero: 'Beachfront',
    );
    return '$_temp0';
  }

  @override
  String specificationBabyMonitor(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Baby monitors',
      one: 'Baby monitor',
      zero: 'Baby monitor',
    );
    return '$_temp0';
  }

  @override
  String specificationBabysitterRecommendations(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Babysitter recommendations',
      one: 'Babysitter recommendation',
      zero: 'Babysitter recommendations',
    );
    return '$_temp0';
  }

  @override
  String specificationChildrensBooksAndToys(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Children\'s books and toys',
      one: 'Children\'s book and toy',
      zero: 'Children\'s books and toys',
    );
    return '$_temp0';
  }

  @override
  String specificationGameConsole(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Game consoles',
      one: 'Game console',
      zero: 'Game console',
    );
    return '$_temp0';
  }

  @override
  String specificationStreetParking(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Street parking',
      one: 'Street parking',
      zero: 'Street parking',
    );
    return '$_temp0';
  }

  @override
  String specificationPaidParking(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paid parking',
      one: 'Paid parking',
      zero: 'Paid parking',
    );
    return '$_temp0';
  }

  @override
  String specificationHotWater(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hot water',
      one: 'Hot water',
      zero: 'Hot water',
    );
    return '$_temp0';
  }

  @override
  String specificationLakeAccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lake access',
      one: 'Lake access',
      zero: 'Lake access',
    );
    return '$_temp0';
  }

  @override
  String specificationSingleLevelHome(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Single-level homes',
      one: 'Single-level home',
      zero: 'Single-level home',
    );
    return '$_temp0';
  }

  @override
  String specificationWaterfront(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Waterfront',
      one: 'Waterfront',
      zero: 'Waterfront',
    );
    return '$_temp0';
  }

  @override
  String specificationFirstAidKit(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'First aid kits',
      one: 'First aid kit',
      zero: 'First aid kit',
    );
    return '$_temp0';
  }

  @override
  String specificationHandheldShowerHead(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Handheld shower heads',
      one: 'Handheld shower head',
      zero: 'Handheld shower head',
    );
    return '$_temp0';
  }

  @override
  String specificationHomeStepFreeAccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Step-free home access',
      one: 'Step-free home access',
      zero: 'Step-free home access',
    );
    return '$_temp0';
  }

  @override
  String specificationLockOnBedroomDoor(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Locks on bedroom doors',
      one: 'Lock on bedroom door',
      zero: 'Lock on bedroom door',
    );
    return '$_temp0';
  }

  @override
  String specificationMobileHoist(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mobile hoists',
      one: 'Mobile hoist',
      zero: 'Mobile hoist',
    );
    return '$_temp0';
  }

  @override
  String specificationPathToEntranceLitAtNight(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paths to entrance lit at night',
      one: 'Path to entrance lit at night',
      zero: 'Path to entrance lit at night',
    );
    return '$_temp0';
  }

  @override
  String specificationPoolHoist(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pool hoists',
      one: 'Pool hoist',
      zero: 'Pool hoist',
    );
    return '$_temp0';
  }

  @override
  String specificationEvCharger(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'EV chargers',
      one: 'EV charger',
      zero: 'EV charger',
    );
    return '$_temp0';
  }

  @override
  String specificationRollinShower(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Roll-in showers',
      one: 'Roll-in shower',
      zero: 'Roll-in shower',
    );
    return '$_temp0';
  }

  @override
  String specificationShowerChair(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shower chairs',
      one: 'Shower chair',
      zero: 'Shower chair',
    );
    return '$_temp0';
  }

  @override
  String specificationTubWithShowerBench(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tubs with shower benches',
      one: 'Tub with shower bench',
      zero: 'Tub with shower bench',
    );
    return '$_temp0';
  }

  @override
  String specificationWideClearanceToBed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wide clearances to beds',
      one: 'Wide clearance to bed',
      zero: 'Wide clearance to bed',
    );
    return '$_temp0';
  }

  @override
  String specificationWideClearanceToShowerAndToilet(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wide clearances to showers and toilets',
      one: 'Wide clearance to shower and toilet',
      zero: 'Wide clearance to shower and toilet',
    );
    return '$_temp0';
  }

  @override
  String specificationWideHallwayClearance(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wide hallway clearances',
      one: 'Wide hallway clearance',
      zero: 'Wide hallway clearance',
    );
    return '$_temp0';
  }

  @override
  String specificationBabyBath(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Baby baths',
      one: 'Baby bath',
      zero: 'Baby bath',
    );
    return '$_temp0';
  }

  @override
  String specificationChangingTable(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Changing tables',
      one: 'Changing table',
      zero: 'Changing table',
    );
    return '$_temp0';
  }

  @override
  String specificationRoomDarkeningShades(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Room-darkening shades',
      one: 'Room-darkening shade',
      zero: 'Room-darkening shades',
    );
    return '$_temp0';
  }

  @override
  String specificationStairGates(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stair gates',
      one: 'Stair gate',
      zero: 'Stair gates',
    );
    return '$_temp0';
  }

  @override
  String specificationTableCornerGuards(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Table corner guards',
      one: 'Table corner guard',
      zero: 'Table corner guards',
    );
    return '$_temp0';
  }

  @override
  String specificationExtraPillowsAndBlankets(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Extra pillows and blankets',
      one: 'Extra pillow and blanket',
      zero: 'Extra pillows and blankets',
    );
    return '$_temp0';
  }

  @override
  String specificationSkiInSkiOut(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ski-in/ski-out',
      one: 'Ski-in/ski-out',
      zero: 'Ski-in/ski-out',
    );
    return '$_temp0';
  }

  @override
  String specificationWindowGuards(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Window guards',
      one: 'Window guard',
      zero: 'Window guards',
    );
    return '$_temp0';
  }

  @override
  String specificationDisabledParkingSpot(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Disabled parking spots',
      one: 'Disabled parking spot',
      zero: 'Disabled parking spot',
    );
    return '$_temp0';
  }

  @override
  String specificationGrabRailsInToilet(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grab rails in toilet',
      one: 'Grab rail in toilet',
      zero: 'Grab rails in toilet',
    );
    return '$_temp0';
  }

  @override
  String specificationEventsAllowed(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Events allowed',
      one: 'Events allowed',
      zero: 'Events allowed',
    );
    return '$_temp0';
  }

  @override
  String specificationCommonSpacesShared(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared common spaces',
      one: 'Shared common space',
      zero: 'Shared common spaces',
    );
    return '$_temp0';
  }

  @override
  String specificationBathroomShared(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared bathrooms',
      one: 'Shared bathroom',
      zero: 'Shared bathroom',
    );
    return '$_temp0';
  }

  @override
  String specificationSecurityCameras(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Security cameras',
      one: 'Security camera',
      zero: 'Security cameras',
    );
    return '$_temp0';
  }
}
