require 'rubygems'
require 'bundler/setup'

require 'feedjira'

require 'cinch'
require 'yaml'

$LOAD_PATH.unshift File.expand_path('..', __FILE__)

require 'cinchfeed2ircbot/interval'

require 'rbtv/rbtv'
require 'rbtv/sendeplan'

class Feed
	attr_accessor :feed, :prefix, :channels, :timer, :condition

	def initialize
		@timer = CinchFeed2IrcBot::Interval.new
	end
end

# loading plugins
plugins_paths = $LOAD_PATH.map {|path| path+"/plugins"}.select {|path| File.exists?(path) }
plugins_paths.map {|path| Dir.glob(path+"/*.rb")}.flatten.each {|plugin| load plugin }

$reddit = []

# Load config. If the normal config file doesn't exists, load example.
config = YAML.load(File.open(File.exists?('config.yaml') ? 'config.yaml' : 'config.yaml.example'))
config['prefix'] ||= '!'

def check_feed(bot, name, feed)
	begin
	sleep feed.timer.next_interval
	bot.info "Checking for updates for feed #{name}"
	bot.info feed.to_s
	updated_feed = Feedjira::Feed.update(feed.feed)
	if updated_feed.respond_to?("updated?") and updated_feed.updated? then
		feed.timer.reset if feed.feed.new_entries.size > 0
		bot.info "Feed #{name} has been updated"
		# TODO
		# short url
		feed.feed.new_entries.each {|entry|
			text = ""
			# construct display text
			if entry.url then
				text = "#{feed.prefix}: #{entry.title} #{entry.url}"
			else
				text = "#{feed.prefix}: #{entry.title}"
			end

			# send text to all channels and users
			feed.channels.each {|channel|
				if eval(feed.condition) then
					post_link = true
					if channel == "#RBTV"
						link_already_posted = $reddit.find {|m| m.include? entry.url.match(%r{comments/([^/]*)/})[1] }
						submitted_by_praktikante = entry.summary.include? "://www.reddit.com/user/Praktikante"
						post_link = !link_already_posted && !submitted_by_praktikante

						# Reddit-Shortlink
						text = "#{$1.strip} - https://#{$2}/#{$3}" if text =~ %r{(.*)http.*//(www.reddit.com).*comments\/([^/]+\/[^/]+\/.+|[^/]+)}
					end

					if channel.start_with? '#' then
						Channel(channel).send text if post_link
					else
						User(channel).send text
					end
				end
			}
			bot.debug entry.to_s
		}
		updated_feed.new_entries = []
		feed.feed = updated_feed
	end
	rescue Exception => e
		bot.error("check_feed: #{e.inspect}")
		e.backtrace.each {|b|
			bot.error("check_feed:  #{b}")
		}
		raise e
	end
end


# connect to IRC
bot = Cinch::Bot.new { |b|
	configure { |c|
		c.nick = config['nick']
		c.user = config['user'] || config['nick']
		c.realname = config['real_name'] || config['nick']
		c.server = config['server']
		c.port = config['port']

		if config['ssl'] then
			c.ssl.use = true
			c.ssl.verify = (config['verify_ssl'] != false)
			c.port ||= 6697
			b.info("using SSL for #{c.nick}@#{c.server}")
		else
			c.port ||= 6667
			b.info("not using SSL for #{c.nick}@#{c.server}")
		end
	}
	b.loggers.push Cinch::Logger::FormattedLogger.new(File.new("cinchfeed2ircbot.log", "w"))

	on :connect do
		feeds = Hash.new
		# loop over all RSS feeds
		config['feeds'].each {|feed|
			bot.debug feed.to_s
			bot.info "Setting up feed #{feed['prefix']}"
			# init all RSS threads
			f = Feed.new
			f.feed = Feedjira::Feed.fetch_and_parse(feed['url'])
			f.prefix = feed['prefix']
			f.channels = feed['channels']
			f.condition = feed['condition'] || "true"
			feeds[feed['prefix'].to_sym] = f
			# join all channels in config
			feed['channels'].each {|channel|
				bot.join channel if channel.start_with? '#'
			}
		}

		# start a new thread for every feed
		feeds.each {|name, feed|
			Thread.new { loop { check_feed(bot, name, feed); } }
			sleep 1
		}
	end

  on :message, /(.*)/ do |m, message|
    begin
      if message.downcase == "#{config["prefix"]}sendeplan" then
        sendungen = Sendeplan.jetzt_und_danach
        m.reply "#{m.user.name}: Gerade läuft #{sendungen[0]}."
        sleep 1
        m.reply "#{m.user.name}: Danach kommt #{sendungen[1]}."

      elsif message.downcase == "#{config["prefix"]}zuschauer" then
        m.reply "#{m.user.name}: #{RBTV.aktuelle_sendung}"

      elsif message.downcase == "#{config["prefix"]}sofia"
        views = RBTV.sofia_schnuerrle_interview_count
        m.reply "#{m.user.name}: #{views} Views hat Sofias Interview mit diesem unbekannten Fußballer."

      elsif message.strip.downcase == "#{config["prefix"]}live" ||
            message.strip.downcase == "ist das live?"
        m.reply "#{m.user.name}: #{RBTV.ist_das_live}"

      elsif message.start_with? bot.nick then
        m.reply config['message'][m.channel.name] ||
          config['message']['default'] ||
          config['message'] ||
          "I'm just a dumb bot, ask the person who runs me."

      elsif message.include? "https://www.reddit.com/r/"
        $reddit << message
      end
    rescue => e
      bot.error e.to_s
      m.reply "#{m.user.name}: #{e.to_s}"
    end
  end
}

# load configured plugins
bot.plugins.register_plugins((config["plugins"]||[]).map {|plugin| Module.const_get plugin })

bot.start
