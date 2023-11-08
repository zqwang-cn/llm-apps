import 'package:flutter/material.dart';

import 'chat.dart';
import 'doc_qa.dart';
import 'models.dart';
import 'sql_qa.dart';
import 'summarize.dart';

void main() {
  runApp(const MaterialApp(
    title: 'LLM Apps',
    home: Home(),
  ));
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('全部应用'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Models()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('模型管理'),
            )
          ],
        ),
        body: Center(
          child: Wrap(
            children: <Widget>[
              Card(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Column(
                    children: <Widget>[
                      const ListTile(
                        title: Text('聊天机器人'),
                        subtitle: Text('与机器人进行多轮连续对话'),
                        leading: Icon(Icons.album),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Chat()),
                              );
                            },
                            child: const Text('运行'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Column(
                    children: <Widget>[
                      const ListTile(
                        title: Text('文档问答'),
                        subtitle: Text('针对文档内容进行提问'),
                        leading: Icon(Icons.album),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: const Text('运行'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const DocQA()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Column(
                    children: <Widget>[
                      const ListTile(
                        title: Text('文本摘要'),
                        subtitle: Text('将较长文本整理为简短摘要'),
                        leading: Icon(Icons.album),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Summarize()),
                              );
                            },
                            child: const Text('运行'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Column(
                    children: <Widget>[
                      const ListTile(
                        title: Text('数据库问答'),
                        subtitle: Text('使用SQL对关系型数据库内容进行问答'),
                        leading: Icon(Icons.album),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SQLQA()),
                              );
                            },
                            child: const Text('运行'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
