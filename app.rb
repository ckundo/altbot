require "dotenv"
require "pry"
require "yaml"

require "twitter"

require_relative "lib/uri_extractor"
require_relative "lib/transcriber"

require "honeybadger"

Dotenv.load

Honeybadger.start

USERS = ENV.fetch("USERS").split(",").freeze

client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV.fetch("TWITTER_CONSUMER_KEY")
  config.consumer_secret = ENV.fetch("TWITTER_CONSUMER_SECRET")
  config.access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
  config.access_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
end

streamer = Twitter::Streaming::Client.new do |config|
  config.consumer_key = ENV.fetch("TWITTER_CONSUMER_KEY")
  config.consumer_secret = ENV.fetch("TWITTER_CONSUMER_SECRET")
  config.access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
  config.access_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
end

def is_tweet_from_myself?(object)
  object.user.screen_name == "alt_text_bot"
end

def is_subscribed_user?(object)
  USERS.include?(object.user.screen_name)
end

streamer.user(replies: "all") do |object|
  case object
    when Twitter::Tweet
      unless is_tweet_from_myself?(object)
        if is_subscribed_user?(object)
          uri_extractor = AltBot::UriExtractor.call(object, client)
          image_uri = uri_extractor.image_uri
          tweet = uri_extractor.retweet || object
          message = ""

          if image_uri
            EM.run do
              transcriber = AltBot::Transcriber.new(image_uri)
              transcriber.transcribe
              puts "transcribing #{image_uri} from status #{tweet.id}"

              transcriber.callback do |text|
                message += "alt=#{text.slice(0..100)}"
                if object.user.screen_name != tweet.user.screen_name
                  message += " @#{object.user.screen_name} "
                end

                message += " @#{tweet.user.screen_name}"
                client.update(message, in_reply_to_status_id: tweet.id)

                puts message
              end

              transcriber.errback do |error|
                Honeybadger.notify(error)
              end
            end
          end
        end
      end
      
    when Twitter::Streaming::StallWarning
      Honeybadger.notify("Twitter::Streaming::StallWarning")
  end
end

Honeybadger.notify("altbot process ended")
