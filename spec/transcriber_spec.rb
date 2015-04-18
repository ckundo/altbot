require_relative "../lib/transcriber"

RSpec.describe AltBot::Transcriber do
  it "transcribes text in an image" do

    stub_request(:post, "http://api.cloudsightapi.com/image_requests").
      to_return(body: { token: "abc123" }.to_json)

    stub_request(:get, "http://api.cloudsightapi.com/image_responses/abc123").
      to_return({
        status: 200,
        body: {
          status: "completed",
          name: "ermahgerd i wern anerther debert"
        }.to_json,
        headers: {
          status: 200
        }
    })

    url = "http://i0.kym-cdn.com/photos/images/original/000/422/676/969.jpg"

    transcriber = described_class.new(url)

    EM.run do
      transcriber.transcribe

      transcriber.callback do |text|
        expect(text).to eq "ermahgerd i wern anerther debert"
        EM.stop
      end
    end
  end
end
