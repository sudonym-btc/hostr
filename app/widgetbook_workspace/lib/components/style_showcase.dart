import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/presentation/component/widgets/badges_widget.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:models/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../seed_data.dart';

class ComponentsShowcase extends StatelessWidget {
  const ComponentsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShowcasePage();
  }
}

@widgetbook.UseCase(name: 'Side by side', type: ComponentsShowcase)
Widget componentsSideBySide(BuildContext context) {
  return const ComponentsShowcase();
}

@widgetbook.UseCase(name: 'All styles', type: FilledButton)
Widget filledButtonStyles(BuildContext context) {
  return const _UseCaseFrame(child: _FilledButtonSamples());
}

@widgetbook.UseCase(name: 'All styles', type: OutlinedButton)
Widget outlinedButtonStyles(BuildContext context) {
  return const _UseCaseFrame(child: _OutlinedButtonSamples());
}

@widgetbook.UseCase(name: 'All styles', type: TextButton)
Widget textButtonStyles(BuildContext context) {
  return const _UseCaseFrame(child: _TextButtonSamples());
}

@widgetbook.UseCase(name: 'Semantic variants', type: AppChip)
Widget semanticChipStyles(BuildContext context) {
  return const _UseCaseFrame(child: _SemanticChipSamples());
}

@widgetbook.UseCase(name: 'Spec and input chips', type: Chip)
Widget materialChipStyles(BuildContext context) {
  return const _UseCaseFrame(child: _MaterialChipSamples());
}

@widgetbook.UseCase(name: 'Badge awards', type: BadgeChip)
Widget badgeAwardChipStyles(BuildContext context) {
  return _UseCaseFrame(child: _BadgeAwardChipSamples());
}

@widgetbook.UseCase(name: 'All styles', type: ProfileChipWidget)
Widget profileChipStyles(BuildContext context) {
  return const _UseCaseFrame(child: _ProfileChipSamples());
}

@widgetbook.UseCase(name: 'All styles', type: DateRangeButtons)
Widget dateRangeButtonStyles(BuildContext context) {
  return const _UseCaseFrame(child: _DateRangeButtonSamples());
}

@widgetbook.UseCase(name: 'Text styles', type: AmountTapInput)
Widget amountTapInputTextStyles(BuildContext context) {
  return const _UseCaseFrame(child: _AmountTapInputSamples());
}

class _ShowcasePage extends StatelessWidget {
  const _ShowcasePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          const _ShowcasePanel(
            title: 'Filled buttons',
            child: _FilledButtonSamples(),
          ),
          const _ShowcasePanel(
            title: 'Outlined buttons',
            child: _OutlinedButtonSamples(),
          ),
          const _ShowcasePanel(
            title: 'Text buttons',
            child: _TextButtonSamples(),
          ),
          const _ShowcasePanel(
            title: 'Semantic chips',
            child: _SemanticChipSamples(),
          ),
          const _ShowcasePanel(
            title: 'Spec and input chips',
            child: _MaterialChipSamples(),
          ),
          const _ShowcasePanel(
            title: 'Badge award chips',
            child: _BadgeAwardChipSamples(),
          ),
          const _ShowcasePanel(
            title: 'Profile chips',
            child: _ProfileChipSamples(),
          ),
          const _ShowcasePanel(
            title: 'Date range buttons',
            wide: true,
            child: _DateRangeButtonSamples(),
          ),
          const _ShowcasePanel(
            title: 'Amount tap inputs',
            wide: true,
            child: _AmountTapInputSamples(),
          ),
        ],
      ),
    );
  }
}

class _ShowcasePanel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool wide;

  const _ShowcasePanel({
    required this.title,
    required this.child,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 680 : 320),
      child: AppSurface(
        borderRadius: AppBorderRadii.sm,
        padding: const EdgeInsets.all(kSpace4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Gap.vertical.md(),
            child,
          ],
        ),
      ),
    );
  }
}

class _UseCaseFrame extends StatelessWidget {
  final Widget child;

  const _UseCaseFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(kSpace4), child: child),
      ),
    );
  }
}

class _FilledButtonSamples extends StatelessWidget {
  const _FilledButtonSamples();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [
        FilledButton(onPressed: () {}, child: const Text('Primary')),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Primary icon'),
        ),
        FilledButton(
          style: AppButtonStyles.secondary(context),
          onPressed: () {},
          child: const Text('Secondary'),
        ),
        FilledButton(
          style: AppButtonStyles.destructive(context),
          onPressed: () {},
          child: const Text('Destructive'),
        ),
        const FilledButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

class _OutlinedButtonSamples extends StatelessWidget {
  const _OutlinedButtonSamples();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [
        OutlinedButton(onPressed: () {}, child: const Text('Default')),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune),
          label: const Text('With icon'),
        ),
        OutlinedButton(
          style: AppButtonStyles.destructiveOutline(context),
          onPressed: () {},
          child: const Text('Destructive'),
        ),
        OutlinedButton(
          style: AppButtonStyles.destructiveOutline(
            context,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {},
          child: const Text('Compact destructive'),
        ),
        const OutlinedButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

class _TextButtonSamples extends StatelessWidget {
  const _TextButtonSamples();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [
        TextButton(onPressed: () {}, child: const Text('Default')),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
        ),
        TextButton(
          style: AppButtonStyles.text(context).copyWith(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.error,
            ),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {},
          child: const Text('Destructive'),
        ),
        const TextButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

class _SemanticChipSamples extends StatelessWidget {
  const _SemanticChipSamples();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [
        AppChip.neutral.sm(label: Text('Neutral')),
        AppChip.success.sm(label: Text('Success')),
        AppChip.info.sm(label: Text('Info')),
        AppChip.warning.sm(label: Text('Warning')),
        AppChip.error.sm(label: Text('Error')),
        AppChip.success.xs(label: Text('XS status')),
        AppChip.neutral.sm(
          avatar: Icon(Icons.flash_on, size: 16),
          label: Text('Avatar'),
        ),
      ],
    );
  }
}

class _MaterialChipSamples extends StatelessWidget {
  const _MaterialChipSamples();

  @override
  Widget build(BuildContext context) {
    final specShape = AppShapes.pillWithSide(
      color: AppSurface.stepped(context, 4),
    );
    final specColor = AppSurface.stepped(context, 2);

    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [
        AppChip(
          label: const Text('2 bedrooms'),
          shape: specShape,
          backgroundColor: specColor,
        ),
        AppChip(
          label: const Text('Wifi'),
          shape: specShape,
          backgroundColor: specColor,
        ),
        ChoiceChip(
          label: const Text('Apartment'),
          selected: true,
          onSelected: (_) {},
          labelStyle: AppChipStyles.statefulLabelStyle(context),
          shape: AppChipStyles.shape,
          side: AppChipStyles.selectableSide(context),
          color: AppChipStyles.selectableColor(context),
          padding: AppChipStyles.padding,
          labelPadding: AppChipStyles.labelPadding,
          visualDensity: AppChipStyles.visualDensity,
          materialTapTargetSize: AppChipStyles.materialTapTargetSize,
        ),
        ChoiceChip(
          label: const Text('House'),
          selected: false,
          onSelected: (_) {},
          labelStyle: AppChipStyles.statefulLabelStyle(context),
          shape: AppChipStyles.shape,
          side: AppChipStyles.selectableSide(context),
          color: AppChipStyles.selectableColor(context),
          padding: AppChipStyles.padding,
          labelPadding: AppChipStyles.labelPadding,
          visualDensity: AppChipStyles.visualDensity,
          materialTapTargetSize: AppChipStyles.materialTapTargetSize,
        ),
        InputChip(
          label: const Text('Pool'),
          shape: specShape,
          backgroundColor: specColor,
          side: AppChipStyles.neutralSide(context),
          labelStyle: AppChipStyles.labelStyle(context),
          padding: AppChipStyles.padding,
          labelPadding: AppChipStyles.inputLabelPadding,
          visualDensity: AppChipStyles.visualDensity,
          materialTapTargetSize: AppChipStyles.materialTapTargetSize,
          onDeleted: () {},
        ),
        InputChip(
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 6),
              Text('Add feature'),
            ],
          ),
          shape: specShape,
          backgroundColor: Theme.of(context).colorScheme.surface,
          side: AppChipStyles.neutralSide(context),
          labelStyle: AppChipStyles.labelStyle(context),
          iconTheme: AppChipStyles.iconTheme(context),
          padding: AppChipStyles.padding,
          labelPadding: AppChipStyles.inputLabelPadding,
          visualDensity: AppChipStyles.visualDensity,
          materialTapTargetSize: AppChipStyles.materialTapTargetSize,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _BadgeAwardChipSamples extends StatelessWidget {
  const _BadgeAwardChipSamples();

  @override
  Widget build(BuildContext context) {
    final awards = seedData.badgeAwards.take(3).toList();
    if (awards.isEmpty) {
      return const _FallbackBadgeAwardChip();
    }

    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [for (final award in awards) BadgeChip(award: award)],
    );
  }
}

class _FallbackBadgeAwardChip extends StatelessWidget {
  const _FallbackBadgeAwardChip();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppBorderRadii.full,
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: AppBorderRadii.full,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: kIconMd,
              color: Theme.of(context).colorScheme.primary,
            ),
            Gap.horizontal.xs(),
            Text(
              'Badge',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChipSamples extends StatelessWidget {
  const _ProfileChipSamples();

  @override
  Widget build(BuildContext context) {
    final profiles = mockProfiles.take(2).toList();

    return Wrap(
      spacing: kSpace2,
      runSpacing: kSpace2,
      children: [
        for (final profile in profiles) ProfileChipWidget(id: profile.pubKey),
      ],
    );
  }
}

class _DateRangeButtonSamples extends StatelessWidget {
  const _DateRangeButtonSamples();

  @override
  Widget build(BuildContext context) {
    final selectedRange = DateTimeRange(
      start: DateTime(2026, 5, 14),
      end: DateTime(2026, 5, 18),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DateRangeButtons(selectedDateRange: selectedRange),
          Gap.vertical.md(),
          DateRangeButtons(selectedDateRange: selectedRange, small: true),
          Gap.vertical.md(),
          DateRangeButtons(
            selectedDateRange: selectedRange,
            single: true,
            small: true,
          ),
          Gap.vertical.md(),
          const DateRangeButtons(single: true),
        ],
      ),
    );
  }
}

class _AmountTapInputSamples extends StatefulWidget {
  const _AmountTapInputSamples();

  @override
  State<_AmountTapInputSamples> createState() => _AmountTapInputSamplesState();
}

class _AmountTapInputSamplesState extends State<_AmountTapInputSamples> {
  late final AmountFieldController _editListingPriceController;
  late final AmountFieldController _editListingDepositController;
  late final AmountFieldController _reserveController;
  late final AmountFieldController _paymentController;

  @override
  void initState() {
    super.initState();
    _editListingPriceController = AmountFieldController()
      ..setState(_btcAmount(125000));
    _editListingDepositController = AmountFieldController()
      ..setState(_btcAmount(25000));
    _reserveController = AmountFieldController()..setState(_btcAmount(390000));
    _paymentController = AmountFieldController()..setState(_btcAmount(50000));
  }

  @override
  void dispose() {
    _editListingPriceController.dispose();
    _editListingDepositController.dispose();
    _reserveController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  DenominatedAmount _btcAmount(int sats) {
    return DenominatedAmount(
      denomination: 'BTC',
      value: BigInt.from(sats),
      decimals: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reserveTextStyle = Theme.of(
      context,
    ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold);
    final paymentTextStyle = Theme.of(
      context,
    ).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.bold);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Wrap(
        spacing: kSpace4,
        runSpacing: kSpace4,
        children: [
          _AmountTapInputSample(
            label: 'Edit listing price',
            child: AmountTapInput(
              controller: _editListingPriceController,
              hintText: 'Tap to set price',
              suffixText: '/ day',
              possibleDenominations: const ['BTC', 'USD'],
              required: true,
            ),
          ),
          _AmountTapInputSample(
            label: 'Edit listing deposit',
            child: AmountTapInput(
              controller: _editListingDepositController,
              hintText: 'Tap to set deposit',
              possibleDenominations: const ['BTC', 'USD'],
            ),
          ),
          _AmountTapInputSample(
            label: 'Reserve',
            child: AmountTapInput(
              controller: _reserveController,
              min: [_btcAmount(1)],
              max: [_btcAmount(390000)],
              editable: true,
              exact: false,
              textStyle: reserveTextStyle,
            ),
          ),
          _AmountTapInputSample(
            label: 'Payment flow',
            child: AmountTapInput(
              controller: _paymentController,
              hintText: 'Amount',
              min: [_btcAmount(1000)],
              max: [_btcAmount(100000)],
              required: true,
              textStyle: paymentTextStyle,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountTapInputSample extends StatelessWidget {
  final String label;
  final Widget child;

  const _AmountTapInputSample({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Gap.vertical.xs(),
          child,
        ],
      ),
    );
  }
}
