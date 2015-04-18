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
  if status.user.screen_name != "alt_text_bot"
    tweet_url = status.urls.find do |url|
      url.expanded_url.to_s.match(/^https:\/\/twitter\.com\/.*\/status\/.*$/)
    end

    if tweet_url
      id = tweet_url.expanded_url.to_s.split("/").last.to_i
      retweet = client.status(id)

      if retweet.media?
        images = retweet.media.select { |m| m.is_a? Twitter::Media::Photo }
        uri = images.first.media_uri

        EM.run do
          transcriber = AltBot::Transcriber.new(uri.to_s)
          transcriber.transcribe

          transcriber.callback do |text|
            message = "alt=#{text}. #{tweet_url.url} - @#{status.user.screen_name} @#{retweet.user.screen_name}"

            client.update(message, in_reply_to_status_id: id)
          end

          transcriber.errback { |error| puts error }
        end
      end
    end
  end
end
