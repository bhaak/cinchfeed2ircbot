require 'nokogiri'
require 'open-uri'

class Cinch::Twitter
  include Cinch::Plugin

  match /(.*twitter.com.*)/, use_prefix: false

  def get_twitter_content(status)
    begin
      tweet = Nokogiri::HTML(open(status))
      (tweet/"div.permalink-tweet p.tweet-text").each do |content_node|
        return "#{/twitter.com.(.*).status./.match(status)[1]}: #{content_node.content}"
      end
    rescue => e
      return e.message
    end
  end

  def execute(msg, text, *l)
    urls = text.split.select {|v| v =~ /^(https?:\/\/twitter.com\/.*\/status\/.*)/}
    urls.each {|u|
      ret = get_twitter_content(u)
      msg.reply(ret) if ret
    }
  end

end
