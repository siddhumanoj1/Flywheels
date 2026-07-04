import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const List<VehicleViewAngle> _viewSequence = [
  VehicleViewAngle.front,
  VehicleViewAngle.right,
  VehicleViewAngle.back,
  VehicleViewAngle.left,
  VehicleViewAngle.top,
];

const double _anatomySvgAspectRatio = 810 / 1012.49997;

enum _AnatomyRenderMode { fitted, cropped, relaxedCropped }

class CarAnatomyInspectionEditor extends StatefulWidget {
  const CarAnatomyInspectionEditor({
    super.key,
    required this.marks,
    required this.onChanged,
    required this.initialBodyType,
  });

  final List<VehicleInspectionMark> marks;
  final ValueChanged<List<VehicleInspectionMark>> onChanged;
  final VehicleBodyType initialBodyType;

  @override
  State<CarAnatomyInspectionEditor> createState() =>
      _CarAnatomyInspectionEditorState();
}

class _CarAnatomyInspectionEditorState
    extends State<CarAnatomyInspectionEditor> {
  late VehicleBodyType _bodyType;
  int _viewIndex = 0;
  bool _isCanvasZoomed = false;
  bool _isCanvasGestureLocked = false;
  int _rotationDirection = 1;
  double _dragDistance = 0;
  DateTime? _lastRejectedTapAt;

  VehicleViewAngle get _activeView => _viewSequence[_viewIndex];

  @override
  void initState() {
    super.initState();
    _bodyType = widget.initialBodyType;
  }

  @override
  void didUpdateWidget(covariant CarAnatomyInspectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.marks.isEmpty &&
        oldWidget.initialBodyType != widget.initialBodyType) {
      setState(() => _bodyType = widget.initialBodyType);
    }
  }

  int _nextSequence() {
    return widget.marks.fold<int>(
          0,
          (highest, mark) => mark.sequence > highest ? mark.sequence : highest,
        ) +
        1;
  }

  void _setBodyType(VehicleBodyType bodyType) {
    setState(() => _bodyType = bodyType);
  }

  void _goToView(int delta) {
    final next = (_viewIndex + delta)
        .clamp(0, _viewSequence.length - 1)
        .toInt();
    if (next == _viewIndex) return;
    setState(() {
      _rotationDirection = delta.sign == 0 ? 1 : delta.sign;
      _viewIndex = next;
    });
  }

  void _handleCanvasDragDelta(double deltaX) {
    if (_isCanvasZoomed || _isCanvasGestureLocked) return;
    _dragDistance += deltaX;
    if (_dragDistance.abs() < 72) return;
    _goToView(_dragDistance < 0 ? 1 : -1);
    _dragDistance = 0;
  }

  void _finishCanvasDrag() {
    _dragDistance = 0;
  }

  Future<void> _addMark(TapUpDetails details, Size size) async {
    if (size.width <= 0 || size.height <= 0) return;
    final svgPosition = _croppedBoxPointToSvgPoint(
      details.localPosition,
      size,
      _vehicleRelaxedDrawingRect(_bodyType, _activeView),
    );
    if (!_isInsideVehicleBody(_bodyType, _activeView, svgPosition)) {
      final now = DateTime.now();
      final shouldShowMessage =
          _lastRejectedTapAt == null ||
          now.difference(_lastRejectedTapAt!) > const Duration(seconds: 2);
      _lastRejectedTapAt = now;
      if (shouldShowMessage) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Place markers on the vehicle body.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final note = await _requestMarkNote();
    if (!mounted || note == null) return;
    final mark = VehicleInspectionMark(
      sequence: _nextSequence(),
      bodyType: _bodyType,
      view: _activeView,
      x: svgPosition.dx,
      y: svgPosition.dy,
      note: note,
    );
    widget.onChanged([...widget.marks, mark]);
  }

  Future<String?> _requestMarkNote() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _MarkerNoteDialog(),
    );
  }

  void _removeMark(VehicleInspectionMark mark) {
    widget.onChanged(
      widget.marks.where((item) => item.sequence != mark.sequence).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<VehicleBodyType>(
                segments: const [
                  ButtonSegment<VehicleBodyType>(
                    value: VehicleBodyType.hatchback,
                    label: Text('Hatch'),
                  ),
                  ButtonSegment<VehicleBodyType>(
                    value: VehicleBodyType.sedan,
                    label: Text('Sedan'),
                  ),
                  ButtonSegment<VehicleBodyType>(
                    value: VehicleBodyType.suv,
                    label: Text('SUV'),
                  ),
                ],
                selected: {_bodyType},
                onSelectionChanged: (value) => _setBodyType(value.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.outlined(
              tooltip: 'Previous view',
              onPressed: _viewIndex == 0 ? null : () => _goToView(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _activeView.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Next view',
              onPressed: _viewIndex == _viewSequence.length - 1
                  ? null
                  : () => _goToView(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.sizeOf(context).height;
            final width = constraints.maxWidth;
            final viewportHeight = (width * 1.06).clamp(
              320.0,
              screenHeight * 0.62,
            );
            return SizedBox(
              height: viewportHeight,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerMove: (event) =>
                    _handleCanvasDragDelta(event.delta.dx),
                onPointerUp: (_) => _finishCanvasDrag(),
                onPointerCancel: (_) => _finishCanvasDrag(),
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final value = animation.value;
                          final angle = (1 - value) * 0.48 * _rotationDirection;
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              child: Transform.scale(
                                scale: 0.94 + value * 0.06,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    child: _AnatomyCanvas(
                      key: ValueKey('${_bodyType.name}-${_activeView.name}'),
                      bodyType: _bodyType,
                      view: _activeView,
                      marks: widget.marks
                          .where((mark) => mark.bodyType == _bodyType)
                          .where((mark) => mark.view == _activeView)
                          .toList(),
                      renderMode: _AnatomyRenderMode.relaxedCropped,
                      onTapUp: _addMark,
                      onZoomChanged: (isZoomed) {
                        if (_isCanvasZoomed == isZoomed) return;
                        setState(() => _isCanvasZoomed = isZoomed);
                      },
                      onGestureLockChanged: (isLocked) {
                        if (_isCanvasGestureLocked == isLocked) return;
                        setState(() => _isCanvasGestureLocked = isLocked);
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.marks.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...widget.marks.map(
            (mark) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _InspectionMarkTile(
                mark: mark,
                active: mark.bodyType == _bodyType && mark.view == _activeView,
                onDeleted: () => _removeMark(mark),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MarkerNoteDialog extends StatefulWidget {
  const _MarkerNoteDialog();

  @override
  State<_MarkerNoteDialog> createState() => _MarkerNoteDialogState();
}

class _MarkerNoteDialogState extends State<_MarkerNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marker note'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Add note for this mark',
          prefixIcon: Icon(Icons.edit_note_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class CarAnatomyInspectionReport extends StatelessWidget {
  const CarAnatomyInspectionReport({
    super.key,
    required this.marks,
    this.panelHeight = 132,
  });

  final List<VehicleInspectionMark> marks;
  final double panelHeight;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) return const SizedBox.shrink();
    final groups = _groupMarksByBody(marks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inspection Map',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppPalette.red,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...groups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.bodyType.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppPalette.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _InspectionAnatomyPlate(
                  bodyType: group.bodyType,
                  marks: group.marks,
                  panelHeight: panelHeight,
                ),
                const SizedBox(height: 6),
                ...group.marks.map(
                  (mark) => Text(
                    mark.summary,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnatomyCanvas extends StatelessWidget {
  const _AnatomyCanvas({
    super.key,
    required this.bodyType,
    required this.view,
    required this.marks,
    this.interactive = true,
    this.fit = BoxFit.cover,
    this.markerSize = 22,
    this.renderMode = _AnatomyRenderMode.fitted,
    this.onTapUp,
    this.onZoomChanged,
    this.onGestureLockChanged,
  });

  final VehicleBodyType bodyType;
  final VehicleViewAngle view;
  final List<VehicleInspectionMark> marks;
  final bool interactive;
  final BoxFit fit;
  final double markerSize;
  final _AnatomyRenderMode renderMode;
  final void Function(TapUpDetails details, Size size)? onTapUp;
  final ValueChanged<bool>? onZoomChanged;
  final ValueChanged<bool>? onGestureLockChanged;

  @override
  Widget build(BuildContext context) {
    if (!interactive) {
      return _StaticAnatomyCanvas(
        bodyType: bodyType,
        view: view,
        marks: marks,
        fit: fit,
        markerSize: markerSize,
        renderMode: renderMode,
      );
    }
    return _ZoomableAnatomyCanvas(
      bodyType: bodyType,
      view: view,
      marks: marks,
      fit: fit,
      markerSize: markerSize,
      renderMode: renderMode,
      onTapUp: onTapUp,
      onZoomChanged: onZoomChanged,
      onGestureLockChanged: onGestureLockChanged,
    );
  }
}

class _ZoomableAnatomyCanvas extends StatefulWidget {
  const _ZoomableAnatomyCanvas({
    required this.bodyType,
    required this.view,
    required this.marks,
    required this.fit,
    required this.markerSize,
    required this.renderMode,
    this.onTapUp,
    this.onZoomChanged,
    this.onGestureLockChanged,
  });

  final VehicleBodyType bodyType;
  final VehicleViewAngle view;
  final List<VehicleInspectionMark> marks;
  final BoxFit fit;
  final double markerSize;
  final _AnatomyRenderMode renderMode;
  final void Function(TapUpDetails details, Size size)? onTapUp;
  final ValueChanged<bool>? onZoomChanged;
  final ValueChanged<bool>? onGestureLockChanged;

  @override
  State<_ZoomableAnatomyCanvas> createState() => _ZoomableAnatomyCanvasState();
}

class _ZoomableAnatomyCanvasState extends State<_ZoomableAnatomyCanvas> {
  late final TransformationController _transformationController;
  bool _isZoomed = false;
  int _activePointerCount = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void didUpdateWidget(covariant _ZoomableAnatomyCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bodyType != widget.bodyType ||
        oldWidget.view != widget.view) {
      _transformationController.value = Matrix4.identity();
      _setZoomed(false);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _setZoomed(bool value) {
    if (_isZoomed == value) return;
    setState(() => _isZoomed = value);
    widget.onZoomChanged?.call(value);
    widget.onGestureLockChanged?.call(value || _activePointerCount > 1);
  }

  void _syncZoomState() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    _setZoomed(scale > 1.02);
  }

  void _setPointerCount(int value) {
    final next = value < 0 ? 0 : value;
    if (_activePointerCount == next) return;
    _activePointerCount = next;
    widget.onGestureLockChanged?.call(_isZoomed || _activePointerCount > 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          onPointerDown: (_) => _setPointerCount(_activePointerCount + 1),
          onPointerUp: (_) => _setPointerCount(_activePointerCount - 1),
          onPointerCancel: (_) => _setPointerCount(_activePointerCount - 1),
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1,
            maxScale: 5,
            panEnabled: _isZoomed,
            scaleEnabled: true,
            trackpadScrollCausesScale: true,
            clipBehavior: Clip.hardEdge,
            boundaryMargin: const EdgeInsets.all(96),
            onInteractionUpdate: (_) => _syncZoomState(),
            onInteractionEnd: (_) => _syncZoomState(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.onTapUp == null || _activePointerCount > 1
                  ? null
                  : (details) => widget.onTapUp!(details, size),
              child:
                  widget.renderMode == _AnatomyRenderMode.cropped ||
                      widget.renderMode == _AnatomyRenderMode.relaxedCropped
                  ? _CroppedAnatomyCanvas(
                      bodyType: widget.bodyType,
                      view: widget.view,
                      marks: widget.marks,
                      markerSize: widget.markerSize,
                      cropRect: _vehicleDrawingRectForMode(
                        widget.bodyType,
                        widget.view,
                        widget.renderMode,
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: SvgPicture.asset(
                            vehicleAnatomyAssetPath(
                              widget.bodyType,
                              widget.view,
                            ),
                            fit: widget.fit,
                            alignment: Alignment.center,
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _InspectionMarkersOverlay(
                              marks: widget.marks,
                              markerSize: widget.markerSize,
                              fit: widget.fit,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _StaticAnatomyCanvas extends StatelessWidget {
  const _StaticAnatomyCanvas({
    required this.bodyType,
    required this.view,
    required this.marks,
    required this.fit,
    required this.markerSize,
    required this.renderMode,
  });

  final VehicleBodyType bodyType;
  final VehicleViewAngle view;
  final List<VehicleInspectionMark> marks;
  final BoxFit fit;
  final double markerSize;
  final _AnatomyRenderMode renderMode;

  @override
  Widget build(BuildContext context) {
    if (renderMode == _AnatomyRenderMode.cropped ||
        renderMode == _AnatomyRenderMode.relaxedCropped) {
      return _CroppedAnatomyCanvas(
        bodyType: bodyType,
        view: view,
        marks: marks,
        markerSize: markerSize,
        cropRect: _vehicleDrawingRectForMode(bodyType, view, renderMode),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            vehicleAnatomyAssetPath(bodyType, view),
            fit: fit,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _InspectionMarkersOverlay(
              marks: marks,
              markerSize: markerSize,
              fit: fit,
            ),
          ),
        ),
      ],
    );
  }
}

Offset _fittedBoxPointForSvgPoint(Offset svgPoint, Size size, BoxFit fit) {
  if (size.width <= 0 || size.height <= 0) return Offset.zero;
  final boxAspectRatio = size.width / size.height;
  if (fit == BoxFit.cover) {
    if (boxAspectRatio > _anatomySvgAspectRatio) {
      final displayedHeight = boxAspectRatio / _anatomySvgAspectRatio;
      final croppedTop = (displayedHeight - 1) / 2;
      return Offset(
        svgPoint.dx * size.width,
        (svgPoint.dy * displayedHeight - croppedTop) * size.height,
      );
    }

    final displayedWidth = _anatomySvgAspectRatio / boxAspectRatio;
    final croppedLeft = (displayedWidth - 1) / 2;
    return Offset(
      (svgPoint.dx * displayedWidth - croppedLeft) * size.width,
      svgPoint.dy * size.height,
    );
  }

  if (boxAspectRatio > _anatomySvgAspectRatio) {
    final displayedWidth = _anatomySvgAspectRatio / boxAspectRatio;
    final insetLeft = (1 - displayedWidth) / 2;
    return Offset(
      (insetLeft + svgPoint.dx * displayedWidth) * size.width,
      svgPoint.dy * size.height,
    );
  }

  final displayedHeight = boxAspectRatio / _anatomySvgAspectRatio;
  final insetTop = (1 - displayedHeight) / 2;
  return Offset(
    svgPoint.dx * size.width,
    (insetTop + svgPoint.dy * displayedHeight) * size.height,
  );
}

Offset _croppedBoxPointToSvgPoint(Offset localPoint, Size size, Rect cropRect) {
  return _croppedGeometry(cropRect, size).svgPointForBoxPoint(localPoint);
}

_CroppedGeometry _croppedGeometry(Rect cropRect, Size size) {
  if (size.width <= 0 || size.height <= 0) {
    return _CroppedGeometry(
      cropRect: cropRect,
      fullSvgSize: Size.zero,
      fullSvgOffset: Offset.zero,
    );
  }
  final cropSourceWidth = cropRect.width * _anatomySvgAspectRatio;
  final cropSourceHeight = cropRect.height;
  final widthScale = size.width / cropSourceWidth;
  final heightScale = size.height / cropSourceHeight;
  final scale = widthScale < heightScale ? widthScale : heightScale;
  final fittedCropSize = Size(
    cropSourceWidth * scale,
    cropSourceHeight * scale,
  );
  final fullSvgSize = Size(
    fittedCropSize.width / cropRect.width,
    fittedCropSize.height / cropRect.height,
  );
  final fullSvgOffset = Offset(
    (size.width - fittedCropSize.width) / 2 - cropRect.left * fullSvgSize.width,
    (size.height - fittedCropSize.height) / 2 -
        cropRect.top * fullSvgSize.height,
  );
  return _CroppedGeometry(
    cropRect: cropRect,
    fullSvgSize: fullSvgSize,
    fullSvgOffset: fullSvgOffset,
  );
}

class _CroppedGeometry {
  const _CroppedGeometry({
    required this.cropRect,
    required this.fullSvgSize,
    required this.fullSvgOffset,
  });

  final Rect cropRect;
  final Size fullSvgSize;
  final Offset fullSvgOffset;

  Offset boxPointForSvgPoint(Offset svgPoint) {
    return Offset(
      fullSvgOffset.dx + svgPoint.dx * fullSvgSize.width,
      fullSvgOffset.dy + svgPoint.dy * fullSvgSize.height,
    );
  }

  Offset svgPointForBoxPoint(Offset boxPoint) {
    if (fullSvgSize.width <= 0 || fullSvgSize.height <= 0) {
      return Offset.zero;
    }
    return Offset(
      (boxPoint.dx - fullSvgOffset.dx) / fullSvgSize.width,
      (boxPoint.dy - fullSvgOffset.dy) / fullSvgSize.height,
    );
  }
}

bool _isInsideVehicleBody(
  VehicleBodyType bodyType,
  VehicleViewAngle view,
  Offset point,
) {
  final rect = _vehicleBodyHitRect(bodyType, view);
  final x = ((point.dx - rect.left) / rect.width * 2 - 1).abs();
  final y = ((point.dy - rect.top) / rect.height * 2 - 1).abs();
  if (x > 1 || y > 1) return false;
  final x4 = x * x * x * x;
  final y4 = y * y * y * y;
  return x4 + y4 <= 1;
}

Rect _vehicleBodyHitRect(VehicleBodyType bodyType, VehicleViewAngle view) {
  switch (view) {
    case VehicleViewAngle.left:
    case VehicleViewAngle.right:
      switch (bodyType) {
        case VehicleBodyType.hatchback:
          return const Rect.fromLTRB(0.04, 0.31, 0.96, 0.69);
        case VehicleBodyType.sedan:
          return const Rect.fromLTRB(0.04, 0.35, 0.96, 0.65);
        case VehicleBodyType.suv:
          return const Rect.fromLTRB(0.04, 0.33, 0.96, 0.67);
      }
    case VehicleViewAngle.top:
      switch (bodyType) {
        case VehicleBodyType.hatchback:
          return const Rect.fromLTRB(0.05, 0.28, 0.95, 0.68);
        case VehicleBodyType.sedan:
          return const Rect.fromLTRB(0.05, 0.32, 0.95, 0.68);
        case VehicleBodyType.suv:
          return const Rect.fromLTRB(0.05, 0.22, 0.95, 0.67);
      }
    case VehicleViewAngle.front:
    case VehicleViewAngle.back:
      switch (bodyType) {
        case VehicleBodyType.hatchback:
          return view == VehicleViewAngle.front
              ? const Rect.fromLTRB(0.15, 0.24, 0.85, 0.86)
              : const Rect.fromLTRB(0.15, 0.17, 0.85, 0.86);
        case VehicleBodyType.sedan:
          return view == VehicleViewAngle.front
              ? const Rect.fromLTRB(0.16, 0.19, 0.84, 0.82)
              : const Rect.fromLTRB(0.16, 0.16, 0.84, 0.84);
        case VehicleBodyType.suv:
          return view == VehicleViewAngle.front
              ? const Rect.fromLTRB(0.12, 0.12, 0.88, 0.92)
              : const Rect.fromLTRB(0.12, 0.10, 0.88, 0.93);
      }
  }
}

Rect _vehicleDrawingRect(VehicleBodyType bodyType, VehicleViewAngle view) {
  final hitRect = _vehicleBodyHitRect(bodyType, view);
  switch (view) {
    case VehicleViewAngle.front:
    case VehicleViewAngle.back:
      return _expandUnitRect(hitRect, horizontal: 0.08, vertical: 0.045);
    case VehicleViewAngle.left:
    case VehicleViewAngle.right:
    case VehicleViewAngle.top:
      return _expandUnitRect(hitRect, horizontal: 0.04, vertical: 0.035);
  }
}

Rect _vehicleRelaxedDrawingRect(
  VehicleBodyType bodyType,
  VehicleViewAngle view,
) {
  final hitRect = _vehicleBodyHitRect(bodyType, view);
  switch (view) {
    case VehicleViewAngle.front:
    case VehicleViewAngle.back:
      return _expandUnitRect(hitRect, horizontal: 0.16, vertical: 0.1);
    case VehicleViewAngle.left:
    case VehicleViewAngle.right:
    case VehicleViewAngle.top:
      return _expandUnitRect(hitRect, horizontal: 0.12, vertical: 0.09);
  }
}

Rect _vehicleDrawingRectForMode(
  VehicleBodyType bodyType,
  VehicleViewAngle view,
  _AnatomyRenderMode mode,
) {
  return mode == _AnatomyRenderMode.relaxedCropped
      ? _vehicleRelaxedDrawingRect(bodyType, view)
      : _vehicleDrawingRect(bodyType, view);
}

Rect _expandUnitRect(
  Rect rect, {
  required double horizontal,
  required double vertical,
}) {
  return Rect.fromLTRB(
    (rect.left - horizontal).clamp(0.0, 1.0).toDouble(),
    (rect.top - vertical).clamp(0.0, 1.0).toDouble(),
    (rect.right + horizontal).clamp(0.0, 1.0).toDouble(),
    (rect.bottom + vertical).clamp(0.0, 1.0).toDouble(),
  );
}

class _CroppedAnatomyCanvas extends StatelessWidget {
  const _CroppedAnatomyCanvas({
    required this.bodyType,
    required this.view,
    required this.marks,
    required this.markerSize,
    required this.cropRect,
  });

  final VehicleBodyType bodyType;
  final VehicleViewAngle view;
  final List<VehicleInspectionMark> marks;
  final double markerSize;
  final Rect cropRect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _croppedGeometry(cropRect, size);
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: geometry.fullSvgOffset.dx,
                top: geometry.fullSvgOffset.dy,
                width: geometry.fullSvgSize.width,
                height: geometry.fullSvgSize.height,
                child: SvgPicture.asset(
                  vehicleAnatomyAssetPath(bodyType, view),
                  fit: BoxFit.fill,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: _CroppedInspectionMarkersOverlay(
                    marks: marks,
                    markerSize: markerSize,
                    geometry: geometry,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InspectionMarkersOverlay extends StatelessWidget {
  const _InspectionMarkersOverlay({
    required this.marks,
    required this.markerSize,
    required this.fit,
  });

  final List<VehicleInspectionMark> marks;
  final double markerSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: marks.map((mark) {
            final point = _fittedBoxPointForSvgPoint(
              Offset(mark.x, mark.y),
              size,
              fit,
            );
            return Positioned(
              left: point.dx - markerSize / 2,
              top: point.dy - markerSize / 2,
              child: _InspectionMarkerBubble(
                sequence: mark.sequence,
                markerSize: markerSize,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CroppedInspectionMarkersOverlay extends StatelessWidget {
  const _CroppedInspectionMarkersOverlay({
    required this.marks,
    required this.markerSize,
    required this.geometry,
  });

  final List<VehicleInspectionMark> marks;
  final double markerSize;
  final _CroppedGeometry geometry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: marks.map((mark) {
        final point = geometry.boxPointForSvgPoint(Offset(mark.x, mark.y));
        return Positioned(
          left: point.dx - markerSize / 2,
          top: point.dy - markerSize / 2,
          child: _InspectionMarkerBubble(
            sequence: mark.sequence,
            markerSize: markerSize,
          ),
        );
      }).toList(),
    );
  }
}

class _InspectionMarkerBubble extends StatelessWidget {
  const _InspectionMarkerBubble({
    required this.sequence,
    required this.markerSize,
  });

  final int sequence;
  final double markerSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        color: AppPalette.red,
        borderRadius: BorderRadius.circular(markerSize),
        border: Border.all(color: AppPalette.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        sequence.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppPalette.white,
          fontWeight: FontWeight.w800,
          fontSize: markerSize <= 16 ? 8 : 10,
        ),
      ),
    );
  }
}

class _InspectionMarkTile extends StatelessWidget {
  const _InspectionMarkTile({
    required this.mark,
    required this.active,
    required this.onDeleted,
  });

  final VehicleInspectionMark mark;
  final bool active;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppPalette.red.withValues(alpha: 0.08)
            : AppPalette.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? AppPalette.red : AppPalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppPalette.red,
            child: Text(
              mark.sequence.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppPalette.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mark.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            tooltip: 'Remove mark',
            onPressed: onDeleted,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _InspectionAnatomyPlate extends StatelessWidget {
  const _InspectionAnatomyPlate({
    required this.bodyType,
    required this.marks,
    required this.panelHeight,
  });

  final VehicleBodyType bodyType;
  final List<VehicleInspectionMark> marks;
  final double panelHeight;

  List<VehicleInspectionMark> _marksFor(VehicleViewAngle view) {
    return marks.where((mark) => mark.view == view).toList();
  }

  Widget _viewPanel(
    VehicleViewAngle view, {
    required double height,
    double? width,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: _AnatomyCanvas(
        bodyType: bodyType,
        view: view,
        marks: _marksFor(view),
        interactive: false,
        fit: BoxFit.contain,
        markerSize: 15,
        renderMode: _AnatomyRenderMode.cropped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final gap = (width * 0.014).clamp(4.0, 6.0).toDouble();
        final cellWidth = (width - gap * 2) / 3;
        final cellHeight = (cellWidth * 0.72)
            .clamp(panelHeight * 0.62, panelHeight)
            .toDouble();

        return Column(
          children: [
            Row(
              children: [
                _viewPanel(
                  VehicleViewAngle.top,
                  height: cellHeight,
                  width: cellWidth,
                ),
                SizedBox(width: gap),
                _viewPanel(
                  VehicleViewAngle.front,
                  height: cellHeight,
                  width: cellWidth,
                ),
                SizedBox(width: gap),
                _viewPanel(
                  VehicleViewAngle.right,
                  height: cellHeight,
                  width: cellWidth,
                ),
              ],
            ),
            SizedBox(height: gap),
            Row(
              children: [
                _viewPanel(
                  VehicleViewAngle.back,
                  height: cellHeight,
                  width: cellWidth,
                ),
                SizedBox(width: gap),
                _viewPanel(
                  VehicleViewAngle.left,
                  height: cellHeight,
                  width: cellWidth,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _InspectionMarkBodyGroup {
  const _InspectionMarkBodyGroup({required this.bodyType, required this.marks});

  final VehicleBodyType bodyType;
  final List<VehicleInspectionMark> marks;
}

List<_InspectionMarkBodyGroup> _groupMarksByBody(
  List<VehicleInspectionMark> marks,
) {
  final groups = <_InspectionMarkBodyGroup>[];
  for (final mark in marks) {
    final index = groups.indexWhere((group) => group.bodyType == mark.bodyType);
    if (index == -1) {
      groups.add(
        _InspectionMarkBodyGroup(bodyType: mark.bodyType, marks: [mark]),
      );
    } else {
      groups[index].marks.add(mark);
    }
  }
  for (final group in groups) {
    group.marks.sort((left, right) => left.sequence.compareTo(right.sequence));
  }
  return groups;
}
