import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/services/nearby/nearby_models.dart';
import '../../../../core/services/nearby/nearby_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/copied_hud.dart';
import '../../../../l10n/app_localizations.dart';
import '../../vault/bloc/vault_bloc.dart';

/// Pick a nearby ClipVal device, enter their session PIN, send item.
class NearbySendSheet extends StatefulWidget {
  const NearbySendSheet({
    required this.title,
    required this.value,
    this.categoryName,
    this.isSensitive = false,
    super.key,
  });

  final String title;
  final String value;
  final String? categoryName;
  final bool isSensitive;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String value,
    String? categoryName,
    bool isSensitive = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NearbySendSheet(
        title: title,
        value: value,
        categoryName: categoryName,
        isSensitive: isSensitive,
      ),
    );
  }

  @override
  State<NearbySendSheet> createState() => _NearbySendSheetState();
}

class _NearbySendSheetState extends State<NearbySendSheet> {
  List<NearbyDevice> _devices = [];
  StreamSubscription<List<NearbyDevice>>? _sub;
  bool _scanning = true;
  String? _sendingToId;
  String? _status;
  final _pinController = TextEditingController();
  NearbyDevice? _selected;

  @override
  void initState() {
    super.initState();
    _sub = NearbyService.instance.devices$.listen((list) {
      if (!mounted) return;
      setState(() => _devices = list);
    });
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _status = null;
    });
    try {
      await NearbyService.instance.startIfEnabled();
      final list = await NearbyService.instance.discover();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _scanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _status = '$e';
      });
    }
  }

  Future<void> _send() async {
    final device = _selected;
    if (device == null) return;
    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _status = l10n.nearbyPinInvalid);
      return;
    }

    setState(() {
      _sendingToId = device.id;
      _status = null;
    });
    HapticFeedback.selectionClick();
    final report = await NearbyService.instance.sendItem(
      device: device,
      title: widget.title,
      value: widget.value,
      pin: pin,
      categoryName: widget.categoryName,
      isSensitive: widget.isSensitive,
    );
    if (!mounted) return;
    setState(() => _sendingToId = null);

    final msg = switch (report.result) {
      NearbySendResult.accepted => l10n.nearbySendAccepted(device.name),
      NearbySendResult.rejected => l10n.nearbySendRejected(device.name),
      NearbySendResult.timeout => l10n.nearbySendTimeout,
      NearbySendResult.unreachable => l10n.nearbySendUnreachable,
      NearbySendResult.disabled => l10n.nearbyDisabledHint,
      NearbySendResult.cancelled => l10n.cancel,
      NearbySendResult.badPin => l10n.nearbyPinWrong,
      NearbySendResult.error => report.message ?? l10n.nearbySendError,
    };

    if (report.result == NearbySendResult.accepted) {
      Navigator.pop(context);
      if (context.mounted) {
        CopiedHud.show(context, message: msg);
      }
    } else {
      setState(() => _status = msg);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final busy = _sendingToId != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: BoxDecoration(
          color: AppColors.groupedBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.tertiaryLabel(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.nearbySendTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: _scanning || busy ? null : _scan,
                    child: _scanning
                        ? const CupertinoActivityIndicator()
                        : Icon(CupertinoIcons.refresh, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.nearbySendSubtitlePin,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryLabel(context),
                ),
              ),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _status!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            Flexible(
              child: _devices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _scanning ? l10n.nearbyScanning : l10n.nearbyNoDevices,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryLabel(context),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = _devices[i];
                        final selected = _selected?.id == d.id;
                        return Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.cardBackground(context),
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            leading: Icon(
                              CupertinoIcons.antenna_radiowaves_left_right,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              d.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              d.host,
                              style: TextStyle(
                                color: AppColors.tertiaryLabel(context),
                                fontSize: 13,
                              ),
                            ),
                            trailing: selected
                                ? Icon(CupertinoIcons.checkmark_circle_fill,
                                    color: AppColors.primary)
                                : null,
                            onTap: busy
                                ? null
                                : () => setState(() => _selected = d),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.nearbyPinLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    placeholder: '••••••',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    enabled: !busy,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy || _selected == null ? null : _send,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.nearbySendAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Host-level listener: Accept/Reject incoming nearby offers (queued).
class NearbyOfferHost extends StatefulWidget {
  const NearbyOfferHost({required this.child, super.key});
  final Widget child;

  @override
  State<NearbyOfferHost> createState() => _NearbyOfferHostState();
}

class _NearbyOfferHostState extends State<NearbyOfferHost> {
  StreamSubscription<NearbyIncomingOffer>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = NearbyService.instance.incomingOffers.listen(_onOffer);
  }

  Future<void> _onOffer(NearbyIncomingOffer offer) async {
    if (!mounted) {
      offer.reject();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final payload = offer.payload;
    final preview = payload.isSensitive
        ? '••••'
        : (payload.value.length > 80
            ? '${payload.value.substring(0, 80)}…'
            : payload.value);

    final accepted = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.nearbyReceiveTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Text(l10n.nearbyReceiveFrom(payload.fromName)),
              const SizedBox(height: 10),
              Text(
                payload.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                preview,
                style: TextStyle(
                  color: AppColors.secondaryLabel(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.nearbyReceivePrivacyNote,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.tertiaryLabel(context),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.nearbyDecline),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.nearbyAcceptSave),
          ),
        ],
      ),
    );

    if (accepted == true) {
      try {
        await AppBootstrap.clipItemRepository.create(
          title: payload.title,
          value: payload.value,
          isSensitive: payload.isSensitive,
        );
        offer.accept();
        if (mounted) {
          try {
            context.read<VaultBloc>().add(const VaultRefreshed());
          } catch (_) {}
          CopiedHud.show(
            context,
            message: AppLocalizations.of(context).nearbyReceiveSaved,
          );
        }
      } catch (e) {
        offer.reject();
        if (mounted) {
          CopiedHud.show(context, message: '$e');
        }
      }
    } else {
      offer.reject();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
