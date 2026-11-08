import 'package:flutter/material.dart';

/// Screen width at which we switch from phone layout to tablet/desktop layout.
const double kWideLayoutBreakpoint = 700;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;

/// Keeps content from stretching too wide on tablets, desktop and web.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 1000});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Number of grid/list columns that fits the available width.
int columnsForWidth(double width, {double minItemWidth = 360}) {
  final count = (width / minItemWidth).floor();
  return count.clamp(1, 4);
}

/// Shows loading, error (with retry) or empty states, otherwise [child].
class AsyncStateView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRetry;
  final Widget child;

  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyMessage = 'Nothing here yet',
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        message: error!,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }
    if (isEmpty) {
      // Still scrollable so pull-to-refresh works on an empty list.
      return RefreshIndicator(
        onRefresh: onRetry,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _Message(icon: emptyIcon, message: emptyMessage),
            ),
          ),
        ),
      );
    }
    return child;
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.green[300]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One "icon  Label: value" line that wraps long values instead of overflowing.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? labelColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: iconColor ?? Colors.green[700]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: labelColor ?? Colors.green[800],
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured pill for an order status.
class StatusChip extends StatelessWidget {
  final String? status;

  const StatusChip({super.key, required this.status});

  Color _color() {
    final s = (status ?? '').toLowerCase();
    if (s.contains('deliver') || s.contains('complete') || s.contains('paid')) {
      return Colors.green;
    }
    if (s.contains('cancel') || s.contains('reject') || s.contains('fail')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        (status == null || status!.isEmpty) ? 'Unknown' : status!,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

/// Network image with a loading spinner and a broken-image fallback.
class NetworkImageBox extends StatelessWidget {
  final String? url;
  final double? height;
  final BorderRadius borderRadius;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: Colors.green[100],
      child: Icon(Icons.image_not_supported_outlined,
          size: 48, color: Colors.green[400]),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : SizedBox(
                      height: height,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green[700],
    ));
}

/// Formats numbers like 12.0 as "12" and 12.5 as "12.5".
String formatNum(dynamic value) {
  if (value == null) return 'N/A';
  final n = value is num ? value : num.tryParse(value.toString());
  if (n == null) return value.toString();
  return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
}

double toDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

/// Validator for positive numbers in forms.
String? validatePositiveNumber(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) return 'Please enter $fieldName';
  final n = double.tryParse(value.trim());
  if (n == null) return 'Enter a valid number';
  if (n <= 0) return '$fieldName must be more than 0';
  return null;
}

const String kNetworkError =
    'Could not reach the server.\nCheck that the backend is running and the IP in ipfile.dart is correct.';
