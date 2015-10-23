require 'json'
require 'open-uri'
require 'nokogiri'

class Sendeplan
  def self.format_item(item)
    "#{item[:summary]} von #{item[:start][:dateTime][11..15]} bis #{item[:end][:dateTime][11..15]} Uhr"
  end

  def self.jetzt_und_danach
    key = File.read(File.expand_path("~/.google_calendar_api_key")).strip
    url = "https://www.googleapis.com/calendar/v3/calendars/"+
      "h6tfehdpu3jrbcrn9sdju9ohj8@group.calendar.google.com/events"+
      "?singleEvents=true&orderBy=startTime&timeZone=CET&"+
      "timeMin=#{(Time.now).utc.iso8601}&"+
      "timeMax=#{(Time.now+86400).utc.iso8601}&"+
      "key=#{key}"

    open(url) do |cal|
      events = JSON.parse cal.read, symbolize_names: true
      [format_item(events[:items][0]), format_item(events[:items][1])]
    end
  end
end

class RBTV
  def initialize
    @data = open('https://api.twitch.tv/kraken/streams/rocketbeanstv')
    @json = JSON.parse(@data.read)
  end

  def live_zuschauer
    begin
      # format numbers with the German thousands separator
      @json["stream"]["viewers"].to_s.reverse.scan(/.{1,3}/).join('.').reverse if @json["stream"]
    rescue => e
      e.to_s
    end
  end

  def thema
    @json["stream"]["channel"]["status"].split('|').first.strip
  end

  def self.aktuelle_sendung
    rbtv = RBTV.new
    live_zuschauer = rbtv.live_zuschauer
    live_zuschauer ? "Gerade schauen #{rbtv.live_zuschauer} Zuschauer #{rbtv.thema}." :
      "RBTV scheint gerade nicht zu senden."
  end

  def self.sofia_schnuerrle_interview_count
    key = File.read(File.expand_path("~/.google_api_keys/youtube_data")).strip
    url = "https://www.googleapis.com/youtube/v3/videos?part=statistics&id=NSx0_18lC5w&key=#{key}"

    open(url) do |request|
      data = JSON.parse(request.read, symbolize_names: true)
      data[:items].first[:statistics][:viewCount].to_s.reverse.scan(/.{1,3}/).join('.').reverse
    end
  end

  def self.ist_das_live
    begin
      url = "http://rbtvapi.rodney.io/islive"
      open(url) do |request|
        data = JSON.parse(request.read, symbolize_names: true)

        return "Da stimmt was nicht: #{data[:error]}" if data[:error] != "ok"
        "Das ist #{data[:islive] ? "" : "nicht "}live!"
      end
    rescue => e
      e.to_s
    end
  end
end
