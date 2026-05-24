import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/features/device_discovery/screens/device_discovery_screen.dart';
import 'package:flixsy/features/home/screens/home_screen.dart';
import 'package:flixsy/features/layout_editor/screens/layout_editor_screen.dart';
import 'package:flixsy/features/layout_picker/screens/layout_picker_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: DeviceDiscoveryRoute.page, initial: true),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: LayoutPickerRoute.page),
    AutoRoute(page: LayoutEditorRoute.page),
  ];
}
