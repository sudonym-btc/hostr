import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

typedef AppCarouselItemBuilder =
    Widget Function(BuildContext context, int index);

typedef EditableCarouselThumbnailBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

class AppCarousel extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final int itemCount;
  final AppCarouselItemBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;
  final Widget? placeholder;
  final VoidCallback? onPlaceholderTap;
  final bool showArrows;
  final bool padEnds;
  final double bottomControlsHeight;
  final PageStorageKey<String>? storageKey;

  const AppCarousel({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.placeholder,
    this.onPlaceholderTap,
    this.showArrows = true,
    this.padEnds = true,
    this.bottomControlsHeight = 0,
    this.storageKey,
  });

  static final Set<PointerDeviceKind> _dragDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };

  void _animateToPage(int page) {
    if (!controller.hasClients) return;
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onPlaceholderTap,
          child: Container(alignment: Alignment.center, child: placeholder),
        ),
      );
    }

    final canGoLeft = currentIndex > 0;
    final canGoRight = currentIndex < itemCount - 1;
    return Stack(
      children: [
        ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: _dragDevices,
          ),
          child: PageView.builder(
            key: storageKey,
            controller: controller,
            pageSnapping: true,
            physics: const PageScrollPhysics(),
            padEnds: padEnds,
            itemCount: itemCount,
            onPageChanged: onPageChanged,
            itemBuilder: itemBuilder,
          ),
        ),
        if (showArrows && canGoLeft)
          Positioned(
            left: kSpace2,
            top: 0,
            bottom: bottomControlsHeight,
            child: Center(
              child: _AppCarouselArrow(
                icon: Icons.chevron_left,
                onTap: () => _animateToPage(currentIndex - 1),
              ),
            ),
          ),
        if (showArrows && canGoRight)
          Positioned(
            right: kSpace2,
            top: 0,
            bottom: bottomControlsHeight,
            child: Center(
              child: _AppCarouselArrow(
                icon: Icons.chevron_right,
                onTap: () => _animateToPage(currentIndex + 1),
              ),
            ),
          ),
      ],
    );
  }
}

class EditableCarouselFilmstrip<T> extends StatelessWidget {
  final List<T> items;
  final int currentIndex;
  final bool atMax;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;
  final void Function(int from, int to) onReorder;
  final VoidCallback? onAdd;
  final LocalKey Function(T item, int index) keyBuilder;
  final EditableCarouselThumbnailBuilder<T> thumbnailBuilder;
  final double height;
  final double thumbnailWidth;
  final double thumbnailHeight;

  const EditableCarouselFilmstrip({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.atMax,
    required this.onSelect,
    required this.onDelete,
    required this.onReorder,
    required this.keyBuilder,
    required this.thumbnailBuilder,
    this.onAdd,
    this.height = 88,
    this.thumbnailWidth = 84,
    this.thumbnailHeight = 64,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.94),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpace2,
                  vertical: kSpace2,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _DraggableEditableCarouselThumbnail(
                      key: keyBuilder(items[index], index),
                      index: index,
                      selected: index == currentIndex,
                      canReorder: items.length > 1,
                      width: thumbnailWidth,
                      height: thumbnailHeight,
                      onSelect: () => onSelect(index),
                      onDelete: () => onDelete(index),
                      onReorder: onReorder,
                      child: thumbnailBuilder(context, items[index], index),
                    ),
                    const SizedBox(width: kSpace2),
                  ],
                ],
              ),
            ),
            if (!atMax && onAdd != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: kSpace2,
                  right: kSpace2,
                  bottom: kSpace2,
                ),
                child: _EditableCarouselAddTile(
                  width: thumbnailWidth,
                  height: thumbnailHeight,
                  onTap: onAdd!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppCarouselIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppCarouselIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color:
          backgroundColor ??
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        icon: Icon(
          icon,
          size: kIconMd,
          color: foregroundColor ?? colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DraggableEditableCarouselThumbnail extends StatefulWidget {
  final int index;
  final bool selected;
  final bool canReorder;
  final double width;
  final double height;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final void Function(int from, int to) onReorder;
  final Widget child;

  const _DraggableEditableCarouselThumbnail({
    super.key,
    required this.index,
    required this.selected,
    required this.canReorder,
    required this.width,
    required this.height,
    required this.onSelect,
    required this.onDelete,
    required this.onReorder,
    required this.child,
  });

  @override
  State<_DraggableEditableCarouselThumbnail> createState() =>
      _DraggableEditableCarouselThumbnailState();
}

class _DraggableEditableCarouselThumbnailState
    extends State<_DraggableEditableCarouselThumbnail> {
  bool _hoveringDropTarget = false;

  @override
  Widget build(BuildContext context) {
    final thumbnail = _EditableCarouselThumbnail(
      index: widget.index,
      selected: widget.selected,
      canReorder: widget.canReorder,
      highlighted: _hoveringDropTarget,
      width: widget.width,
      height: widget.height,
      onSelect: widget.onSelect,
      onDelete: widget.onDelete,
      child: widget.child,
    );

    if (!widget.canReorder) return thumbnail;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final hovering = details.data != widget.index;
        if (_hoveringDropTarget != hovering) {
          setState(() => _hoveringDropTarget = hovering);
        }
        return hovering;
      },
      onLeave: (_) {
        if (_hoveringDropTarget) {
          setState(() => _hoveringDropTarget = false);
        }
      },
      onAcceptWithDetails: (details) {
        if (_hoveringDropTarget) {
          setState(() => _hoveringDropTarget = false);
        }
        widget.onReorder(details.data, widget.index);
      },
      builder: (context, _, _) {
        return Draggable<int>(
          data: widget.index,
          feedback: _EditableCarouselDragFeedback(
            width: widget.width,
            height: widget.height,
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: thumbnail),
          child: thumbnail,
        );
      },
    );
  }
}

class _EditableCarouselThumbnail extends StatelessWidget {
  final int index;
  final bool selected;
  final bool canReorder;
  final bool highlighted;
  final double width;
  final double height;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final Widget child;

  const _EditableCarouselThumbnail({
    required this.index,
    required this.selected,
    required this.canReorder,
    required this.highlighted,
    required this.width,
    required this.height,
    required this.onSelect,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Tooltip(
              message: canReorder ? 'Drag to reorder' : 'Photo',
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppBorderRadii.xs,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onSelect,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: highlighted
                            ? colorScheme.secondary
                            : selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: (selected || highlighted) ? 3 : 1,
                      ),
                      borderRadius: AppBorderRadii.xs,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          if (highlighted)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.18),
                    border: Border.all(color: colorScheme.primary, width: 3),
                    borderRadius: AppBorderRadii.xs,
                  ),
                ),
              ),
            ),
          Positioned(
            top: kSpace1,
            right: kSpace1,
            child: AppCarouselIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Remove photo',
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: Colors.white,
              onPressed: onDelete,
            ),
          ),
          if (selected)
            Positioned(
              left: 0,
              right: 0,
              bottom: -kSpace2,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: AppBorderRadii.full,
                  ),
                  child: const SizedBox(width: 28, height: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditableCarouselDragFeedback extends StatelessWidget {
  final double width;
  final double height;

  const _EditableCarouselDragFeedback({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.04,
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.92,
              ),
              border: Border.all(color: colorScheme.primary, width: 3),
              borderRadius: AppBorderRadii.xs,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.image_outlined,
              color: colorScheme.onSurface,
              size: kIconLg,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableCarouselAddTile extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const _EditableCarouselAddTile({
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppBorderRadii.xs,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: AppBorderRadii.xs,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: colorScheme.onSurface,
              size: kIconLg,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppCarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppCarouselArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(kSpace1),
          child: Icon(
            icon,
            size: kIconLg,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}
