require "dotenv"
require "pry"

require "tweetstream"
require "twitter"
require_relative "lib/transcriber"

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
  if status.media?
    puts status

    AltBot::Twitter.reply(status)
  end
end

TweetStream::Client.new.track("alttext") do |status|
  puts status

  if status.media?
    AltBot::Twitter.reply(status)
  end
end

module AltBot
  class Twitter
    def self.reply(status)
      images = status.media.select { |m| m.is_a? Twitter::Media::Photo }
      uri = images.first.media_uri
      transcriber = AltBot::Transcriber.new(uri.to_s)

      EM.run do
        transcriber.transcribe

        transcriber.callback do |text|
          message = ".@#{status.user.screen_name} it looks like a #{text}."
          puts message

          client.update(message, in_reply_to_status_id: status.id)
        end

        transcriber.errback { |error| puts error }
      end
    end
  end
end
