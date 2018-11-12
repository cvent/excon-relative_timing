require 'spec_helper'
require 'stringio'

require 'statsd-ruby'

RSpec.describe Excon::RelativeTiming::Middleware do

  # All tests must exist in a context block that defined `logger_override` and
  # `statsd_client_override`. This simulates the configuration of the middleware that would
  # normally happen in a Rails initializer, etc.
  around(:each) do |example|
    saved_logger = Excon::RelativeTiming::Middleware.logger
    saved_statsd_client = Excon::RelativeTiming::Middleware.statsd_client
    saved_statsd_supports_tags = Excon::RelativeTiming::Middleware.statsd_supports_tags

    Excon::RelativeTiming::Middleware.logger = logger_override
    Excon::RelativeTiming::Middleware.statsd_client = statsd_client_override
    Excon::RelativeTiming::Middleware.statsd_supports_tags = statsd_supports_tags_override

    begin
      example.run
    ensure
      Excon::RelativeTiming::Middleware.logger = saved_logger
      Excon::RelativeTiming::Middleware.statsd_client = saved_statsd_client
      Excon::RelativeTiming::Middleware.statsd_supports_tags = saved_statsd_supports_tags
    end
  end

  # Useful for spying on the middleware in tests.
  let(:fake_log){ StringIO.new }
  let(:fake_statsd_client){ instance_double(::Statsd) }

  # Default config.
  let(:statsd_supports_tags_override){ nil }

  # Simulated excon datum values.
  let(:request_preflight) do
    {
      host: 'example.com',
      port: 80,
      path: '/some/path',
    }
  end

  let(:response_full) do
    response_headers = Excon::Headers.new
    response_headers['X-Runtime'] = '0.13243546'

    request_preflight.merge(
      response: {
        headers: response_headers
      }
    )
  end

  let(:response_incompatible) do
    request_preflight.merge(
      response: {
        headers: Excon::Headers.new
      }
    )
  end

  let(:middleware) do
    fake_next_middleware = double('Excon::Middleware::Base')
    allow(fake_next_middleware).to receive(:request_call) do |datum|
      datum
    end
    allow(fake_next_middleware).to receive(:response_call) do |datum|
      datum
    end
    Excon::RelativeTiming::Middleware.new(fake_next_middleware)
  end

  def simulate_request_and_response(req, resp)
    middleware.request_call(req)
    middleware.response_call(resp)
  end

  context "when it is configured with neither a logger nor a statsd client" do
    let(:logger_override){ nil }
    let(:statsd_client_override){ nil }

    it "does not complain" do
      expect{
        simulate_request_and_response(request_preflight, response_full)
      }.to_not raise_error
    end
  end

  context "when it is configured with a logger" do
    let(:logger_override){ ::Logger.new(fake_log) }
    let(:statsd_client_override){ nil }

    it "logs the runtime" do
      simulate_request_and_response(request_preflight, response_full)
      expect(fake_log.string).to match(/remote_runtime_ms.*132/)
    end
  end

  context "when it is configured with a tranditional statsd client" do
    let(:logger_override){ nil }
    let(:statsd_client_override){
      # This will send an actual packet to a local statsd instance. That's unfortunate but testing
      # against the real API of the statsd-ruby gem seems worth it.
      ::Statsd.new('127.0.0.2', 8126)
    }
    let(:statsd_supports_tags_override){ false }

    it "does not fail" do
      expect{ 
        allow(middleware).to receive(:current_time).and_return(Time.gm(1999, 12, 31, 23, 59, 59, 000000))
        middleware.request_call(request_preflight)
        allow(middleware).to receive(:current_time).and_return(Time.gm(1999, 12, 31, 23, 59, 59, 500000))
        middleware.response_call(response_full)
      }.to_not raise_error
    end
  end

  context "when it is configured with a datadog statsd client" do
    let(:logger_override){ nil }
    let(:statsd_client_override){ fake_statsd_client }
    let(:statsd_supports_tags_override){ true }

    it "sends the runtime as a timing" do
      expect(fake_statsd_client).to receive(:timing).with(%r{excon.remote_runtime}, 132, hash_including(:tags))
      expect(fake_statsd_client).to receive(:timing).with(%r{excon.network_overhead}, 368, hash_including(:tags))
      allow(middleware).to receive(:current_time).and_return(Time.gm(1999, 12, 31, 23, 59, 59, 000000))
      middleware.request_call(request_preflight)
      allow(middleware).to receive(:current_time).and_return(Time.gm(1999, 12, 31, 23, 59, 59, 500000))
      middleware.response_call(response_full)
    end
  end

  context "when the response is missing the X-Runtime header" do
    let(:logger_override){ ::Logger.new(fake_log) }
    let(:statsd_client_override){ fake_statsd_client }

    it "does not emit anything" do
      expect(statsd_client_override).to_not receive(:timing)
      expect(logger_override).to_not receive(:add)
      simulate_request_and_response(request_preflight, response_incompatible)
    end
  end
end


