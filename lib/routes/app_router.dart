import 'package:flutter/material.dart';

final appRouter = RouterConfig<Object?>(
  routerDelegate: RootRouterDelegate(),
  routeInformationParser: RootRouteParser(),
);

class RootRouterDelegate extends RouterDelegate<Object?> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }

  @override
  Future<void> setNewRoutePath(Object? configuration) async {}
}

class RootRouteParser extends RouteInformationParser<Object?> {
  @override
  Future<Object?> parseRouteInformation(
      RouteInformation routeInformation) async {
    return null;
  }
}
