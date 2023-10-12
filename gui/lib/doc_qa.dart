import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class DocQA extends StatefulWidget {
  const DocQA({super.key});

  @override
  State<DocQA> createState() => _DocQAState();
}

class _DocQAState extends State<DocQA> {
  String filename = '未选择文件';
  TextEditingController question = TextEditingController();
  TextEditingController answer = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文档问答'),
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
                      ElevatedButton(
                        child: const Text('加载模型'),
                        onPressed: () {
                          startLoading(context);
                          http
                              .get(Uri.parse('$apiRoot/doc-qa/load'))
                              .then((response) {
                            stopLoading(context);
                            var msg = response.statusCode == 204
                                ? '加载模型成功'
                                : '加载模型失败';
                            showMsg(context, msg);
                          }).onError((error, stackTrace) {
                            stopLoading(context);
                            showMsg(context, '加载模型失败');
                          });
                        },
                      ),
                      ElevatedButton(
                        child: const Text('卸载模型'),
                        onPressed: () {
                          startLoading(context);
                          http
                              .get(Uri.parse('$apiRoot/doc-qa/unload'))
                              .then((response) {
                            stopLoading(context);
                            var msg = response.statusCode == 204
                                ? '卸载模型成功'
                                : '卸载模型失败';
                            showMsg(context, msg);
                          }).onError((error, stackTrace) {
                            stopLoading(context);
                            showMsg(context, '卸载模型失败');
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OverflowBar(
                    spacing: 10,
                    children: <Widget>[
                      Text(filename),
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
                            setState(() {
                              filename = file.name;
                            });
                            var request = http.MultipartRequest(
                                'POST', Uri.parse('$apiRoot/doc-qa/add-doc'));
                            var multipart = http.MultipartFile.fromBytes(
                                'file', file.bytes!.toList(),
                                filename: file.name);
                            request.files.add(multipart);
                            request.send().then((response) {
                              stopLoading(context);
                              var msg = response.statusCode == 204
                                  ? '上传文件成功'
                                  : '上传文件失败';
                              showMsg(context, msg);
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
                    ],
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
                    controller: answer,
                    maxLines: 10,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('提问'),
                    onPressed: () {
                      startLoading(context);
                      http
                          .post(Uri.parse('$apiRoot/doc-qa/query'),
                              headers: {"content-type": "application/json"},
                              body: json.encode({'q': question.text}))
                          .then((response) {
                        stopLoading(context);
                        if (response.statusCode == 200) {
                          showMsg(context, '调用成功');
                          answer.text = json.decode(response.body)['ans'];
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
