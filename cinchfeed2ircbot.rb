require 'rubygems'
require 'bundler/setup'

require 'feedzirra'

require 'cinch'

class Feed
  attr_accessor :name, :feed, :prefix, :channels
end

# Load config. If the normal config file doesn't exists, load example.
config = YAML.load(File.open(File.exists?('config.yaml') ? 'config.yaml' : 'config.yaml.example'))

def check_feed(bot, name, feed)
	begin
	bot.info "Checking for updates for feed #{name}"
	bot.info feed.to_s
	updated_feed = Feedzirra::Feed.update(feed.feed)
	if updated_feed and updated_feed.updated? then
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
				if channel.start_with? '#' then
					Channel(channel).send text
				else
					User(channel).send text
				end
			}
			bot.debug entry.to_s
		}
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

	on :connect do
		feeds = Hash.new
		channels = Hash.new
		# loop over all RSS feeds
		config['feeds'].each {|feed|
			bot.debug feed.to_s
			bot.info "Setting up feed #{feed['name']}"
			# init all RSS threads
			f = Feed.new
			f.feed = Feedzirra::Feed.fetch_and_parse(feed['url'])
			f.prefix = feed['prefix']
			f.channels = feed['channels']
			feeds[feed['name']] = f
			# join all channels in config
			feed['channels'].each {|channel|
				bot.join channel if channel.start_with? '#'
			}
		}

		# start a new thread for every feed
		feeds.each {|name, feed|
			# TODO: make sleep interval configurable
			Thread.new { loop { check_feed(bot, name, feed); sleep 600 } }
		}
	end

	on :message, /(.*)/ do |m, message|
		if message.start_with? bot.nick then
			m.reply config['message'] || "I'm just a dumb bot, ask the person who runs me."
		end
	end
}

bot.start
