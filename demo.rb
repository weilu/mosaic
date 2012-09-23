require 'open-uri'
require 'nokogiri'
require 'google_calendar'

class CalendarParser
  attr_reader :start_date, :calendar

  def initialize
    @doc = Nokogiri::HTML(open 'http://www.mosaicdance.com.sg/calendar.html')
    @start_date = Date.parse(@doc.css('.calendar-headings-white')[1].content)

    @calendar = Google::Calendar.new(username: 'wei.calendar.demo@gmail.com',
                                     password: 'wordpass09')
  end
  
  def clear_calendar
    (@calendar.events || []).each{ |e| calendar.delete_event(e) }
  end

  def weekly_mappings_for_studio calendar_id
    tables = @doc.css("#{calendar_id} table table table")
    tables.map do |table|
      times = table.css('tr td >span').map(&:content).select{|a| !a.empty? }.compact
      courses = table.css('tr td .calendar-timing-black strong').map(&:content).select{|a| !a.empty? }.compact
      next if times.empty? || courses.empty?
      [times, courses]
    end.compact
  end

  def create_events mappings
    (@start_date..@start_date+6).to_a.each_with_index do |date, i|
      day_mapping = mappings[i]
      times = parse_from_to(day_mapping[0], date)
      classes = day_mapping[1]

      times.each_with_index do |from_to, i|
        event = calendar.create_event do |e|
          e.title = classes[i]
          e.start_time = from_to.first
          e.end_time = from_to.last
        end
        puts event
      end
    end
  end
  
  private
  
  def parse_from_to times, date
    times.map do |from_to| 
      from, to = from_to.split(' to ').map do |t| 
        DateTime.parse("#{date.to_s} #{t} +0800")
      end
      to += 1 if from > to
      [from.to_time, to.to_time]
    end
  end
end

p = CalendarParser.new
p.clear_calendar
mappings = p.weekly_mappings_for_studio('#blue_calandar')
p.create_events(mappings)
