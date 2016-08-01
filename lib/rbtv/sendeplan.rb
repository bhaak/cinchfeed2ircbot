require 'open-uri'
require 'nokogiri'
require 'json'

class Sendeplan
  class Show
    attr_reader :time

    def initialize(data)
      @start_time = Time.parse(data[:timeStart])
      @end_time = Time.parse(data[:timeEnd])
      @title = data[:title]
      @sub_title = data[:topic]
      @prefix = data[:type]
    end

    def title
      @sub_title ? "#{@title} - #{@sub_title}" : @title
    end

    def start_time
      @start_time.strftime("%H:%M")
    end

    def end_time
      @end_time.strftime("%H:%M")
    end

    def prefix
      @prefix.length > 0 ? "[#{@prefix[0].upcase}] " : ""
    end

    def to_s
      "#{prefix}#{title} von #{start_time} bis #{end_time} Uhr"
    end
  end

  def self.jetzt_und_danach
    begin
      url = "http://api.rbtv.rodney.io/api/1.0/schedule/schedule_linear.json"
      open(url) do |request|
        data = JSON.parse(request.read, symbolize_names: true)

        index = data[:schedule].find_index {|e| Time.now < Time.parse(e[:timeEnd]) }.to_i
        [Show.new(data[:schedule][index]), Show.new(data[:schedule][index+1])]
      end
    rescue => e
      e.to_s
    end
  end
end
