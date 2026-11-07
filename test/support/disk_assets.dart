import 'dart:io';

import 'package:filmbuster/data/local/bundled_catalog.dart';
import 'package:filmbuster/data/local/catalog_contents.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serves assets from disk synchronously, so they resolve inside the widget
/// tester's fake async zone (tests run from `client/`).
class DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      SynchronousFuture(ByteData.sublistView(File(key).readAsBytesSync()));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(File(key).readAsStringSync());
}

CatalogContents bundledCatalogContents() =>
    CatalogContents.parse(File(BundledCatalog.assetKey).readAsStringSync());

BundledCatalog bundledCatalogFromDisk() =>
    BundledCatalog((key) => File(key).readAsString());
