import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'utils.dart';

class Models extends StatefulWidget {
  const Models({super.key});

  @override
  State<Models> createState() => _ModelsState();
}

class _ModelsState extends State<Models> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startLoading(context);
      http.get(Uri.parse('$apiRoot/models')).then((result) {
        if (result.statusCode == 200) {
          setState(() {
            modelInfos = json.decode(result.body);
          });
          stopLoading(context);
          showMsg(context, '获取模型列表成功');
        } else {
          stopLoading(context);
          showMsg(context, '获取模型列表失败');
        }
      }).onError((error, stackTrace) {
        stopLoading(context);
        showMsg(context, '获取模型列表失败');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('模型管理'),
        ),
        body: Center(
            child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: const <TableRow>[
                TableRow(children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('名称'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('类型'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text('状态'),
                  ),
                  Text(''),
                  Text('')
                ])
              ] +
              modelInfos.entries
                  .map<TableRow>((e) => TableRow(children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(e.key),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(e.value['type']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(e.value['status']),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: ElevatedButton(
                            child: const Text('加载'),
                            onPressed: () {
                              if (e.value['status'] != 'loaded') {
                                startLoading(context);
                                http
                                    .get(Uri.parse(
                                        '$apiRoot/models/${e.key}/load'))
                                    .then((result) {
                                  if (result.statusCode == 204) {
                                    setState(() {
                                      modelInfos[e.key]['status'] = 'loaded';
                                    });
                                    stopLoading(context);
                                    showMsg(context, '加载模型成功');
                                  } else {
                                    stopLoading(context);
                                    showMsg(context, '加载模型失败');
                                  }
                                }).onError((error, stackTrace) {
                                  stopLoading(context);
                                  showMsg(context, '加载模型失败');
                                });
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: ElevatedButton(
                            child: const Text('卸载'),
                            onPressed: () {
                              if (e.value['status'] != 'unloaded') {
                                startLoading(context);
                                http
                                    .get(Uri.parse(
                                        '$apiRoot/models/${e.key}/unload'))
                                    .then((result) {
                                  if (result.statusCode == 204) {
                                    setState(() {
                                      modelInfos[e.key]['status'] = 'unloaded';
                                    });
                                    stopLoading(context);
                                    showMsg(context, '卸载模型成功');
                                  } else {
                                    stopLoading(context);
                                    showMsg(context, '卸载模型失败');
                                  }
                                }).onError((error, stackTrace) {
                                  stopLoading(context);
                                  showMsg(context, '卸载模型失败');
                                });
                              }
                            },
                          ),
                        )
                      ]))
                  .toList(),
        )));
  }
}
