require "em-http"
require "json"
require "rest-client"

class Transcriber
  include EM::Deferrable

  def initialize(image_url)
    @image_url = image_url
  end

  def transcribe
    http = EM::HttpRequest.new(
      "http://api.cloudsightapi.com/image_responses/#{token}"
    ).get(
      head: {
        "Accept" => "application/json",
        "Authorization" => "CloudSight #{ENV.fetch("CLOUD_SIGHT_KEY")}"
      }
    )

    http.errback do
      self.fail("Error making API call")
    end

    http.callback do
      if http.response_header.status == 200
        response = JSON.parse(http.response)
        status = JSON.parse(http.response).fetch("status")

        if status == "completed"
          self.succeed(response.fetch("name"))
        else
          transcribe
        end
      else
        self.fail("Call to transcribe failed")
      end
    end
  end

  private

  attr_reader :image_url

  def token
    @token ||= JSON.parse(RestClient.post(
      "http://api.cloudsightapi.com/image_requests",
      {
        "focus[x]" => "480",
        "focus[y]" => "640",
        "image_request[altitude]" => "27.912109375",
        "image_request[language]" => "en",
        "image_request[latitude]" => "35.8714220766008",
        "image_request[locale]" => "en_US",
        "image_request[longitude]" => "14.3583203002251",
        "image_request[remote_image_url]" => image_url
      },
      {
        "Accept" => "application/json",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Authorization" => "CloudSight #{ENV.fetch("CLOUD_SIGHT_KEY")}"
      }
    )).fetch("token")
  end
end
