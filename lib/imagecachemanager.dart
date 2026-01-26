import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppImageCacheManager extends CacheManager {
  static const key = 'appImageCache';

  static final AppImageCacheManager _instance =
      AppImageCacheManager._internal();

  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._internal()
      : super(
          Config(
            key,
            stalePeriod: const Duration(hours: 24), // 🔥 CHANGE THIS TIME
            maxNrOfCacheObjects: 200,
          ),
        );
}

