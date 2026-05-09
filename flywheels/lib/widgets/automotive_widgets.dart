import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flutter/material.dart';

class AutomotiveControlButton extends StatelessWidget {
  const AutomotiveControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final foreground = active ? AppPalette.white : AppPalette.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          constraints: BoxConstraints(
            minHeight: compact ? 54 : 72,
            minWidth: compact ? 54 : 72,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: active ? AppPalette.black : AppPalette.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppPalette.black : AppPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: (active ? AppPalette.red : AppPalette.black).withValues(
                  alpha: active ? 0.18 : 0.08,
                ),
                blurRadius: active ? 18 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: compact ? 19 : 22),
                const SizedBox(height: 5),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                LedIndicator(active: active && isEnabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LedIndicator extends StatelessWidget {
  const LedIndicator({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: active ? 30 : 18,
      height: 3,
      decoration: BoxDecoration(
        color: active
            ? AppPalette.red
            : AppPalette.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppPalette.red.withValues(alpha: 0.55),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}

class GearboxActionGrid extends StatelessWidget {
  const GearboxActionGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final columns = isNarrow ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: isNarrow ? 86 : 82,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class HorizontalServiceTimeline extends StatelessWidget {
  const HorizontalServiceTimeline({
    super.key,
    required this.status,
    this.compact = false,
  });

  final JobStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const statuses = JobStatus.values;
    final activeIndex = statuses.indexOf(status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = compact ? 54.0 : 96.0;
        final carSize = compact ? 24.0 : 32.0;
        final nodeSize = compact ? 14.0 : 22.0;
        final trackTop = compact ? 28.0 : 36.0;
        final labelTop = trackTop + 16;
        final usableTrack = (width - nodeSize).clamp(0.0, double.infinity);
        final progress = statuses.length <= 1
            ? 0.0
            : activeIndex / (statuses.length - 1);
        final carLeft = (progress * (width - carSize)).clamp(
          0.0,
          (width - carSize).clamp(0.0, double.infinity),
        );

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: nodeSize / 2,
                right: nodeSize / 2,
                top: trackTop + nodeSize / 2 - 2,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Positioned(
                left: nodeSize / 2,
                top: trackTop + nodeSize / 2 - 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  width: progress * usableTrack,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.red,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                left: carLeft,
                top: compact ? 1 : 2,
                child: _TimelineCarMarker(size: carSize),
              ),
              ...List.generate(statuses.length, (index) {
                final left = statuses.length <= 1
                    ? 0.0
                    : index * (width - nodeSize) / (statuses.length - 1);
                final isReached = index <= activeIndex;
                final isActive = index == activeIndex;
                final isFinal = index == statuses.length - 1;
                return Positioned(
                  left: left,
                  top: trackTop,
                  child: _TimelineNode(
                    size: nodeSize,
                    reached: isReached,
                    active: isActive,
                    finalNode: isFinal,
                  ),
                );
              }),
              if (!compact)
                ...List.generate(statuses.length, (index) {
                  final segmentWidth = width / statuses.length;
                  final isReached = index <= activeIndex;
                  final isActive = index == activeIndex;
                  return Positioned(
                    left: index * segmentWidth,
                    top: labelTop,
                    width: segmentWidth,
                    child: Text(
                      statuses[index].label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive ? AppPalette.red : AppPalette.black,
                        fontWeight: isReached
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineCarMarker extends StatelessWidget {
  const _TimelineCarMarker({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.red, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppPalette.red.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.directions_car_filled_rounded,
        color: AppPalette.red,
        size: size * 0.68,
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.size,
    required this.reached,
    required this.active,
    required this.finalNode,
  });

  final double size;
  final bool reached;
  final bool active;
  final bool finalNode;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: finalNode && reached
            ? AppPalette.black
            : reached
            ? AppPalette.red
            : AppPalette.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: reached ? AppPalette.red : AppPalette.border,
          width: active ? 2.4 : 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppPalette.red.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: reached
          ? finalNode
                ? Center(child: _FinishFlagIcon(size: size * 0.62))
                : Icon(
                    Icons.check_rounded,
                    color: AppPalette.white,
                    size: size * 0.62,
                  )
          : null,
    );
  }
}

class MessengerBubble extends StatelessWidget {
  const MessengerBubble({
    super.key,
    required this.message,
    required this.fromCurrentUser,
    this.carLabel,
    this.avatarPath,
    this.avatarInitials,
  });

  final SupportMessage message;
  final bool fromCurrentUser;
  final String? carLabel;
  final String? avatarPath;
  final String? avatarInitials;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = fromCurrentUser ? AppPalette.red : AppPalette.white;
    final textColor = fromCurrentUser ? AppPalette.white : AppPalette.black;

    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      constraints: const BoxConstraints(maxWidth: 318),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(fromCurrentUser ? 16 : 4),
          bottomRight: Radius.circular(fromCurrentUser ? 4 : 16),
        ),
        border: fromCurrentUser ? null : Border.all(color: AppPalette.border),
        boxShadow: [
          BoxShadow(
            color: AppPalette.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            carLabel == null ? message.topic : '${message.topic} | $carLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: fromCurrentUser ? 0.82 : 0.64),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.28),
          ),
          if (message.attachmentPath != null) ...[
            const SizedBox(height: 8),
            _MessageAttachment(
              path: message.attachmentPath!,
              fromCurrentUser: fromCurrentUser,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatDateTime(message.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(
                    alpha: fromCurrentUser ? 0.78 : 0.5,
                  ),
                  letterSpacing: 0,
                ),
              ),
              if (fromCurrentUser) ...[
                const SizedBox(width: 6),
                Icon(
                  message.isRead
                      ? Icons.done_all_rounded
                      : message.isDelivered
                      ? Icons.done_all_rounded
                      : Icons.check_rounded,
                  size: 15,
                  color: AppPalette.white.withValues(
                    alpha: message.isRead ? 1 : 0.7,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  message.isRead ? 'Read' : 'Delivered',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppPalette.white.withValues(alpha: 0.78),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: fromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromCurrentUser) ...[
            MessengerAvatar(path: avatarPath, initials: avatarInitials),
            const SizedBox(width: 8),
          ],
          bubble,
          if (fromCurrentUser) ...[
            const SizedBox(width: 8),
            MessengerAvatar(path: avatarPath, initials: avatarInitials),
          ],
        ],
      ),
    );
  }
}

class _FinishFlagIcon extends StatelessWidget {
  const _FinishFlagIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _FinishFlagPainter());
  }
}

class _FinishFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final polePaint = Paint()
      ..color = AppPalette.white
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round;
    final flagPaint = Paint()..color = AppPalette.white;
    final squarePaint = Paint()..color = AppPalette.black;
    final poleX = size.width * 0.2;

    canvas.drawLine(
      Offset(poleX, size.height * 0.12),
      Offset(poleX, size.height * 0.9),
      polePaint,
    );

    final flag = Rect.fromLTWH(
      poleX,
      size.height * 0.14,
      size.width * 0.62,
      size.height * 0.42,
    );
    canvas.drawPath(
      Path()
        ..moveTo(flag.left, flag.top)
        ..lineTo(flag.right, flag.top + size.height * 0.06)
        ..lineTo(flag.right - size.width * 0.08, flag.bottom)
        ..lineTo(flag.left, flag.bottom - size.height * 0.06)
        ..close(),
      flagPaint,
    );

    final cellWidth = flag.width / 3;
    final cellHeight = flag.height / 2;
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 3; column++) {
        if ((row + column).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(
              flag.left + column * cellWidth,
              flag.top + row * cellHeight,
              cellWidth,
              cellHeight,
            ),
            squarePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FinishFlagPainter oldDelegate) => false;
}

class _MessageAttachment extends StatelessWidget {
  const _MessageAttachment({required this.path, required this.fromCurrentUser});

  final String path;
  final bool fromCurrentUser;

  bool get _isImage {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.startsWith('http');
  }

  bool get _isPdf => path.toLowerCase().endsWith('.pdf');

  String get _fileName {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    return name.trim().isEmpty ? 'Attachment' : name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage && !_isPdf) {
      return AppImage(
        path: path,
        width: 270,
        height: 146,
        borderRadius: BorderRadius.circular(8),
      );
    }

    final foreground = fromCurrentUser ? AppPalette.white : AppPalette.black;
    final background = fromCurrentUser
        ? AppPalette.white.withValues(alpha: 0.14)
        : AppPalette.soft;
    return Container(
      width: 270,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fromCurrentUser
              ? AppPalette.white.withValues(alpha: 0.28)
              : AppPalette.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPdf ? Icons.picture_as_pdf_rounded : Icons.attach_file_rounded,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessengerAvatar extends StatelessWidget {
  const MessengerAvatar({
    super.key,
    this.path,
    this.initials,
    this.radius = 15,
  });

  final String? path;
  final String? initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (path != null && path!.trim().isNotEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.border),
        ),
        child: ClipOval(
          child: AppImage(path: path!, fit: BoxFit.cover),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppPalette.soft,
      child: Text(
        (initials == null || initials!.isEmpty) ? 'F' : initials!,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
