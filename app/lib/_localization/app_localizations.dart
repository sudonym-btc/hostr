import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import '_localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hostr'**
  String get appTitle;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get when;

  /// No description provided for @where.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get where;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @hostMode.
  ///
  /// In en, this message translates to:
  /// **'Host Mode'**
  String get hostMode;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select Dates'**
  String get selectDates;

  /// No description provided for @requestBooking.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestBooking;

  /// No description provided for @hostedBy.
  ///
  /// In en, this message translates to:
  /// **'hosted by'**
  String get hostedBy;

  /// No description provided for @escrow.
  ///
  /// In en, this message translates to:
  /// **'Escrow'**
  String get escrow;

  /// No description provided for @useEscrow.
  ///
  /// In en, this message translates to:
  /// **'Use Escrow'**
  String get useEscrow;

  /// No description provided for @selectEscrow.
  ///
  /// In en, this message translates to:
  /// **'Select Escrow'**
  String get selectEscrow;

  /// No description provided for @payUpfront.
  ///
  /// In en, this message translates to:
  /// **'Pay Upfront'**
  String get payUpfront;

  /// No description provided for @publicKey.
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get publicKey;

  /// No description provided for @privateKey.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get privateKey;

  /// No description provided for @evmAddress.
  ///
  /// In en, this message translates to:
  /// **'EVM address'**
  String get evmAddress;

  /// No description provided for @evmPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'EVM private key'**
  String get evmPrivateKey;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to'**
  String get connectedTo;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment completed'**
  String get paymentCompleted;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @connectWallet.
  ///
  /// In en, this message translates to:
  /// **'Connect Wallet'**
  String get connectWallet;

  /// No description provided for @leaveATip.
  ///
  /// In en, this message translates to:
  /// **'Leave a tip?'**
  String get leaveATip;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @upcomingReservations.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Reservations'**
  String get upcomingReservations;

  /// No description provided for @reservationRequest.
  ///
  /// In en, this message translates to:
  /// **'Reservation request'**
  String get reservationRequest;

  /// No description provided for @reservationOffer.
  ///
  /// In en, this message translates to:
  /// **'Reservation offer'**
  String get reservationOffer;

  /// No description provided for @youSentReservationRequest.
  ///
  /// In en, this message translates to:
  /// **'You sent a reservation request'**
  String get youSentReservationRequest;

  /// No description provided for @receivedReservationRequest.
  ///
  /// In en, this message translates to:
  /// **'Received reservation offer'**
  String get receivedReservationRequest;

  /// No description provided for @useEscrowOrNot.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use an escrow to settle this transfer?'**
  String get useEscrowOrNot;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @zap.
  ///
  /// In en, this message translates to:
  /// **'Zap'**
  String get zap;

  /// No description provided for @zapUs.
  ///
  /// In en, this message translates to:
  /// **'Zap us'**
  String get zapUs;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @yourListings.
  ///
  /// In en, this message translates to:
  /// **'Your Listings'**
  String get yourListings;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get processingPayment;

  /// No description provided for @payInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay Invoice'**
  String get payInvoiceTitle;

  /// No description provided for @payInvoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay this lightning invoice to continue'**
  String get payInvoiceSubtitle;

  /// No description provided for @invoiceExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get invoiceExpired;

  /// No description provided for @completePaymentInConnectedWallet.
  ///
  /// In en, this message translates to:
  /// **'Please complete the payment in your connected wallet'**
  String get completePaymentInConnectedWallet;

  /// No description provided for @paymentCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Complete'**
  String get paymentCompleteTitle;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with your payment. Please try again.'**
  String get paymentFailed;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodTitle;

  /// No description provided for @payDirectly.
  ///
  /// In en, this message translates to:
  /// **'Pay directly'**
  String get payDirectly;

  /// No description provided for @openWallet.
  ///
  /// In en, this message translates to:
  /// **'Open wallet'**
  String get openWallet;

  /// No description provided for @swapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swapTitle;

  /// No description provided for @swapConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please confirm to proceed with the swap.'**
  String get swapConfirmSubtitle;

  /// No description provided for @swapFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Swap failed.'**
  String get swapFailedMessage;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @swapProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap Progress'**
  String get swapProgressTitle;

  /// No description provided for @swapStatusWaitingForTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for transaction to confirm...'**
  String get swapStatusWaitingForTransactionConfirm;

  /// No description provided for @swapStatusFundedClaiming.
  ///
  /// In en, this message translates to:
  /// **'Swap funded, claiming...'**
  String get swapStatusFundedClaiming;

  /// No description provided for @swapStatusClaimedFinalising.
  ///
  /// In en, this message translates to:
  /// **'Swap claimed, finalising...'**
  String get swapStatusClaimedFinalising;

  /// No description provided for @swapStatusRequestCreated.
  ///
  /// In en, this message translates to:
  /// **'Swap request created...'**
  String get swapStatusRequestCreated;

  /// No description provided for @swapStatusInvoiceCreatedProcessing.
  ///
  /// In en, this message translates to:
  /// **'Invoice created, processing...'**
  String get swapStatusInvoiceCreatedProcessing;

  /// No description provided for @swapStatusFundedWaitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Swap funded, waiting for payment...'**
  String get swapStatusFundedWaitingForPayment;

  /// No description provided for @swapStatusProcessingRefund.
  ///
  /// In en, this message translates to:
  /// **'Processing refund...'**
  String get swapStatusProcessingRefund;

  /// No description provided for @swapStatusProcessingYourSwap.
  ///
  /// In en, this message translates to:
  /// **'Processing your swap...'**
  String get swapStatusProcessingYourSwap;

  /// No description provided for @swapCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap Complete'**
  String get swapCompleteTitle;

  /// No description provided for @swapCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your swap has been completed successfully.'**
  String get swapCompleteSubtitle;

  /// No description provided for @swapFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap Failed'**
  String get swapFailedTitle;

  /// No description provided for @withdrawFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFundsTitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @swapRefundedTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap Refunded'**
  String get swapRefundedTitle;

  /// No description provided for @swapRefundedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swap refunded successfully.'**
  String get swapRefundedSubtitle;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Instructions for providing an external Lightning invoice
  ///
  /// In en, this message translates to:
  /// **'Create a Lightning invoice for exactly {sats} sats in your wallet and paste it below.'**
  String swapOutExternalInvoiceInstructions(int sats);

  /// No description provided for @lightningInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Lightning Invoice'**
  String get lightningInvoiceLabel;

  /// No description provided for @lightningInvoiceHint.
  ///
  /// In en, this message translates to:
  /// **'lnbc…'**
  String get lightningInvoiceHint;

  /// No description provided for @pasteLightningInvoiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please paste a Lightning invoice.'**
  String get pasteLightningInvoiceRequired;

  /// No description provided for @blockedDates.
  ///
  /// In en, this message translates to:
  /// **'Blocked Dates'**
  String get blockedDates;

  /// No description provided for @noBlockedDates.
  ///
  /// In en, this message translates to:
  /// **'No blocked dates.'**
  String get noBlockedDates;

  /// No description provided for @blockDates.
  ///
  /// In en, this message translates to:
  /// **'Block Dates'**
  String get blockDates;

  /// No description provided for @reviewMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get reviewMessageLabel;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about your stay'**
  String get reviewHint;

  /// No description provided for @reviewRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get reviewRatingLabel;

  /// No description provided for @reviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review is required'**
  String get reviewRequired;

  /// No description provided for @ratingMustBeBetween1And5.
  ///
  /// In en, this message translates to:
  /// **'Rating must be between 1 and 5'**
  String get ratingMustBeBetween1And5;

  /// No description provided for @perDayLabel.
  ///
  /// In en, this message translates to:
  /// **' / day '**
  String get perDayLabel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @registerPeriodicBackgroundAppRefreshIos.
  ///
  /// In en, this message translates to:
  /// **'Register Periodic Background App Refresh (iOS)'**
  String get registerPeriodicBackgroundAppRefreshIos;

  /// No description provided for @registerBackgroundProcessingTaskIos.
  ///
  /// In en, this message translates to:
  /// **'Register BackgroundProcessingTask (iOS)'**
  String get registerBackgroundProcessingTaskIos;

  /// No description provided for @refreshStats.
  ///
  /// In en, this message translates to:
  /// **'Refresh stats'**
  String get refreshStats;

  /// No description provided for @workmanagerNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Workmanager not initialized'**
  String get workmanagerNotInitialized;

  /// No description provided for @workmanagerNotInitializedMessage.
  ///
  /// In en, this message translates to:
  /// **'Workmanager is not initialized, please initialize'**
  String get workmanagerNotInitializedMessage;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission'**
  String get noPermission;

  /// No description provided for @allowBarter.
  ///
  /// In en, this message translates to:
  /// **'Allow Barter'**
  String get allowBarter;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'end'**
  String get end;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @dev.
  ///
  /// In en, this message translates to:
  /// **'Dev'**
  String get dev;

  /// No description provided for @swapIn.
  ///
  /// In en, this message translates to:
  /// **'Swap in'**
  String get swapIn;

  /// No description provided for @bolt11.
  ///
  /// In en, this message translates to:
  /// **'Bolt11'**
  String get bolt11;

  /// Error text with details
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorWithDetails(String details);

  /// No description provided for @nsec.
  ///
  /// In en, this message translates to:
  /// **'nsec'**
  String get nsec;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Snackbar text after copying H3 indexes
  ///
  /// In en, this message translates to:
  /// **'Copied {count} H3 indexes'**
  String copiedH3Indexes(int count);

  /// No description provided for @copyH3Indexes.
  ///
  /// In en, this message translates to:
  /// **'Copy H3 indexes'**
  String get copyH3Indexes;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noWalletConnected.
  ///
  /// In en, this message translates to:
  /// **'No wallet connected'**
  String get noWalletConnected;

  /// No description provided for @errorLoadingEscrows.
  ///
  /// In en, this message translates to:
  /// **'Error loading escrows'**
  String get errorLoadingEscrows;

  /// No description provided for @noCompatibleEscrowsFound.
  ///
  /// In en, this message translates to:
  /// **'No compatible escrows found'**
  String get noCompatibleEscrowsFound;

  /// No description provided for @estimatingFees.
  ///
  /// In en, this message translates to:
  /// **'Estimating fees...'**
  String get estimatingFees;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @publicKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get publicKeyCopied;

  /// No description provided for @actionNotImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'Action not implemented yet'**
  String get actionNotImplementedYet;

  /// Error shown when NWC connection fails
  ///
  /// In en, this message translates to:
  /// **'Could not connect to NWC provider: {details}'**
  String couldNotConnectNwcProvider(String details);

  /// Fallback timeline label for unknown event types
  ///
  /// In en, this message translates to:
  /// **'Timeline Event {type}'**
  String timelineEventType(String type);

  /// No description provided for @boltz.
  ///
  /// In en, this message translates to:
  /// **'Boltz'**
  String get boltz;

  /// No description provided for @rootstock.
  ///
  /// In en, this message translates to:
  /// **'Rootstock'**
  String get rootstock;

  /// No description provided for @connectAppToWallet.
  ///
  /// In en, this message translates to:
  /// **'Connect app to wallet'**
  String get connectAppToWallet;

  /// No description provided for @uriCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'URI copied to clipboard'**
  String get uriCopiedToClipboard;

  /// No description provided for @copyWords.
  ///
  /// In en, this message translates to:
  /// **'Copy words'**
  String get copyWords;

  /// No description provided for @recoveryWordsCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery words copied'**
  String get recoveryWordsCopied;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Copied confirmation with object label
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String labelCopied(String label);

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @unknownMessageType.
  ///
  /// In en, this message translates to:
  /// **'Unknown message type'**
  String get unknownMessageType;

  /// No description provided for @noProfileSetUpYet.
  ///
  /// In en, this message translates to:
  /// **'No profile set up yet'**
  String get noProfileSetUpYet;

  /// No description provided for @youMightWantToJotThisDown.
  ///
  /// In en, this message translates to:
  /// **'You might want to jot this down'**
  String get youMightWantToJotThisDown;

  /// No description provided for @mnemonic.
  ///
  /// In en, this message translates to:
  /// **'Mnemonic'**
  String get mnemonic;

  /// No description provided for @startFlutterBackgroundService.
  ///
  /// In en, this message translates to:
  /// **'Start the Flutter background service'**
  String get startFlutterBackgroundService;

  /// No description provided for @frequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency:'**
  String get frequencyLabel;

  /// No description provided for @minutes15.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get minutes15;

  /// No description provided for @minutes30.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get minutes30;

  /// No description provided for @hour1.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get hour1;

  /// No description provided for @cancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel All'**
  String get cancelAll;

  /// No description provided for @noEscrowsTrustedYet.
  ///
  /// In en, this message translates to:
  /// **'No escrows trusted yet'**
  String get noEscrowsTrustedYet;

  /// Generic user-facing error message with details
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {details}'**
  String errorGeneric(String details);

  /// Review count label with plural handling
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews} =1{1 review} other{{count} reviews}}'**
  String reviewCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
