require 'json'
require 'open-uri'
require 'nokogiri'

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
