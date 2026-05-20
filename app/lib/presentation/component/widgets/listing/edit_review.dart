import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/forms/text_field_controller.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

typedef EditReviewSubmit =
    Future<void> Function(EditReviewController controller);

class EditReviewController extends UpsertFormController {
  final TextFieldController reviewField = TextFieldController();
  final EditReviewSubmit? onUpsert;
  final Listing listing;
  final Order? reservation;

  int _rating = 5;
  int _originalRating = 5;

  // Location is tracked by super; rating is a single extra comparison.
  @override
  bool get isDirty => super.isDirty || _rating != _originalRating;

  EditReviewController({
    this.onUpsert,
    Review? existingReview,
    required this.listing,
    this.reservation,
  }) {
    registerField(reviewField);
    setState(existingReview);
  }

  int get rating => _rating;

  /// Rating normalized from 0..1 (where 5 stars == 1.0)
  double get normalizedRating => _rating / 5;

  void setState(Review? review) {
    if (review == null) {
      reviewField.setState('');
      _rating = 5;
      _originalRating = 5;
      notifyListeners();
      return;
    }

    reviewField.setState(review.reviewText);
    _rating = review.rating.clamp(1, 5);
    _originalRating = _rating;
    notifyListeners();
  }

  void setRating(int value) {
    final clamped = value.clamp(1, 5);
    if (_rating == clamped) return;
    _rating = clamped;
    notifyListeners();
  }

  void setNormalizedRating(double value) {
    final clamped = value.clamp(0, 1);
    final mapped = (clamped * 5).round().clamp(1, 5);
    setRating(mapped);
  }

  String? validateReview(String? value, {required String requiredMessage}) {
    if (value == null || value.trim().isEmpty) return requiredMessage;
    return null;
  }

  String? validateRating(int? value, {required String outOfRangeMessage}) {
    if (value == null || value < 1 || value > 5) return outOfRangeMessage;
    return null;
  }

  @override
  Future<void> upsert() async {
    debugPrint('REVIEW_SAVE upsert:start');
    final activeKeyPair = getIt<Hostr>().auth.activeKeyPair!;
    final reservationContext = reservation;
    if (reservationContext == null) {
      throw StateError('Order context is required to publish a review');
    }
    final tradeId = reservationContext.getDtag();
    if (tradeId == null || tradeId.isEmpty) {
      throw StateError('Order trade id is required to publish a review');
    }
    debugPrint('REVIEW_SAVE upsert:tradeId=$tradeId');
    final tradeAccountIndex = await getIt<Hostr>().tradeAccountAllocator
        .findTradeAccountIndexByTradeId(tradeId);
    debugPrint('REVIEW_SAVE upsert:accountIndex=$tradeAccountIndex');
    final reservationAuthorKeyPair = await getIt<Hostr>().auth.hd
        .getTradeKeyPair(accountIndex: tradeAccountIndex);
    debugPrint(
      'REVIEW_SAVE upsert:reservationAuthor=${reservationAuthorKeyPair.publicKey}',
    );
    final proof = await getIt<Hostr>().orders.createParticipationProofForReview(
      order: reservationContext,
      role: 'buyer',
      recipientKeyPair: reservationAuthorKeyPair,
      identityKeyPair: activeKeyPair,
    );
    debugPrint(
      'REVIEW_SAVE upsert:proof participant=${proof.participantPubkey} hash=${proof.authorizationPayloadHash}',
    );
    await getIt<Hostr>().reviews.upsert(
      Review(
        pubKey: activeKeyPair.publicKey,
        content: reviewField.text,
        tags: ReviewTags([
          ['d', tradeId],
          [kListingRefTag, listing.anchor!],
          [kOrderRefTag, reservation?.anchor ?? ''],
          ['p', listing.pubKey],
          ReviewTags.primaryRatingTagFromStars(rating),
          ReviewTags.proofTag(proof),
        ]),
      ),
    );
    debugPrint('REVIEW_SAVE upsert:done');
  }

  @override
  void dispose() {
    reviewField.dispose();
    super.dispose();
  }
}

class EditReview extends StatefulWidget {
  final Review? existingReview;
  final Listing listing;
  final Order? reservation;
  final VoidCallback? onSaved;

  const EditReview({
    super.key,
    this.existingReview,
    this.onSaved,
    required this.listing,
    this.reservation,
  });

  @override
  State<EditReview> createState() => _EditReviewState();
}

class _EditReviewState extends State<EditReview> {
  late final EditReviewController _controller;

  String _formatError(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return 'Failed to publish review. Please try again.';
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  @override
  void initState() {
    super.initState();
    _controller = EditReviewController(
      existingReview: widget.existingReview,
      listing: widget.listing,
      reservation: widget.reservation,
    );
  }

  @override
  void didUpdateWidget(covariant EditReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingReview?.id != widget.existingReview?.id) {
      _controller.setState(widget.existingReview);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    debugPrint(
      'REVIEW_SAVE handle:start canSubmit=${_controller.canSubmit} isSaving=${_controller.isSaving}',
    );
    try {
      final didSave = await _controller.save();
      debugPrint('REVIEW_SAVE handle:didSave=$didSave');
      if (didSave) {
        widget.onSaved?.call();
      }
    } catch (error) {
      debugPrint('REVIEW_SAVE handle:error=$error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatError(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Form(
          key: _controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormLabel(
                label: AppLocalizations.of(context)!.reviewMessageLabel,
              ),
              TextFormField(
                key: const ValueKey('review_message_input'),
                controller: _controller.reviewField.textController,
                validator: (value) => _controller.validateReview(
                  value,
                  requiredMessage: AppLocalizations.of(context)!.reviewRequired,
                ),
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.reviewHint,
                ),
              ),
              Gap.vertical.lg(),
              FormField<int>(
                initialValue: _controller.rating,
                validator: (value) => _controller.validateRating(
                  value,
                  outOfRangeMessage: AppLocalizations.of(
                    context,
                  )!.ratingMustBeBetween1And5,
                ),
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormLabel(
                        label: AppLocalizations.of(context)!.reviewRatingLabel,
                      ),
                      Gap.vertical.sm(),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            final selected = star <= _controller.rating;
                            return IconButton(
                              key: ValueKey('review_rating_star_$star'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _controller.setRating(star);
                                field.didChange(_controller.rating);
                              },
                              icon: Icon(
                                selected ? Icons.star : Icons.star_border,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            );
                          }),
                        ],
                      ),
                      // Text(
                      //   'Normalized: ${_controller.normalizedRating.toStringAsFixed(2)}',
                      //   style: Theme.of(context).textTheme.bodySmall,
                      // ),
                      if (field.hasError)
                        CustomPadding.only(
                          top: 6,
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Gap.vertical.lg(),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: const ValueKey('review_save_button'),
                  onPressed: _controller.canSubmit ? _handleSave : null,
                  child: _controller.isSaving
                      ? AppLoadingIndicator.small(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : Text(AppLocalizations.of(context)!.save),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
