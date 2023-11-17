import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

var engineUrlBases = {
  'bing': 'https://www.bing.com/search?q=',
  'google': 'https://www.google.com/search?q='
};

class WebRequest extends StatefulWidget {
  const WebRequest({super.key});

  @override
  State<WebRequest> createState() => _WebRequestState();
}

class _WebRequestState extends State<WebRequest> {
  String? model;
  TextEditingController query = TextEditingController();
  TextEditingController url = TextEditingController();
  String engine = engineUrlBases.keys.first;
  TextEditingController result = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络问答'),
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
                            modelInfos[name]
                                .containsKey('web_request_template') &&
                            modelInfos[name]['status'] == 'loaded')
                        .map((name) =>
                            DropdownMenuEntry<String>(label: name, value: name))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '问题',
                      border: OutlineInputBorder(),
                    ),
                    controller: query,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                    ),
                    controller: url,
                  ),
                  const SizedBox(height: 20),
                  OverflowBar(
                    spacing: 10,
                    children: <Widget>[
                      DropdownMenu<String>(
                        label: const Text('搜索引擎'),
                        onSelected: (value) {
                          engine = value!;
                        },
                        initialSelection: engineUrlBases.keys.first,
                        dropdownMenuEntries: engineUrlBases.keys
                            .map((value) => DropdownMenuEntry<String>(
                                label: value, value: value))
                            .toList(),
                      ),
                      ElevatedButton(
                          child: const Text('生成URL'),
                          onPressed: () {
                            url.text = Uri.encodeFull(
                                '${engineUrlBases[engine]}${query.text}');
                          }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '回答',
                      border: OutlineInputBorder(),
                    ),
                    controller: result,
                    maxLines: 10,
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
                      if (query.text == '') {
                        showMsg(context, '问题不能为空');
                        return;
                      }
                      if (url.text == '') {
                        showMsg(context, 'URL不能为空');
                        return;
                      }

                      startLoading(context);
                      http
                          .post(
                        Uri.parse('$apiRoot/web-request/query'),
                        headers: {'content-type': 'application/json'},
                        body: json.encode(
                          {
                            'model_name': model,
                            'query': query.text,
                            'url': url.text
                          },
                        ),
                      )
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
