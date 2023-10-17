import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  TextEditingController model = TextEditingController();
  List<Map<String, String>> dialog = [];
  ScrollController scroll = ScrollController();
  TextEditingController input = TextEditingController();
  bool enabled = true;
  FocusNode focus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('聊天机器人'),
        ),
        body: Center(
            child: SizedBox(
                width: 500,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      DropdownMenu<String>(
                        label: const Text('模型'),
                        initialSelection:
                            modelInfos.isEmpty ? null : modelInfos.keys.first,
                        controller: model,
                        dropdownMenuEntries: modelInfos.keys
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                              value: value, label: value);
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        height: 500,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                        ),
                        child: ListView.separated(
                          controller: scroll,
                          itemCount: dialog.length,
                          itemBuilder: (BuildContext context, int index) =>
                              Padding(
                            padding: dialog[index]['role'] == 'user'
                                ? const EdgeInsets.only(right: 50)
                                : const EdgeInsets.only(left: 50),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: dialog[index]['role'] == 'user'
                                    ? Colors.green
                                    : Colors.blue,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Text(dialog[index]['content']!),
                            ),
                          ),
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 20),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: input,
                        focusNode: focus,
                        decoration: InputDecoration(
                          labelText: '请输入',
                          border: const OutlineInputBorder(),
                          enabled: enabled,
                        ),
                        onSubmitted: (text) {
                          if (text == '') {
                            showMsg(context, '输入不能为空');
                            focus.requestFocus();
                          } else {
                            setState(() {
                              enabled = false;
                              dialog.add({'role': 'user', 'content': text});
                              input.text = '';
                            });
                            Future.delayed(const Duration(milliseconds: 200),
                                () {
                              scroll.jumpTo(scroll.position.maxScrollExtent);
                            });
                            http
                                .post(
                              Uri.parse('$apiRoot/chat/chat'),
                              headers: {"content-type": "application/json"},
                              body: json.encode(
                                {'model_name': model.text, 'dialog': dialog},
                              ),
                            )
                                .then((result) {
                              if (result.statusCode == 200) {
                                setState(() {
                                  dialog.add({
                                    'role': 'ai',
                                    'content':
                                        json.decode(result.body)['result']
                                  });
                                  enabled = true;
                                });
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
                                  scroll
                                      .jumpTo(scroll.position.maxScrollExtent);
                                  focus.requestFocus();
                                });
                              } else {
                                setState(() {
                                  dialog.add(
                                      {'role': 'ai', 'content': '调用失败，请刷新后重试'});
                                });
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
                                  scroll
                                      .jumpTo(scroll.position.maxScrollExtent);
                                });
                              }
                            }).onError((error, stackTrace) {
                              setState(() {
                                dialog.add(
                                    {'role': 'ai', 'content': '调用失败，请刷新后重试'});
                              });
                              Future.delayed(const Duration(milliseconds: 200),
                                  () {
                                scroll.jumpTo(scroll.position.maxScrollExtent);
                              });
                            });
                          }
                        },
                      ),
                    ]))));
  }
}
