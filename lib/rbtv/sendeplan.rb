require 'open-uri'
require 'nokogiri'

class Sendeplan
  class Show
    attr_reader :time

    def initialize(xml)
      @time = Time.parse(xml.at_css(".scheduleTime").text)
      show_details = xml.at_css(".showDetails")
      @title = show_details.at_css("h4").text
      @sub_title = show_details.at_css(".game")&.text
      @duration = show_details.at_css(".showDuration")
      @prefix = show_details.at_css(".smallBtn")&.text
    end

    def title
      @sub_title ? "#{@title} - #{@sub_title}" : @title
    end

    def start_time
      @time.strftime("%H:%M")
    end

    def end_time
      /(?:(\d+) Std. )?(\d+) Min./.match(@duration)
      minutes = $1.to_i*60+$2.to_i
      (@time+minutes*60).strftime("%H:%M")
    end

    def prefix
      @prefix ? "[#{@prefix[0].upcase}] " : ""
    end

    def to_s
      "#{prefix}#{title} von #{start_time} bis #{end_time} Uhr"
    end
  end

  def self.jetzt_und_danach
    wochenplan = Nokogiri::HTML(open("https://www.rocketbeans.tv/wochenplan/"))
    today = wochenplan.at_css(".today")
    binding.pry
    shows = today.css(".show").map {|show| Show.new(show) }

    [shows.reverse.find {|show| show.time <= Time.now }.to_s,
     shows.find {|show| show.time >= Time.now }.to_s].compact
  end
end
