module AltBot
  class UriExtractor
    attr_reader :image_uri, :retweet

    def self.call(*args)
      new(*args)
    end

    def initialize(status, client)
      @status = status
      @client = client

      images = images_from_tweet(tweet)

      if images.any?
        @image_uri = images.first.media_uri.to_s
      end
    end

    private

    attr_reader :status, :client, :tweet

    def tweet
      if status.media?
        @tweet ||= status
      elsif retweet_url
        id = retweet_url.expanded_url.to_s.split("/").last.to_i
        @retweet = @tweet ||= retweeted_status(id)
      end
    end

    def retweet_url
      @retweet_url ||= status.urls.find do |url|
        url.expanded_url.to_s.match(/^https:\/\/twitter\.com\/.*\/status\/.*$/)
      end
    end

    def images_from_tweet(tweet)
      @images ||= tweet.media.select { |m| m.is_a? Twitter::Media::Photo } || []
    end

    def retweeted_status(id)
      @retweeted_status ||= client.status(id)
    end
  end
end
