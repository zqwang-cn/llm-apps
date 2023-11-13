import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class Jsonformer extends StatefulWidget {
  const Jsonformer({super.key});

  @override
  State<Jsonformer> createState() => _JsonformerState();
}

class _JsonformerState extends State<Jsonformer> {
  String? model;
  TextEditingController schema = TextEditingController();
  TextEditingController prompt = TextEditingController();
  TextEditingController result = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('格式化输出（Jsonformer）'),
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
                            modelInfos[name]['type'] == 'HuggingFacePipeline' &&
                            modelInfos[name]['status'] == 'loaded')
                        .map((name) =>
                            DropdownMenuEntry<String>(label: name, value: name))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Schema',
                      border: OutlineInputBorder(),
                    ),
                    controller: schema,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '输入',
                      border: OutlineInputBorder(),
                    ),
                    controller: prompt,
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
                      if (schema.text == '') {
                        showMsg(context, 'Schema不能为空');
                        return;
                      }
                      if (prompt.text == '') {
                        showMsg(context, '输入不能为空');
                        return;
                      }
                      dynamic jsonSchema;
                      try {
                        jsonSchema = json.decode(schema.text);
                        if (jsonSchema is! Map) {
                          throw const FormatException();
                        }
                      } catch (_) {
                        showMsg(context, 'Schema应为JSON格式');
                        return;
                      }

                      startLoading(context);
                      http
                          .post(
                        Uri.parse('$apiRoot/jsonformer/generate'),
                        headers: {'content-type': 'application/json'},
                        body: json.encode(
                          {
                            'model_name': model,
                            'json_schema': jsonSchema,
                            'prompt': prompt.text
                          },
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
