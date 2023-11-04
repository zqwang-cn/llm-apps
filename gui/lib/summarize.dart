import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class Summarize extends StatefulWidget {
  const Summarize({super.key});

  @override
  State<Summarize> createState() => _SummarizeState();
}

class _SummarizeState extends State<Summarize> {
  TextEditingController model = TextEditingController();
  TextEditingController type = TextEditingController();
  PlatformFile? file;
  TextEditingController summary = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文本摘要'),
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
                        controller: model,
                        dropdownMenuEntries: modelInfos.keys
                            .where((name) =>
                                modelInfos[name]
                                    .containsKey('summarize_templates') &&
                                modelInfos[name]['status'] == 'loaded')
                            .map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(
                              value: value, label: value);
                        }).toList(),
                      ),
                      DropdownMenu<String>(
                        label: const Text('prompt类型'),
                        initialSelection: 'stuff',
                        controller: type,
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(label: 'stuff', value: 'stuff'),
                          DropdownMenuEntry(
                              label: 'map_reduce', value: 'map_reduce'),
                          DropdownMenuEntry(label: 'refine', value: 'refine'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OverflowBar(
                    spacing: 10,
                    children: <Widget>[
                      Text(file == null ? '未选择文件' : file!.name),
                      ElevatedButton(
                        child: const Text('选择文件'),
                        onPressed: () {
                          startLoading(context);
                          FilePicker.platform.pickFiles().then((result) {
                            if (result != null) {
                              setState(() {
                                file = result.files.single;
                              });
                            }
                            stopLoading(context);
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
                      labelText: '摘要',
                      border: OutlineInputBorder(),
                    ),
                    controller: summary,
                    maxLines: 10,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text('生成'),
                    onPressed: () {
                      if (model.text == '') {
                        showMsg(context, '请选择模型');
                        return;
                      }
                      if (file == null) {
                        showMsg(context, '请选择文件');
                        return;
                      }

                      startLoading(context);
                      var request = http.MultipartRequest(
                          'POST', Uri.parse('$apiRoot/summarize/summarize'));
                      request.fields['model_name'] = model.text;
                      request.fields['type'] = type.text;
                      var multipart = http.MultipartFile.fromBytes(
                          'file', file!.bytes!.toList(),
                          filename: file!.name);
                      request.files.add(multipart);
                      request.send().then((response) {
                        if (response.statusCode == 200) {
                          response.stream.toStringStream().join().then((value) {
                            summary.text = json.decode(value)['summary'];
                            stopLoading(context);
                            showMsg(context, '生成成功');
                          }).onError((error, stackTrace) {
                            stopLoading(context);
                            showMsg(context, '生成失败');
                          });
                        } else {
                          stopLoading(context);
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
