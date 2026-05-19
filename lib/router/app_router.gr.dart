// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DeviceDiscoveryScreen]
class DeviceDiscoveryRoute extends PageRouteInfo<void> {
  const DeviceDiscoveryRoute({List<PageRouteInfo>? children})
    : super(DeviceDiscoveryRoute.name, initialChildren: children);

  static const String name = 'DeviceDiscoveryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DeviceDiscoveryScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [LayoutEditorScreen]
class LayoutEditorRoute extends PageRouteInfo<LayoutEditorRouteArgs> {
  LayoutEditorRoute({
    Key? key,
    required RemoteLayout layout,
    List<PageRouteInfo>? children,
  }) : super(
         LayoutEditorRoute.name,
         args: LayoutEditorRouteArgs(key: key, layout: layout),
         initialChildren: children,
       );

  static const String name = 'LayoutEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LayoutEditorRouteArgs>();
      return LayoutEditorScreen(key: args.key, layout: args.layout);
    },
  );
}

class LayoutEditorRouteArgs {
  const LayoutEditorRouteArgs({this.key, required this.layout});

  final Key? key;

  final RemoteLayout layout;

  @override
  String toString() {
    return 'LayoutEditorRouteArgs{key: $key, layout: $layout}';
  }
}

/// generated route for
/// [LayoutPickerScreen]
class LayoutPickerRoute extends PageRouteInfo<void> {
  const LayoutPickerRoute({List<PageRouteInfo>? children})
    : super(LayoutPickerRoute.name, initialChildren: children);

  static const String name = 'LayoutPickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LayoutPickerScreen();
    },
  );
}
