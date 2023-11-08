import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class SQLQA extends StatefulWidget {
  const SQLQA({super.key});

  @override
  State<SQLQA> createState() => _SQLQAState();
}

class _SQLQAState extends State<SQLQA> {
  String? model;
  String type = 'sql';
  TextEditingController uri = TextEditingController();
  TextEditingController question = TextEditingController();
  TextEditingController result = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库问答'),
      ),
      body: Center(
          child: SizedBox(
              width: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OverflowBar(
                    spacing: 10,
                    children: <Widget>[
                      DropdownMenu<String>(
                        label: const Text('模型'),
                        onSelected: (value) {
                          model = value;
                        },
                        dropdownMenuEntries: modelInfos.keys
                            .where((name) =>
                                modelInfos[name]['status'] == 'loaded')
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                              value: value, label: value);
                        }).toList(),
                      ),
                      DropdownMenu<String>(
                        label: const Text('问答类型'),
                        initialSelection: 'sql',
                        onSelected: (value) {
                          type = value!;
                        },
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(label: '仅生成SQL语句', value: 'sql'),
                          DropdownMenuEntry(label: '生成完整回答', value: 'answer'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                      '请输入数据库URI，或上传数据库文件\n（支持.sql, .db, .sqlite, .sqlite3格式文件上传）'),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '数据库URI',
                      border: OutlineInputBorder(),
                    ),
                    controller: uri,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    child: const Text('选择文件并上传'),
                    onPressed: () {
                      startLoading(context);
                      FilePicker.platform.pickFiles().then((result) {
                        if (result == null) {
                          stopLoading(context);
                          return;
                        }
                        var file = result.files.single;
                        var request = http.MultipartRequest(
                            'POST', Uri.parse('$apiRoot/sql-qa/upload'));
                        var multipart = http.MultipartFile.fromBytes(
                            'file', file.bytes!.toList(),
                            filename: file.name);
                        request.files.add(multipart);
                        request.send().then((response) {
                          if (response.statusCode == 200) {
                            response.stream
                                .toStringStream()
                                .join()
                                .then((value) {
                              uri.text = json.decode(value)['uri'];
                              stopLoading(context);
                              showMsg(context, '上传文件成功');
                            }).onError((error, stackTrace) {
                              stopLoading(context);
                              showMsg(context, '上传文件失败');
                            });
                          } else {
                            stopLoading(context);
                            showMsg(context, '上传文件失败');
                          }
                        }).onError((error, stackTrace) {
                          stopLoading(context);
                          showMsg(context, '上传文件失败');
                        });
                      }).onError((error, stackTrace) {
                        stopLoading(context);
                        showMsg(context, '选择文件失败');
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '问题',
                      border: OutlineInputBorder(),
                    ),
                    controller: question,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '回答',
                      border: OutlineInputBorder(),
                    ),
                    controller: result,
                    maxLines: 3,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('提问'),
                    onPressed: () {
                      if (model == null) {
                        showMsg(context, '请选择模型');
                        return;
                      }
                      if (uri.text == '') {
                        showMsg(context, '请输入数据库URI或上传数据库文件');
                        return;
                      }
                      if (question.text == '') {
                        showMsg(context, '请输入问题');
                        return;
                      }

                      startLoading(context);
                      http
                          .post(Uri.parse('$apiRoot/sql-qa/query'),
                              headers: {"content-type": "application/json"},
                              body: json.encode({
                                'model_name': model,
                                'type': type,
                                'uri': uri.text,
                                'question': question.text
                              }))
                          .then((response) {
                        stopLoading(context);
                        if (response.statusCode == 200) {
                          result.text = json.decode(response.body)['result'];
                          showMsg(context, '调用成功');
                        } else {
                          showMsg(context, '调用失败');
                        }
                      }).onError((error, stackTrace) {
                        stopLoading(context);
                        showMsg(context, '调用失败');
                      });
                    },
                  ),
                ],
              ))),
    );
  }
}
