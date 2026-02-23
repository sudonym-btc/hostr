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
  String get swapStatusFundedClaiming => 'Swap funded, claiming...';

  @override
  String get swapStatusClaimedFinalising => 'Swap claimed, finalising...';

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
  String get allowBarter => 'Allow Barter';

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
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
      zero: 'No reviews',
    );
    return '$_temp0';
  }
}
