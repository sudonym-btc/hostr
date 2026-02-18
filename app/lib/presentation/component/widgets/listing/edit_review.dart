import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

typedef EditReviewSubmit =
    Future<void> Function(EditReviewController controller);

class EditReviewController extends UpsertFormController {
  final TextEditingController reviewController = TextEditingController();
  final EditReviewSubmit? onUpsert;
  final Listing listing;
  final Reservation? reservation;
  final String? salt;

  int _rating = 5;

  EditReviewController({
    this.onUpsert,
    Review? existingReview,
    required this.listing,
    this.reservation,
    this.salt,
  }) {
    setState(existingReview);
  }

  int get rating => _rating;

  /// Rating normalized from 0..1 (where 5 stars == 1.0)
  double get normalizedRating => _rating / 5;

  void setState(Review? review) {
    if (review == null) {
      reviewController.text = '';
      _rating = 5;
      notifyListeners();
      return;
    }

    reviewController.text = review.parsedContent.content;
    _rating = review.parsedContent.rating.clamp(1, 5);
    notifyListeners();
  }

  void setRating(int value) {
    final clamped = value.clamp(1, 5);
    if (_rating == clamped) {
      return;
    }
    _rating = clamped;
    notifyListeners();
  }

  void setNormalizedRating(double value) {
    final clamped = value.clamp(0, 1);
    final mapped = (clamped * 5).round().clamp(1, 5);
    setRating(mapped);
  }

  String? validateReview(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Review is required';
    }
    return null;
  }

  String? validateRating(int? value) {
    if (value == null || value < 1 || value > 5) {
      return 'Rating must be between 1 and 5';
    }
    return null;
  }

  @override
  Future<void> upsert() async {
    await getIt<Hostr>().reviews.create(
      Review(
        pubKey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
        content: ReviewContent(
          rating: rating,
          content: reviewController.text,
          proof: ParticipationProof(salt: salt!),
        ),
        tags: ReviewTags([
          [kListingRefTag, listing.anchor!],
          [kReservationRefTag, '1234'],
        ]),
      ),
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }
}

class EditReview extends StatefulWidget {
  final Review? existingReview;
  final Listing listing;
  final Reservation? reservation;
  final String? salt;
  final VoidCallback? onSaved;

  const EditReview({
    super.key,
    this.existingReview,
    this.onSaved,
    required this.listing,
    this.reservation,
    this.salt,
  });

  @override
  State<EditReview> createState() => _EditReviewState();
}

class _EditReviewState extends State<EditReview> {
  late final EditReviewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditReviewController(
      existingReview: widget.existingReview,
      listing: widget.listing,
      reservation: widget.reservation,
      salt: widget.salt,
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
    final didSave = await _controller.save();
    if (didSave) {
      widget.onSaved?.call();
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
              const FormLabel(label: 'Message'),
              TextFormField(
                controller: _controller.reviewController,
                validator: _controller.validateReview,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Tell others about your stay',
                ),
              ),
              SizedBox(height: kDefaultPadding.toDouble()),
              FormField<int>(
                initialValue: _controller.rating,
                validator: _controller.validateRating,
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FormLabel(label: 'Rating'),
                      SizedBox(height: kDefaultPadding.toDouble() / 4),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            final selected = star <= _controller.rating;
                            return IconButton(
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
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
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
              SizedBox(height: kDefaultPadding.toDouble()),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _controller.canSubmit ? _handleSave : null,
                  child: _controller.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
