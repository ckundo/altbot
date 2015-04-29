require "dotenv"
require "pry"

require "tweetstream"
require "twitter"

require_relative "lib/uri_extractor"
require_relative "lib/transcriber"

RESTRICTED = %w(
  alt_text_bot
).freeze

Dotenv.load

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
  unless RESTRICTED.include?(status.user.screen_name)
    uri_extractor = AltBot::UriExtractor.call(status, client)
    image_uri = uri_extractor.image_uri

    if image_uri
      EM.run do
        transcriber = AltBot::Transcriber.new(image_uri)
        transcriber.transcribe

        transcriber.callback do |text|
          message = "alt=#{text.slice(0..50)}. #{status.url} - @#{status.user.screen_name}"

          client.update(message, in_reply_to_status_id: status.id)
        end

        transcriber.errback { |error| puts error }
      end
    end
  end
end
