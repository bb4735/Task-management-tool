require 'time'
require 'json'

class TimeTrackingTool
  PATH_TO_TASKS_FILE = "tasks.json"

  def initialize
    @tasks = load_tasks
  end
  
  def start_task(task_name)
    task_name = task_name.to_sym
    return puts "タスク: #{task_name}は既に存在しています。" if @tasks.key?(task_name)
  
    @tasks[task_name] = { start_time: Time.now, end_time: nil }
    save_tasks
    puts "タスク: #{task_name}を開始しました。"
  end

  def finish_task(task_name)
    task_name = task_name.to_sym
    return puts "タスク: #{task_name}は開始されていません。" unless @tasks.key?(task_name)
    return puts "タスク: #{task_name}はすでに終了しています。" unless @tasks[task_name][:end_time].nil?
  
    @tasks[task_name][:end_time] = Time.now
    save_tasks
    puts "タスク: #{task_name}を終了しました。"
  end

  def show_today_tasks
    puts "本日のタスク一覧"
    total_time = 0
    today = Date.today

    @tasks.each do |task_name, times|
      if times[:start_time].to_date == today
        end_time = times[:end_time] || Time.now
        worked_seconds = end_time - times[:start_time]
        total_time += worked_seconds
        worked_time_today = format_time(worked_seconds)
        print "#{task_name}: 開始時間:#{times[:start_time]} 終了時間:#{times[:end_time]}"
        puts " 実績時間:#{worked_time_today}"
      end
    end
    puts "本日の合計作業時間: #{format_time(total_time)}"
  end

  def show_week_tasks
    total_seconds_by_day = Hash.new(0)

    @tasks.each do |task_name, times|
      start_date = times[:start_time].to_date
      if start_date >= Date.today - 7
        end_time = times[:end_time] || Time.now
        worked_seconds = end_time - times[:start_time]
        total_seconds_by_day[start_date] += worked_seconds
      end
    end

    puts "直近7日間の作業時間"
    total_seconds_by_day.sort.each do |date, total_seconds|
      puts "#{date}: #{format_time(total_seconds)}"
    end
  end

  def format_time(seconds)
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    seconds = (seconds % 60).to_i
    format("%02d時間%02d分%02d秒", hours, minutes, seconds)
  end

  def save_tasks
    File.open(PATH_TO_TASKS_FILE, "w") do |file|
      file.write(JSON.pretty_generate(@tasks))
    end
  end

  def load_tasks
    if File.exist?(PATH_TO_TASKS_FILE)
      file_content = File.read(PATH_TO_TASKS_FILE)
      @tasks = JSON.parse(file_content, symbolize_names: true)

      @tasks.each do |task_name, times|
        times[:start_time] = Time.parse(times[:start_time]) if times[:start_time]
        times[:end_time] = Time.parse(times[:end_time]) if times[:end_time]
      end
    else
      @tasks = {}
    end
  end

  def show_usage
    puts "Usage: ruby time_tracking_tool.rb [option]"
    puts "-s <task_name> / --start <task_name>  : タスク開始"
    puts "-f <task_name> / --finish <task_name> : タスク終了"
    puts "-st / --show-today                    : 本日のタスク一覧表示"
    puts "-sw / --show-week                     : 直近7日間の作業時間表示"
  end

  def self.run
    tool = TimeTrackingTool.new
    case ARGV[0]
    when '-s', '--start'
      return tool.start_task(ARGV[1]) if ARGV[1]
      
      puts "タスク名が指定されていません。"
      tool.show_usage
    when '-f', '--finish'
      return tool.finish_task(ARGV[1]) if ARGV[1]
      
      puts "タスク名が指定されていません。"
      tool.show_usage
    when '-st', '--show-today'
      tool.show_today_tasks
    when '-sw', '--show-week'
      tool.show_week_tasks
    else
      tool.show_usage
    end
  end
end

TimeTrackingTool.run