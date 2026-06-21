import 'package:blood_donation/provider/network_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wraps the whole app. When the device goes offline it shows a slim banner at
/// the top INSTEAD of replacing the entire UI. Replacing the UI used to defeat
/// Firestore's offline cache — the user couldn't read already-loaded chats,
/// requests or directories, or queue actions, which is exactly when an
/// emergency blood app needs to keep working on a flaky connection.
class NetworkWrapper extends StatelessWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, _) {
        return Stack(
          children: [
            Positioned.fill(child: child),
            if (networkProvider.isOffline)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _OfflineBanner(),
              ),
          ],
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "You're offline — showing saved data.",
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
