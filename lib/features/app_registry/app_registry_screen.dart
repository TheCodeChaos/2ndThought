import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import '../../core/database/db_helper.dart';
import '../../core/providers/blocked_apps_provider.dart';
import '../../shared/theme/color_tokens.dart';
import 'widgets/app_tile.dart';

// Simple app info model for the registry
class InstalledAppInfo {
  final String appName;
  final String packageName;

  InstalledAppInfo({required this.appName, required this.packageName});
}

class AppRegistryScreen extends ConsumerStatefulWidget {
  const AppRegistryScreen({super.key});

  @override
  ConsumerState<AppRegistryScreen> createState() => _AppRegistryScreenState();
}

class _AppRegistryScreenState extends ConsumerState<AppRegistryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<InstalledAppInfo>> _deviceAppsFuture;

  @override
  void initState() {
    super.initState();
    _deviceAppsFuture = _loadDeviceApps();
  }

  Future<List<InstalledAppInfo>> _loadDeviceApps() async {
    try {
      debugPrint('[AppRegistry] Loading device apps...');

      // Get list of installed apps from the device
      final List<dynamic> installedApps =
          await InstalledApps.getInstalledApps();

      // Convert to InstalledAppInfo
      final List<InstalledAppInfo> apps = <InstalledAppInfo>[];
      for (final app in installedApps) {
        try {
          // Extract app name and package name from app object
          final appName = _getAppName(app);
          final packageName = _getPackageName(app);

          if (appName != null && packageName != null) {
            apps.add(
              InstalledAppInfo(appName: appName, packageName: packageName),
            );
          }
        } catch (e) {
          debugPrint('[AppRegistry] Error processing app: $e');
        }
      }

      // Sort by app name
      apps.sort((a, b) => a.appName.compareTo(b.appName));

      debugPrint('[AppRegistry] Loaded ${apps.length} apps from device');
      return apps;
    } catch (e) {
      debugPrint('[AppRegistry] Error loading device apps: $e');
      // Return empty list if error occurs
      return [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getAppName(dynamic app) {
    try {
      // Try different possible property names
      if (app is Map) {
        return (app['name'] ?? app['appName'] ?? app['app_name'])?.toString();
      }
      // If it's an object with properties
      if (app.name != null) {
        return app.name.toString();
      }
      if (app.appName != null) {
        return app.appName.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? _getPackageName(dynamic app) {
    try {
      // Try different possible property names
      if (app is Map) {
        return (app['packageName'] ?? app['package_name'])?.toString();
      }
      // If it's an object with properties
      if (app.packageName != null) {
        return app.packageName.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedAppsAsync = ref.watch(blockedAppsProvider);
    final blockedPackages =
        blockedAppsAsync.valueOrNull?.map((a) => a.packageName).toSet() ?? {};

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APP REGISTRY',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${blockedPackages.length} apps blocked',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 12,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: kSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kDivider),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        color: kTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search apps...',
                        hintStyle: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 14,
                          color: kTextSecondary.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: kTextSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<InstalledAppInfo>>(
                future: _deviceAppsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error loading apps: ${snapshot.error}',
                          style: const TextStyle(color: kTextSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final deviceApps = snapshot.data ?? [];

                  if (deviceApps.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'No apps found on this device',
                          style: const TextStyle(color: kTextSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final filteredApps = deviceApps.where((app) {
                    if (_searchQuery.isEmpty) return true;
                    return app.appName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        app.packageName.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isBlocked = blockedPackages.contains(
                        app.packageName,
                      );

                      return AppTile(
                        appName: app.appName,
                        packageName: app.packageName,
                        isBlocked: isBlocked,
                        onToggle: (blocked) async {
                          if (blocked) {
                            await ref
                                .read(blockedAppsProvider.notifier)
                                .add(
                                  BlockedApp(
                                    packageName: app.packageName,
                                    appName: app.appName,
                                    addedAt:
                                        DateTime.now().millisecondsSinceEpoch,
                                  ),
                                );
                          } else {
                            await ref
                                .read(blockedAppsProvider.notifier)
                                .remove(app.packageName);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
