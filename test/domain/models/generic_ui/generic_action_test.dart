import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';

GenericAction _decode(Map<String, Object?> json) => GenericActionMapper.fromMap(json);

void main() {
  group(GenericAction, () {
    group(UpdateStateAction, () {
      test('decodes with defaults', () {
        expect(_decode({'type': 'updateState', 'path': 'count'}), const UpdateStateAction(path: 'count'));
      });

      test('decodes every op', () {
        for (final op in UpdateOp.values) {
          expect(
            _decode({'type': 'updateState', 'path': 'count', 'op': op.name}),
            UpdateStateAction(path: 'count', op: Literal(op)),
            reason: op.name,
          );
        }
      });

      test('decodes literal values of any JSON type', () {
        for (final value in <Object>[
          1,
          'text',
          true,
          [1, 2],
          {'k': 'v'},
        ]) {
          expect(
            _decode({'type': 'updateState', 'path': 'p', 'value': value}),
            isA<UpdateStateAction>().having((a) => a.value, 'value', Literal<Object>(value)),
          );
        }
      });

      test('decodes bound op and value', () {
        expect(
          _decode({
            'type': 'updateState',
            'path': 'todos',
            'op': {r'$bind': 'mode', 'fallback': 'append'},
            'value': {r'$bind': 'draft'},
          }),
          const UpdateStateAction(
            path: 'todos',
            op: Binding('mode', fallback: UpdateOp.append),
            value: Binding<Object>('draft'),
          ),
        );
      });

      test('fails without a path or with an unknown op', () {
        expect(() => _decode({'type': 'updateState'}), throwsA(isA<MapperException>()));
        expect(() => _decode({'type': 'updateState', 'path': 'p', 'op': 'multiply'}), throwsA(isA<MapperException>()));
      });
    });

    group(NavigateAction, () {
      test('decodes with defaults', () {
        expect(_decode({'type': 'navigate', 'pageId': 'home'}), const NavigateAction(pageId: Literal('home')));
      });

      test('decodes params and replace', () {
        expect(
          _decode({
            'type': 'navigate',
            'pageId': 'detail',
            'params': {'id': '7'},
            'replace': true,
          }),
          const NavigateAction(pageId: Literal('detail'), params: Literal({'id': '7'}), replace: Literal(true)),
        );
      });

      test('decodes bound fields', () {
        expect(
          _decode({
            'type': 'navigate',
            'pageId': {r'$bind': 'next'},
            'params': {r'$bind': 'selected'},
            'replace': {r'$bind': 'replace', 'fallback': false},
          }),
          const NavigateAction(
            pageId: Binding('next'),
            params: Binding('selected'),
            replace: Binding('replace', fallback: false),
          ),
        );
      });

      test('decodes scalar param values as strings', () {
        expect(
          _decode({
            'type': 'navigate',
            'pageId': 'detail',
            'params': {'id': 7, 'open': true},
          }),
          const NavigateAction(pageId: Literal('detail'), params: Literal({'id': '7', 'open': 'true'})),
        );
      });

      test('fails without a pageId or with params that are not an object', () {
        expect(() => _decode({'type': 'navigate'}), throwsA(isA<MapperException>()));
        expect(
          () => _decode({'type': 'navigate', 'pageId': 'home', 'params': 'id=7'}),
          throwsA(isA<MapperException>()),
        );
      });
    });

    group(BackAction, () {
      test('decodes', () {
        expect(_decode({'type': 'back'}), const BackAction());
      });
    });

    group(ReloadAction, () {
      test('decodes', () {
        expect(_decode({'type': 'reload'}), const ReloadAction());
      });

      test('decodes onError and onComplete', () {
        expect(
          _decode({
            'type': 'reload',
            'onError': [
              {'type': 'showMessage', 'text': 'Failed'},
              {'type': 'confetti'},
            ],
            'onComplete': [
              {'type': 'updateState', 'path': 'refreshing', 'value': false},
            ],
          }),
          const ReloadAction(
            onError: [
              ShowMessageAction(text: Literal('Failed')),
              UnknownAction(),
            ],
            onComplete: [UpdateStateAction(path: 'refreshing', value: Literal(false))],
          ),
        );
      });

      test('childActions lists onError and then onComplete', () {
        const action = ReloadAction(onError: [BackAction()], onComplete: [ReloadAction()]);

        expect(action.childActions, const [BackAction(), ReloadAction()]);
      });

      test('fails when onError or onComplete is not a list', () {
        expect(() => _decode({'type': 'reload', 'onError': 'back'}), throwsA(isA<MapperException>()));
        expect(() => _decode({'type': 'reload', 'onComplete': 'back'}), throwsA(isA<MapperException>()));
      });
    });

    group(ShowMessageAction, () {
      test('decodes literal and bound text', () {
        expect(_decode({'type': 'showMessage', 'text': 'Saved'}), const ShowMessageAction(text: Literal('Saved')));
        expect(
          _decode({
            'type': 'showMessage',
            'text': {r'$bind': 'error', 'fallback': 'Oops'},
          }),
          const ShowMessageAction(text: Binding('error', fallback: 'Oops')),
        );
      });

      test('fails without text', () {
        expect(() => _decode({'type': 'showMessage'}), throwsA(isA<MapperException>()));
      });
    });

    group(OpenUrlAction, () {
      test('decodes literal and bound urls', () {
        expect(
          _decode({'type': 'openUrl', 'url': 'https://claude.ai/new'}),
          const OpenUrlAction(url: Literal('https://claude.ai/new')),
        );
        expect(
          _decode({
            'type': 'openUrl',
            'url': {r'$bind': 'link', 'fallback': 'https://claude.ai/new'},
          }),
          const OpenUrlAction(url: Binding('link', fallback: 'https://claude.ai/new')),
        );
      });

      test('fails without a url', () {
        expect(() => _decode({'type': 'openUrl'}), throwsA(isA<MapperException>()));
      });
    });

    group(RequestAction, () {
      test('decodes with defaults', () {
        expect(
          _decode({'type': 'request', 'endpoint': '/auth/login'}),
          const RequestAction(endpoint: Literal('/auth/login')),
        );
      });

      test('decodes every method', () {
        for (final (name, method) in [
          ('GET', RequestMethod.get),
          ('POST', RequestMethod.post),
          ('PUT', RequestMethod.put),
          ('PATCH', RequestMethod.patch),
          ('DELETE', RequestMethod.delete),
        ]) {
          expect(
            _decode({'type': 'request', 'endpoint': '/x', 'method': name}),
            RequestAction(endpoint: const Literal('/x'), method: Literal(method)),
            reason: name,
          );
        }
      });

      test('parses bindings nested in the body', () {
        expect(
          _decode({
            'type': 'request',
            'endpoint': '/auth/login',
            'body': {
              'email': {r'$bind': 'form.email'},
              'meta': {
                'tags': [
                  'x',
                  {r'$bind': 'tag'},
                ],
              },
            },
          }),
          const RequestAction(
            endpoint: Literal('/auth/login'),
            body: JsonObject({
              'email': JsonBinding(Binding('form.email')),
              'meta': JsonObject({
                'tags': JsonList([JsonLiteral('x'), JsonBinding(Binding('tag'))]),
              }),
            }),
          ),
        );
      });

      test('fails on a malformed binding nested in the body', () {
        expect(
          () => _decode({
            'type': 'request',
            'endpoint': '/x',
            'body': {
              'meta': {
                'email': {r'$bind': 3},
              },
            },
          }),
          throwsA(isA<MapperException>()),
        );
      });

      test('decodes bound fields', () {
        expect(
          _decode({
            'type': 'request',
            'method': {r'$bind': 'method'},
            'endpoint': {r'$bind': 'url'},
            'body': {r'$bind': 'form'},
          }),
          const RequestAction(method: Binding('method'), endpoint: Binding('url'), body: JsonBinding(Binding('form'))),
        );
      });

      test('decodes onError and onComplete in order', () {
        expect(
          _decode({
            'type': 'request',
            'endpoint': '/save',
            'onError': [
              {'type': 'showMessage', 'text': 'Failed'},
              {'type': 'confetti'},
            ],
            'onComplete': [
              {'type': 'updateState', 'path': 'busy', 'value': false},
            ],
          }),
          const RequestAction(
            endpoint: Literal('/save'),
            onError: [
              ShowMessageAction(text: Literal('Failed')),
              UnknownAction(),
            ],
            onComplete: [UpdateStateAction(path: 'busy', value: Literal(false))],
          ),
        );
      });

      test('childActions lists onError and then onComplete', () {
        const action = RequestAction(endpoint: Literal('/save'), onError: [BackAction()], onComplete: [ReloadAction()]);

        expect(action.childActions, const [BackAction(), ReloadAction()]);
      });

      test('fails without an endpoint or with an unknown method', () {
        expect(() => _decode({'type': 'request'}), throwsA(isA<MapperException>()));
        expect(
          () => _decode({'type': 'request', 'endpoint': '/x', 'method': 'TRACE'}),
          throwsA(isA<MapperException>()),
        );
      });

      test('fails when onError or onComplete is not a list', () {
        expect(
          () => _decode({'type': 'request', 'endpoint': '/x', 'onError': 'back'}),
          throwsA(isA<MapperException>()),
        );
        expect(
          () => _decode({'type': 'request', 'endpoint': '/x', 'onComplete': 'back'}),
          throwsA(isA<MapperException>()),
        );
      });
    });

    group(UnknownAction, () {
      test('has no childActions', () {
        expect(const UnknownAction().childActions, isEmpty);
        expect(const BackAction().childActions, isEmpty);
      });

      test('decodes an unknown type', () {
        expect(_decode({'type': 'vibrate', 'pattern': 'short'}), const UnknownAction());
      });

      test('decodes a missing type', () {
        expect(_decode({}), const UnknownAction());
      });

      test('keeps known actions around it in a list', () {
        expect(
          MapperContainer.globals.fromValue<List<GenericAction>>([
            {'type': 'back'},
            {'type': 'confetti'},
            {'type': 'reload'},
          ]),
          const [BackAction(), UnknownAction(), ReloadAction()],
        );
      });
    });

    test('round-trips through toMap', () {
      final actions = <Map<String, Object?>>[
        {'type': 'updateState', 'path': 'count', 'op': 'increment', 'value': 2},
        {
          'type': 'navigate',
          'pageId': 'home',
          'params': {'tab': 'feed'},
          'replace': true,
        },
        {'type': 'back'},
        {
          'type': 'reload',
          'onError': [
            {'type': 'back'},
          ],
          'onComplete': [
            {'type': 'updateState', 'path': 'refreshing', 'op': 'set', 'value': false},
          ],
        },
        {
          'type': 'showMessage',
          'text': {r'$bind': 'message', 'fallback': 'Done'},
        },
        {
          'type': 'request',
          'method': 'PATCH',
          'endpoint': '/todos',
          'body': {
            'title': {r'$bind': 'draft'},
          },
          'onError': [
            {'type': 'showMessage', 'text': 'Failed'},
          ],
          'onComplete': [
            {'type': 'updateState', 'path': 'saving', 'op': 'set', 'value': false},
          ],
        },
      ];

      for (final json in actions) {
        expect(_decode(json).toMap(), json, reason: '${json['type']}');
      }
    });
  });
}
