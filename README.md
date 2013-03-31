Hige Task Helper
-----------
###動機
  1. 日記・予定・タスクを管理するために、Google Calendarとorg-mode(on Emacs)の両方を使用。
  2. データを一つにまとめたいが、Google Calendarは登録したデータはネット上にあるのみ。
  3. なんとかしてGoogle Calendarからデータをテキストとして取得して、org-mode用に整形できないか。
  
###このアプリでできること
  - Google Calendarに登録されたカレンダー（複数あってもOK）から指定された日のイベントをすべて取り出し、org-modeで見やすいように時刻やタグをつけて整形。ウィンドウで確認後、データをorgファイルに追記させる。
  - Google Calendarからイベントを取り出せるならイベントの登録もできるので、ついでに、毎日のように繰り返すイベントを定型文にして、簡単操作で登録できるようにした。
  - もう一つついでに、毎日やらなきゃいけないタスクは、やったかどうかひと目でわかるようにした。
  
###使い方
  - sample_private_data.yamlの中身を適当に書き換えてprivate_data.yamlに名前を変更する
  
  ###これからの予定
  -　とりあえず大まかには動いたので、これから細部を作っていく