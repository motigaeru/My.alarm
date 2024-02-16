# アラームアプリ

制作期間4ヶ月

## ツールのバージョン
- X Code&emsp;15.0.1
- VS Code&emsp;1.59.1
- Android Studio&emsp;Android Studio 2022.1, build AI-221.6008.13.2211.9619390. Copyright JetBrains s.r.o., (c) 2000-2023

# 作った動機

- すぐにアラームの設定ができるアプリを作って見たかった
- Dart言語の理解の為

# 機能

- アラーム設定機能
- アラーム音を消す機能
- アラームに名前をつける機能
- バイブレーション機能
- スヌーズ機能(５分刻み)
- 鳴る曜日を指定できる機能
- 音量調節機能
- 通知機能（バックグランド）

# 環境構築
- 1 https://docs.flutter.dev/get-started/install （公式サイト）のInstalページでmacOSを選択
- 2 zip ファイルをダウンロードし解凍
- 3 ユーザーフォルダ直下に「development」フォルダを作成し、ダウンロードした「flutter」フォルダを移動
- 4 macのターミナルを開き `export PATH="$PATH:[flutterフォルダが格納されているディレクトリ]/flutter/bin"`を入力
- 5 esc キーを押してINSERTモードを終了し、:WQ と入力しENTERで内容を上書き保存
- 6 ターミナルで `which flutter`を実行する
- 7 Android Studioを入れて設定画面からDartをインストールする
- 8 Android Studio を再起動し、初期画面に「start a new flutter project」があることを確認する
- 9 Xcodeを入れる
- 10 VScodeにflutterとDartのプラグインを入れる
- 11 Shift＋command＋Pを押し、入力欄に`flutter`と入力します。
- 12 `New Project`を押し、`Application`と言う部分を押す
- 13 好きな場所を選択して`Select a folder to create the project in`と言う部分を押します。
- 14 `Project Name`にプロジェクトフォルダの名前を入力します。
- 以下参考にした記事
- https://zenn.dev/kboy/books/ca6a9c93fd23f3/viewer/5232dc
- https://qiita.com/Hershel/items/2c386238d47924a5253a
- https://zenn.dev/lisras/articles/9f4fe12f920e59

# 稼働手順
- X CodeかAndroid Studioを使いシュミレータを開く
- VS CodeやAndroid Studioでcode runする

# 今後の展望
- このアプリをストアにリリースする
- ファイル分割などを利用してコードを見やすくする技術などを磨きたい
- どれくらい自分に課題を抱えているのか把握したい
