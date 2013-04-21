# -*- coding: utf-8 -*-

class YamlData
  attr_reader :account, :feed, :tag, :writefeed, :task, :exportfile, :buttonlabel
  def initialize(file)
    @file = file
  end
  def split_data()
    File.open(@file) do |f|
      YAML.load_documents(f) do |data|
        data.each do |k, v|
          instance_variable_set("@#{k}", v)
        end
      end
    end
  end
end

class ClickButtonAndToggleLabel
  def initialize(taskname, window)
    @taskname = taskname
    @window = window
  end
  def make_taskbox(taskdetail)
    hbox = Gtk::HBox.new(true, 0)
    button = Gtk::Button.new(@taskname)
    tooltips = Gtk::Tooltips.new
    tooltips.set_tip(button, "Open edit-screen", nil)
    hbox.pack_start(button, true, true, 5)
    button.signal_connect('clicked') do
      dialog = EditScreen.new(@window)
      dialog.taskbutton_clicked(taskdetail)
    end
    eventbox = ClickButtonAndToggleLabel.make_labelbox
    hbox.pack_start(eventbox, true, true, 5)
    return hbox, eventbox
  end
  def make_pasteventbox()
    vbox = Gtk::VBox.new(false, 0)
    date = DateTable.new
    hbox, dateeventbox = date.make_table
    vbox.pack_start(hbox, true, true, 5)
    hbox = Gtk::HBox.new(true, 0)
    button = Gtk::Button.new(@taskname)
    tooltips = Gtk::Tooltips.new
    tooltips.set_tip(button, "Get events on the day above from Google Calendar.", nil)
    hbox.pack_start(button, true, true, 5)
    button.signal_connect('clicked') do
      dialog = EditScreen.new(@window)
      dialog.pasteventbutton_clicked(dateeventbox)
    end
    eventbox = ClickButtonAndToggleLabel.make_labelbox
    hbox.pack_start(eventbox, true, true, 5)
    vbox.pack_start(hbox, true, true, 5)
    return vbox, eventbox
  end
  def self.make_labelbox()
    label = Gtk::Label.new
    tooltips = Gtk::Tooltips.new
    tooltips.set_tip(label, "Double-click to toggle", nil)
    eventbox = Gtk::EventBox.new
    eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
    eventbox.add(label)
    return eventbox
  end
end

class EditScreen
  def initialize(window)
    @window = window
  end
  def taskbutton_clicked(taskdetail)
    dialog = Gtk::Dialog.new(
                             "Information",
                             @window,
                             Gtk::Dialog::MODAL,
                             [ "Google Calendarに追加", Gtk::Dialog::RESPONSE_OK ], [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
                             )
    dialog.has_separator = true
    dialog.border_width = 10

    entrybox = Gtk::VBox.new(false, 10)
    titlebox, titleentry = EditScreen.make_entrybox("title", taskdetail)
    wherebox, whereentry = EditScreen.make_entrybox("where")
    entrybox.pack_start_defaults(titlebox)
    entrybox.pack_start_defaults(wherebox)
    dialog.vbox.add(entrybox)

    taskdate = DateTable.new
    taskdatebox, taskdateentry, checkbox = taskdate.make_table(1)
    dialog.vbox.add(taskdatebox)

    scrolled_win, textbox = EditScreen.make_textareabox
    dialog.vbox.add(scrolled_win)
 
    dialog.show_all
    dialog.run do |response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        pp titleentry.text
        pp checkbox.active?
        pp textbox.buffer.text
      else
        puts 'キャンセルされました'
      end
    end
    dialog.destroy
  end

  def pasteventbutton_clicked(eventbox)
    pp eventbox
    dialog = Gtk::Dialog.new(
                             "Information",
                             @window,
                             Gtk::Dialog::MODAL,
                             [ "EmacsのDiarioに追加", Gtk::Dialog::RESPONSE_OK ], [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]
                             )
    dialog.has_separator = true
    dialog.border_width = 10

    scrolled_win, textbox = EditScreen.make_textareabox
    dialog.vbox.add(scrolled_win)
 
    dialog.show_all
    dialog.run do |response|
      case response
      when Gtk::Dialog::RESPONSE_OK
        pp textbox.buffer.text
      else
        puts 'キャンセルされました'
      end
    end
    dialog.destroy

  end

  def self.make_entrybox(label, text = nil)
    hbox = Gtk::HBox.new(false, 5)
    label = Gtk::Label.new(label)
    entry = Gtk::Entry.new
    entry.text = text if text
    hbox.pack_start(label, false, false, 0)
    hbox.pack_start(entry, false, false, 0)
    return hbox, entry
  end
  def self.make_textareabox
    textbox = Gtk::TextView.new
    scrolled_win = Gtk::ScrolledWindow.new
    scrolled_win.border_width = 5
    scrolled_win.add(textbox)
    scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
    scrolled_win.set_size_request(550, 400)
   return scrolled_win, textbox
  end
end

class ToggleLabel
  def initialize(eventboxes, flags)
    @eventboxes = eventboxes
    @flags = flags
    @done_undone_str = ['<span foreground="red" background="lightpink" weight="bold">oh...(ﾉд-。)</span>',
                        '<span foreground="blue" weight="bold">done!!ヽ(o￣∇￣o)ノ</span>']
  end
  def set_label()
    for i in 0..@eventboxes.size-1
      box = @eventboxes[i]
      box.children[0].name = @flags[i]
      box.children[0].markup = @done_undone_str[@flags[i].to_i]
  ### You need to call {{ realize }} only after you add it to the
  ### top (including) widget.
      box.realize
      box.window.cursor = Gdk::Cursor.new(Gdk::Cursor::HAND2)
      box.signal_connect('button_press_event') do |w, e|
        ToggleLabel.change_label(w.children[0], e, @done_undone_str)
      end
    end
  end
  def self.change_label(label, event, str)
    if event.event_type == Gdk::Event::BUTTON2_PRESS
      if label.name == "0"
        label.markup = str[1]
        label.name = "1"
      else
        label.markup = str[0]
        label.name = "0"
      end
    end
  end
end

class TaskFrame
  def initialize(title, parent)
    @title = title
    @parent = parent
  end
  def make_frame()
    frame = Gtk::Frame.new(@title)
    frame.border_width = 10
    @parent.pack_start(frame, true, true, 0)
    vbox = Gtk::VBox.new(false, 0)
    vbox.border_width = 5
    frame.add(vbox)
    return vbox
  end
end

class DateTable
  def initialize()
    @t = Time.now
    @items = [["year", 4, @t.strftime("%Y")],
              ["month", 2, @t.strftime("%m")],
              ["day", 2, @t.strftime("%d")]]
  end
  def make_table(flag = nil)
    n = 1
    if flag == 1
      @items << ["time", 4, @t.strftime("%H%M")]
      n = 2
    end
    entries = []
    hbox = Gtk::HBox.new(false, 5)
    for i in 0.. @items.size-1
      vbox = Gtk::VBox.new(false, 5)
      hbox.pack_start(vbox, false, false, 0)
      label = Gtk::Label.new(@items[i][0])
      vbox.pack_start(label, false, false, 0)
      n.times do
        entry = Gtk::Entry.new
        entry.set_size_request(50, 27)
        entry.max_length = @items[i][1]
        entry.text = @items[i][2]
        vbox.pack_start(entry, false, false, 0)
        entries << entry
      end
    end
    if flag == 1
      checkbox = Gtk::CheckButton.new("All day")
      checkbox.set_size_request(140, 70)
      hbox.pack_start(checkbox, false, false, 0)
      return hbox, entries, checkbox
    else
      return hbox, entries
    end
  end
end


###############
### main
###############

require 'gtk2'
require 'pp'
require "yaml"

t = Time.now
dir = File.dirname(__FILE__)
yamlfile = "#{dir}/private_data.yaml"
timefile = "#{dir}/time"

data = YamlData.new(yamlfile)
data.split_data

  taskflags, otherflags = [], []
begin
  File.open(timefile) do |f|
    taskflags = f.gets.chomp.split(/,/)
    otherflags = f.gets.chomp.split(/,/)
  end
rescue
  taskflags = Array.new(data.task.size, "0")
  otherflags = [t.strftime("%d"), "0", "0"]
end


#######################
#### make container
#######################
window = Gtk::Window.new
window.border_width = 10
window.resizable = true
#window.set_size_request(800, 500)
window.title = "Hige-Task-Helper"

main_box = Gtk::VBox.new(false, 0)
window.add(main_box)

frame1 = TaskFrame.new("Task", main_box)
vbox = frame1.make_frame
task_eventboxes = []
for i in 0..data.task.size-1
  separator = Gtk::HSeparator.new
  vbox.pack_start(separator, false, true, 5)
  task = ClickButtonAndToggleLabel.new(data.task[i]['taskname'], window)
  taskbox, eventbox = task.make_taskbox(data.task[i]['taskdetail'])
  vbox.pack_start(taskbox, false, false, 5)
  task_eventboxes << eventbox
  tasklabel = ToggleLabel.new(task_eventboxes, taskflags)
  tasklabel.set_label
end

separator = Gtk::HSeparator.new
vbox.pack_start(separator, false, true, 5)
task_free = ClickButtonAndToggleLabel.new('Other', window)
task_freebox, freeeventbox = task_free.make_taskbox("")
vbox.pack_start(task_freebox, false, false, 5)
task_free_eventboxes = [freeeventbox]
otherflag1 = [otherflags[1]]
tasklabel = ToggleLabel.new(task_free_eventboxes, otherflag1)
tasklabel.set_label

frame2 = TaskFrame.new("Get Past Event", main_box)
vbox = frame2.make_frame
pastevent = ClickButtonAndToggleLabel.new('Get!', window)
pastbox, pasteventbox = pastevent.make_pasteventbox
vbox.pack_start(pastbox, false, false, 5)
past_eventboxes = [pasteventbox]
otherflag2 = [otherflags[2]]
tasklabel = ToggleLabel.new(past_eventboxes, otherflag2)
tasklabel.set_label

window.signal_connect("delete_event") do
  File.open(timefile, "w") do |f|
    d = ""
    for i in 0..data.task.size-1
      d << task_eventboxes[i].children[0].name + ","
    end
    d << "\n" + t.strftime("%d") + "," + freeeventbox.children[0].name + "," + pasteventbox.children[0].name
    f.write d
  end

  Gtk::main_quit
end


window.show_all
Gtk.main

