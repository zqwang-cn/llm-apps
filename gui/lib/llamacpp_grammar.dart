import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class LlamacppGrammar extends StatefulWidget {
  const LlamacppGrammar({super.key});

  @override
  State<LlamacppGrammar> createState() => _LlamacppGrammarState();
}

class _LlamacppGrammarState extends State<LlamacppGrammar> {
  String? model;
  TextEditingController text = TextEditingController();
  TextEditingController result = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('格式化输出（LlamaCpp）'),
      ),
      body: Center(
          child: SizedBox(
              width: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DropdownMenu<String>(
                    label: const Text('模型'),
                    onSelected: (value) {
                      model = value;
                    },
                    dropdownMenuEntries: modelInfos.keys
                        .where((name) =>
                            modelInfos[name]['type'] == 'LlamaCpp' &&
                            modelInfos[name].containsKey('kwargs') &&
                            modelInfos[name]['kwargs']
                                .containsKey('grammar_path') &&
                            modelInfos[name]['status'] == 'loaded')
                        .map((name) =>
                            DropdownMenuEntry<String>(label: name, value: name))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '输入',
                      border: OutlineInputBorder(),
                    ),
                    controller: text,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '输出',
                      border: OutlineInputBorder(),
                    ),
                    controller: result,
                    maxLines: 10,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('生成'),
                    onPressed: () {
                      if (model == null) {
                        showMsg(context, '请选择模型');
                        return;
                      }
                      if (text.text == '') {
                        showMsg(context, '输入不能为空');
                        return;
                      }

                      startLoading(context);
                      http
                          .post(
                        Uri.parse('$apiRoot/llamacpp-grammar/generate'),
                        headers: {'content-type': 'application/json'},
                        body: json.encode(
                          {'model_name': model, 'text': text.text},
                        ),
                      )
                          .then((response) {
                        stopLoading(context);
                        if (response.statusCode == 200) {
                          JsonEncoder encoder =
                              const JsonEncoder.withIndent('    ');
                          result.text = encoder
                              .convert(json.decode(response.body)['result']);
                          showMsg(context, '生成成功');
                        } else {
                          showMsg(context, '生成失败');
                        }
                      }).onError((error, stackTrace) {
                        stopLoading(context);
                        showMsg(context, '生成失败');
                      });
                    },
                  ),
                ],
              ))),
    );
  }
}
