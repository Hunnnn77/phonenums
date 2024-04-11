import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();

  static RegExp validNumWithCode = RegExp(r'^\+84[35789][0-9]{8}$');
  static RegExp plainNumCode = RegExp(r'^(0[35789][0-9]{8})$');
  static RegExp subString = RegExp(r'\b(0[35789][0-9]{8})\b');
  static RegExp excludeAny = RegExp(r'^[0-9]+$');
}

class _HomeState extends State<Home> {
  bool _permissionDenied = false;
  late TextEditingController _controller;
  Set<String> nums = {};

  @override
  void initState() {
    _controller = TextEditingController();
    String l = '';

    void pushing(String line) {
      if (Home.validNumWithCode.hasMatch(line)) {
        nums.add(line);
      }
    }

    _controller.addListener(() {
      final matches = Home.subString.allMatches(_controller.text);
      for (final m in matches) {
        l = m.group(0)!;
        if (l.isEmpty || !Home.plainNumCode.hasMatch(l)) {
          continue;
        }

        l = l.substring(0, 10);

        if (l[0] == '0') {
          if (Home.plainNumCode.hasMatch(l)) {
            l = '+84${l.substring(1)}';
          }
        }

        pushing(l);
      }
    });

    _fetchContacts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          body: View(
            controller: _controller,
            nums: nums,
            permissionDenied: _permissionDenied,
          ),
        ),
      );

  Future _fetchContacts() async {
    final PermissionStatus permissionStatus =
        await Permission.contacts.request();

    if (permissionStatus.isGranted) {
      try {
        if (!await FlutterContacts.requestPermission(readonly: true)) {
          setState(() => _permissionDenied = true);
        }
      } catch (e) {
        rethrow;
      }
    }
  }
}

class View extends StatefulWidget {
  const View({
    required TextEditingController controller,
    required this.nums,
    required bool permissionDenied,
    super.key,
  })  : _controller = controller,
        _permissionDenied = permissionDenied;

  final TextEditingController _controller;
  final bool _permissionDenied;

  final Set<String> nums;

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  @override
  Widget build(BuildContext context) => ListView(
        children: [
          Column(
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Container(
                    color: Colors.yellow,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: switch (widget.nums.isEmpty) {
                        true => const SizedBox(
                            height: 48,
                          ),
                        _ => SizedBox(
                            height: 48,
                            child: Row(
                              children: [
                                for (var n in widget.nums.toList())
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('$n '),
                                  ),
                              ],
                            ),
                          )
                      },
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: TextField(
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    controller: widget._controller,
                    decoration: InputDecoration(
                      filled: true,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {
                        if (text.isEmpty) {
                          widget._controller.text = '';
                          widget.nums.clear();
                        }
                      });
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (!widget._permissionDenied) {
                        final cs = widget.nums.indexed.map(
                          (e) => Contact()
                            ..name.first =
                                '${DateTime.now().toString().split(' ')[1].split('.')[0]}${e.$1}'
                            ..phones = [Phone(e.$2)],
                        );
                        for (final c in cs) {
                          await c.insert();
                        }
                      }
                    },
                    child: Text('save'.toUpperCase()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      widget._controller.text = '';
                      widget.nums.clear();
                    },
                    child: Text('clean'.toUpperCase()),
                  )
                ],
              ),
            ],
          ),
        ],
      );
}
