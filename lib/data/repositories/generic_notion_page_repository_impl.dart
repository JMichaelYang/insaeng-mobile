import 'package:flutter/services.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/data/services/secure_storage_service.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';

final class GenericNotionPageRepositoryImpl implements GenericPageRepository {
  const new(this._storage);

  static const connectTitle = 'Connect Notion';
  static const connectDescription = 'Paste a Notion integration token to see your day.';
  static const tokenLabel = 'Notion token';
  static const connectLabel = 'Connect';
  static const connectErrorText = "Couldn't save the token. Try again.";

  static final GenericPage connectPage = GenericPage(
    id: MyDayPageMapper.pageId,
    state: GenericValues(const {
      'notion': {'token': ''},
      'saving': false,
    }),
    root: const ColumnNode(
      id: 'root',
      children: [
        AppBarNode(id: 'appBar', title: Literal(MyDayPageMapper.title)),
        ExpandedNode(
          id: 'body',
          child: ScrollNode(
            id: 'scroll',
            child: ContainerNode(
              id: 'content',
              padding: Literal(SpacingToken.lg),
              child: ColumnNode(
                id: 'connect',
                spacing: Literal(SpacingToken.md),
                alignment: Literal(AlignmentToken.stretch),
                children: [
                  TextNode(id: 'connectTitle', text: Literal(connectTitle), style: Literal(TextStyleToken.titleLarge)),
                  TextNode(id: 'connectDescription', text: Literal(connectDescription)),
                  TextFieldNode(id: 'token', bind: 'notion.token', label: Literal(tokenLabel), secure: Literal(true)),
                  ButtonNode(
                    id: 'connectButton',
                    label: Literal(connectLabel),
                    loading: Binding('saving', fallback: false),
                    onTap: [
                      UpdateStateAction(path: 'saving', value: Literal(true)),
                      RequestAction(
                        method: Literal(RequestMethod.put),
                        endpoint: Literal('/notion/token'),
                        body: JsonObject({'token': JsonBinding(Binding('notion.token'))}),
                        onError: [ShowMessageAction(text: Literal(connectErrorText))],
                        onComplete: [UpdateStateAction(path: 'saving', value: Literal(false))],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  final SecureStorageService _storage;

  @override
  Future<Result<GenericPage>> fetch(String id, Map<String, String> params) => switch (id) {
    MyDayPageMapper.pageId => _myDay(),
    _ => Future.value(const Result.err(GenericPageNotFound())),
  };

  Future<Result<GenericPage>> _myDay() async {
    final String? token;
    try {
      token = await _storage.read(SecureStorageService.notionTokenKey);
    } on PlatformException {
      return const Result.err(GenericPageServerError());
    }
    if (token == null || token.isEmpty) return Result.ok(connectPage);
    return Result.ok(MyDayPageMapper.fromRows(const [], now: DateTime.now()));
  }
}
