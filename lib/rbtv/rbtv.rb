require 'json'
require 'open-uri'
require 'nokogiri'

class Fixnum
  def german
    to_s.reverse.scan(/.{1,3}/).join('.').reverse
  end
end

class RBTV
  def initialize
    @data = open('https://api.twitch.tv/kraken/streams/rocketbeanstv')
    @json = JSON.parse(@data.read)
  end

  def live_zuschauer
    @json["stream"]["viewers"].to_i
  end

  def thema
    @json["stream"]["channel"]["status"].split('|').first.strip
  end

  def daten_aktuelle_sendung_twitch
    { zuschauer: live_zuschauer, thema: thema }
  end

  def self.aktuelle_sendung
    twitch = RBTV.new.daten_aktuelle_sendung_twitch
    youtube = daten_aktuelle_sendung_youtube
    if youtube[:thema].size > twitch[:thema].size && youtube[:thema].start_with?(twitch[:thema])
      twitch[:thema] = youtube[:thema]
    end
    if twitch[:thema].size > youtube[:thema].size && twitch[:thema].start_with?(youtube[:thema])
      youtube[:thema] = twitch[:thema]
    end

    if twitch[:thema] == youtube[:thema]
      "Gerade schauen #{(twitch[:zuschauer]+youtube[:zuschauer]).german} Zuschauer #{twitch[:thema]}. "+
        "Auf Twitch #{twitch[:zuschauer].german} und auf YouTube #{youtube[:zuschauer].german}."
    else
      "Gerade schauen #{(twitch[:zuschauer]+youtube[:zuschauer]).german} Zuschauer RBTV. "+
        "Auf Twitch schauen #{twitch[:zuschauer].german} Zuschauer #{twitch[:thema]} und auf YouTube schauen #{youtube[:zuschauer].german} Zuschauer #{youtube[:thema]}."
    end
  end

  def self.aktuelle_sendung_twitch
    rbtv = RBTV.new.daten_aktuelle_sendung_twitch
    rbtv[:zuschauer] ? "Gerade schauen #{rbtv[:zuschauer].german} Zuschauer #{rbtv[:thema]}." :
      "RBTV scheint gerade nicht zu senden."
  end

  def self.daten_aktuelle_sendung_youtube
    key = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"
    live_url = "https://www.youtube.com/c/rocketbeanstv/live"
    html = Nokogiri::HTML(open(live_url))
    video_id = html.xpath('//meta[@itemprop="videoId"]').map {|n| n.attr('content') }.first

    url = "https://www.googleapis.com/youtube/v3/videos?part=liveStreamingDetails,snippet&id=#{video_id}&key=#{key}"

    open(url) do |request|
      data = JSON.parse(request.read, symbolize_names: true)
      item = data[:items].first
      if item
        thema = item[:snippet][:title]
        live_zuschauer = item[:liveStreamingDetails][:concurrentViewers].to_i
        { zuschauer: live_zuschauer, thema: thema }
      else
        {}
      end
    end
  end

  def self.aktuelle_sendung_youtube
    aktuelle_sendung = daten_aktuelle_sendung_youtube
    if !aktuelle_sendung.empty?
      "Gerade schauen #{aktuelle_sendung[:zuschauer].german} Zuschauer #{aktuelle_sendung[:thema]}."
    else
      "RBTV scheint gerade nicht zu senden."
    end
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

  def self.shitstorm?
    begin
      neins = ["Anscheinend nicht.",
               "Sieht nicht so aus.",
               "Ich glaube nicht.",
               "Ich weiss von nichts.",
               "Nicht, dass ich wüsste.",]

      url = "https://rbtvshitstorm.is/"
      html = Nokogiri::HTML(open(url))
      link = html.at_css(".rbtv a")
      if link && link.text == "JA"
        "Natürlich! Schau mal hier: #{link.attr('href')}"
      else
        neins[Time.now.to_i % neins.size]
      end
    rescue => e
      e.to_s
    end
  end
end
