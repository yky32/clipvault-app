import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_palette.dart';

class PaletteController extends ChangeNotifier {
  static const _key = 'brand_palette';

  BrandPaletteId _id = BrandPalettes.defaultId;
  BrandPaletteId get id => _id;
  BrandPaletteTokens get tokens => BrandPalettes.of(_id);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _id = switch (raw) {
      'deepBrown' => BrandPaletteId.deepBrown,
      'woodBlue' => BrandPaletteId.woodBlue,
      'inkBlue' => BrandPaletteId.inkBlue,
      'warmGrey' => BrandPaletteId.warmGrey,
      _ => BrandPalettes.defaultId,
    };
    notifyListeners();
  }

  Future<void> setPalette(BrandPaletteId id) async {
    if (_id == id) return;
    _id = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      switch (id) {
        BrandPaletteId.deepBrown => 'deepBrown',
        BrandPaletteId.warmGrey => 'warmGrey',
        BrandPaletteId.woodBlue => 'woodBlue',
        BrandPaletteId.inkBlue => 'inkBlue',
      },
    );
  }
}

class PaletteScope extends InheritedNotifier<PaletteController> {
  const PaletteScope({
    required PaletteController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static PaletteController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaletteScope>();
    assert(scope != null, 'PaletteScope not found');
    return scope!.notifier!;
  }

  static PaletteController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PaletteScope>()
        ?.notifier;
  }
}
