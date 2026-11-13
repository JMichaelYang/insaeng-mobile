abstract final class Routes {
  static const String homePageId = 'home';
  static const String pageIdParameter = 'pageId';

  static const String home = '/';
  static const String page = '/p/:$pageIdParameter';

  static String pageLocation(String pageId, [Map<String, String> params = const {}]) => Uri(
    path: pageId == homePageId ? home : '/p/${Uri.encodeComponent(pageId)}',
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}
