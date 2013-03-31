# -*- coding: utf-8 -*-

require 'gtk2'
require "gcalapi"
require "yaml"
require 'pp'

#カレンダーを所有しているアカウントと別のアカウントでも、private adress が合っていれば読み込めるらしい。

account = []
feed = []
$stag = []
writefeed = []
$task = []
$task_time = []
t = Time.now

File.open("private_data.yaml") do |f|
  YAML.load_documents(f) do |data|
    data.each do |key, value|
      case key
      when "account"
        account = value
      when "feed"
        feed = value
      when "tag"
        $tag = value
      when "writefeed"
        writefeed = value
      when "task"
        $task = value
      end
    end
  end
end

File.open("time") do |f|
  begin
    $task_time = f.gets.chomp.split(/,/)
  rescue
  end
end

if $task_time[0] == t.strftime("%d")
  $d_fg = 0
else
  $d_fg = 1
end

srv = GoogleCalendar::Service.new(account["mail"], account["pass"])
cal = GoogleCalendar::Calendar.new( srv, writefeed)


def save_event(cal, title, where, body, stime, etime, allday)
  event = cal.create_event
  event.title = title
  event.where = where
  event.desc = body
  event.st = stime
  event.en = etime
  event.allday = allday
  event.save!
end

def fecth_gcal(srv, feed, target_day, textview)
  texts = []
  for i in 0..feed.size-1
    cal = GoogleCalendar::Calendar::new(srv, feed[i]["url"])

    #「:q => 'Thanksgiving'」はok (thanksだけだとダメなので1単語単位なんだろう
    #「:'published-min' => '2013-01-09Z10:57:00-08:00'」はエラーがでる(GoogleCalendar::InvalidCalendarURL) start-min,maxなどもダメ
    #クエリを並べるときはカンマで区切る
    #日付などでフィルターをかけれればいいができなさそうなので、多めにイベントを取得してその後手動で振り分ける。デフォルトは更新日の新しいイベントから取得される。
    events = cal.events(:'max-results' => 20)

    d = Time.parse(target_day)
    d_re = target_day
    d_formatted = d.strftime("%Y-%m-%d %a")
    d_formatted2 = d.strftime("%Y-%m-%d %A")
    titles = []
    dates_and_times = []
    wheres = []
    bodys = []
    times = []
    tags = []

    events.each do |event|
      str =  event.desc
      k = ""
      if /(開始日|期間):\s#{d_re}/ =~ str
        if event.title
          if /(.+)(\s:)([a-z]+)$/ =~ event.title
            $3.each_char do |c|
              if $tag.has_key?(c)
                k << $tag[c]
              end
            end
            titles << "**** " + $1
            tags << "     " + k.squeeze
          else
            titles << "**** " + event.title
            tags << nil
          end
        else
          titles << "**** no title"
          tags << nil
        end
        if /(\d\d:\d\d)(～)(\d\d:\d\d)/ =~ str
          dates_and_times << " <#{d_formatted} #{$1}-#{$3}>"
          times << $1
        else
          dates_and_times << " <#{d_formatted}>"
          times << "00:00"
        end
        if /場所:\s(.+)/ =~ str    #最初に一度マッチしたら「\n」までしか探さないらしい。 /場所:\s(.+)/\n<br \/>/とすると何もマッチしない。
          wheres << " (" + $1 + ")"
        else
          wheres << ""
        end
        if /説明:\s/ =~ str
          bodys << "\n" + $' + "\n"
        else
          bodys << nil
        end
      else
        caution = "no event"
      end
    end

    #p titles
    #p wheres
    #p bodys
    #p dates_and_times
    #text = []

    for j in 0..titles.size-1
      text = [times[j], titles[j], wheres[j], dates_and_times[j], tags[j], bodys[j]]
      texts << text
    end

  end

  texts.sort!{|a, b| a[0] <=> b[0] }  #多重配列のソートは1つ目の要素が使われるので「sort」だけでも良いが、その場合だとtexts内にnilが含まれているのでエラーが出る

  to_emacs = "*** #{d_formatted2}\n"
  texts.each do |text|
    to_emacs << "#{text[1]}#{text[2]}#{text[3]}#{text[4]}#{text[5]}\n#{text[6]}"
  end
  to_emacs.gsub!(/&quot;/, "\"")
  to_emacs.gsub!(/&amp;/, "&")
  to_emacs.gsub!(/&#39;/, "\'")
  to_emacs.gsub!(/&gt;/, "\>")
  to_emacs.gsub!(/&lt;/, "\<")
  textview.buffer.text = to_emacs
end



#######################
#### make container
#######################

window = Gtk::Window.new
window.border_width = 10
window.resizable = true
#window.set_size_request(800, 500)
window.title = "Hige-Task-Helper"
hpane = Gtk::HBox.new(false, 0)
window.add(hpane)


#### left pane
pane = Gtk::VBox.new(false, 0)
hpane.pack_start(pane, false, false, 20)

# task
$undone = '<span foreground="red" background="lightpink" weight="bold">oh...(ﾉд-。)</span>'
$done = '<span foreground="blue" weight="bold">done!!ヽ(o￣∇￣o)ノ</span>'
def change_label(event, label)
  if event.event_type == Gdk::Event::BUTTON2_PRESS
    if label.name == "0"
      label.markup = $done
      label.name = "1"
    else
      label.markup = $undone
      label.name = "0"
    end
  end
end

  hbox = Gtk::HBox.new(true, 0)
  pane.pack_start(hbox, false, false, 0)
  tasktop1 = Gtk::Label.new
  tasktop1.text = "When done, double-click"
  tasktop2 = Gtk::Label.new
  tasktop2.text = "Things To Do"
  hbox.pack_start(tasktop1, true, true, 0)
  hbox.pack_start(tasktop2, true, true, 0)
  separator = Gtk::HSeparator.new
  pane.pack_start(separator, false, true, 5)

=begin
hbox1 = Gtk::HBox.new(true, 0)
pane.pack_start(hbox1, false, false, 0)
eventbox = Gtk::EventBox.new
label11 = Gtk::Label.new
label11.name = "0"
if $task_time[1] == "1"
  label11.name = "1"
  label11.markup =  '<span foreground="blue" weight="bold">'+ $done + '</span>'
else
  label11.markup = $undone
end
eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
eventbox.add(label11)
button1 = Gtk::Button.new
button1.label = "aaa"
hbox1.pack_start(eventbox, true, true, 0)
hbox1.pack_start(button1, true, true, 0)
=end

def make_task(vbox, i)
  separator = Gtk::HSeparator.new
  vbox.pack_start(separator, false, true, 5)
  hbox = Gtk::HBox.new(true, 0)
  vbox.pack_start(hbox, false, false, 0)
  label = eval("$tasklabel#{i} = Gtk::Label.new")
  if $d_fg == 0
    if $task_time[i+1]
      label.name = $task_time[i+1]
    end
  else
    label.name = "0"
  end
  if label.name == "1"
    label.markup = $done
  else
    label.markup = $undone
  end
  eventbox = eval("$eventbox#{i} = Gtk::EventBox.new")
  eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
  eventbox.add(label)
  button = eval("$taskbutton#{i} = Gtk::Button.new")
  button.label = $task[i]['buttonname']
  hbox.pack_start(eventbox, true, true, 0)
  hbox.pack_start(button, true, true, 0)
  ### You need to call {{ realize }} only after you add it to the
  ### top (including) widget.
  eventbox.realize
  eventbox.window.cursor = Gdk::Cursor.new(Gdk::Cursor::HAND1)
  eventbox.signal_connect('button_press_event') do |w, e|
    change_label(e, eventbox.children[0])
  end
end

for i in 0..$task.size-1
  make_task(pane, i)
end
#  pane.each {|child| p child }

  memo = Gtk::Label.new
  memo.text = 'tag:
  b: ":book:"
  c: ":car:"
  e: ":event:"
  f: ":finance:"
  h: ":health:"
  s: ":house:"
  m: ":important:"
  i: ":insurance:"
  k: ":knowledge:"
  p: ":purchase:"
  t: ":tech:"
'
  pane.pack_start(memo, true, true, 0)


#### right pane
pane = Gtk::VBox.new(false, 0)
hpane.pack_start(pane, false, false, 0)

# title
title_label= Gtk::Label.new("title", false)
title_entry = Gtk::Entry.new

pane.pack_start(title_label, false, false, 0)
pane.pack_start(title_entry, false, false, 0)

# where
where_label= Gtk::Label.new("where", false)
where_entry = Gtk::Entry.new

pane.pack_start(where_label, false, false, 0)
pane.pack_start(where_entry, false, false, 0)

## date
vbox = Gtk::VBox.new(false, 0)
vbox.border_width = 5
pane.pack_start(vbox, false, false, 0)

hbox = Gtk::HBox.new(false, 0)
vbox.pack_start(hbox, false, false, 5)

vbox2 = Gtk::VBox.new(false, 0)
hbox.pack_start(vbox2, false, false, 0)
label0 =  Gtk::Label.new("Start :")
label0.set_size_request(80, 50)
label0.set_alignment(0.5, 0.7)
label1 =  Gtk::Label.new("End :")
vbox2.pack_start(label0, false, false, 0)
vbox2.pack_start(label1, false, false, 0)

def make_date_container(hbox, name, digit, pretext)
vbox = Gtk::VBox.new(false, 0)
  hbox.pack_start(vbox, false, false, 5)

  label =  Gtk::Label.new(name)
  vbox.pack_start(label, false, false, 0)
  2.times do |i|
    entry =  eval("$#{name}_entry#{i} = Gtk::Entry.new")   #変数に変数を入れる
    entry.set_size_request(50, 27)
    entry.max_length = digit
    entry.text = "#{pretext}"
    vbox.pack_start(entry, false, false, 0)
  end
end

make_date_container(hbox, "year", 4, t.strftime("%Y"))
make_date_container(hbox, "month", 2, t.strftime("%m"))
make_date_container(hbox, "day", 2, t.strftime("%d"))
make_date_container(hbox, "time", 4, t.strftime("%H%M"))


check = Gtk::CheckButton.new("All day")    #all day check
check.set_size_request(140, 70)
#check.set_alignment(1, 1)
hbox.pack_start(check, false, false, 0)

# text area
textview = Gtk::TextView.new
scrolled_win = Gtk::ScrolledWindow.new
scrolled_win.border_width = 5
scrolled_win.add(textview)
scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
scrolled_win.set_size_request(550, 400)
pane.pack_start(scrolled_win, false, false, 5)

#submit button
hbox = Gtk::HBox.new(true, 0)
pane.pack_start(hbox, false, false, 5)
button_c = Gtk::Button.new("to Google Calendar♪")
button_e = Gtk::Button.new("to Diario♪")
#apply  = Gtk::Button.new(Gtk::Stock::CLOSE) ==> not show icon

hbox.pack_start(button_c, true, true, 0)
hbox.pack_start(button_e, true, true, 0)



####イベント

#日付を変えた時
$year_entry0.signal_connect("changed") do
  $year_entry1.text =  $year_entry0.text
end
$month_entry0.signal_connect("changed") do
  $month_entry1.text =  $month_entry0.text
end
$day_entry0.signal_connect("changed") do
  $day_entry1.text =  $day_entry0.text
end
$time_entry0.signal_connect("changed") do
  $time_entry1.text =  $time_entry0.text
end

# "Edit past Event"ボタンを押した時
$taskbutton0.signal_connect("clicked") do |w|
  day = $year_entry0.text + "/" + $month_entry0.text + "/" + $day_entry0.text
  fecth_gcal(srv, feed, day, textview)
end

#1つ目以外のtaskボタンを押した時
for i in 1..$task.size-1
  b = eval("$taskbutton#{i}")
  b.signal_connect("clicked") do |w|
    title_entry.text = w.label
  end
end

# to Google Calendar のボタンを押した時
def error_dialog (parent)
  dialog = Gtk::Dialog.new(
      "Information",
      parent,
      Gtk::Dialog::MODAL,
      [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK ]
  )
  dialog.has_separator = false
  label = Gtk::Label.new("Date is not validated!")
  image = Gtk::Image.new(Gtk::Stock::DIALOG_INFO, Gtk::IconSize::DIALOG)

  hbox = Gtk::HBox.new(false, 5)
  hbox.border_width = 10
  hbox.pack_start_defaults(image);
  hbox.pack_start_defaults(label);

  # Add the message in a label, and show everything we've added to the dialog.
  # dialog.vbox.pack_start_defaults(hbox) # Also works, however dialog.vbox
                                          # limits a single item (element).
  dialog.vbox.add(hbox)
  dialog.show_all
  dialog.run
  dialog.destroy
end

button_c.signal_connect("clicked"){
  title =  title_entry.text
  where =  where_entry.text
  body = textview.buffer.text
  /(\d\d)(\d\d)/ =~ $time_entry0.text
  stime = Time.mktime($year_entry0.text, $month_entry0.text, $day_entry0.text, $1, $2)
  /(\d\d)(\d\d)/ =~ $time_entry1.text
  etime = Time.mktime($year_entry1.text, $month_entry1.text, $day_entry1.text, $1, $2)
  if stime > etime
    error_dialog(window)
  end
  allday = check.active?
  save_event(cal, title, where, body, stime, etime, allday)
}


window.signal_connect("delete_event") do
  File.open("time", "w") do |f|
    d = t.strftime("%d")
    for i in 0..$task.size-1
      eb = eval("$eventbox#{i}")
      d << "," + eb.children[0].name
    end
    f.write d
  end
  Gtk::main_quit
end


window.show_all
Gtk.main



