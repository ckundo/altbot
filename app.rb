require "dotenv"
require "pry"
require "yaml"

require "tweetstream"
require "twitter"

require_relative "lib/uri_extractor"
require_relative "lib/transcriber"

Dotenv.load

USERS = ENV.fetch("USERS").split(",").freeze

client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV.fetch("TWITTER_CONSUMER_KEY")
  config.consumer_secret = ENV.fetch("TWITTER_CONSUMER_SECRET")
  config.access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
  config.access_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
end

TweetStream.configure do |config|
  config.consumer_key = ENV.fetch("TWITTER_CONSUMER_KEY")
  config.consumer_secret = ENV.fetch("TWITTER_CONSUMER_SECRET")
  config.oauth_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
  config.oauth_token_secret = ENV.fetch("TWITTER_ACCESS_SECRET")
  config.auth_method = :oauth
end

TweetStream::Client.new.userstream do |status|
  puts status.text

  unless status.user.screen_name == "alt_text_bot"
    if USERS.include?(status.user.screen_name)
      uri_extractor = AltBot::UriExtractor.call(status, client)
      image_uri = uri_extractor.image_uri
      tweet = uri_extractor.retweet || status
      message = ""

      if image_uri
        EM.run do
          transcriber = AltBot::Transcriber.new(image_uri)
          transcriber.transcribe
          puts "transcribing #{image_uri} from status #{tweet.id}"

          transcriber.callback do |text|
            message += "alt=#{text.slice(0..100)}"
            if status.user.screen_name != tweet.user.screen_name
              message += " @#{status.user.screen_name} "
            end

            message += " @#{tweet.user.screen_name}"
            client.update(message, in_reply_to_status_id: tweet.id)

            puts message
          end

          transcriber.errback { |error| puts error }
        end
      end
    else
      client.update(
        "@#{status.user.screen_name} Sign up for descriptions at http://alttextbot.com",
        in_reply_to_status_id: status.id
      )
    end
  end
end
