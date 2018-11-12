require 'excon'

module Excon
  module RelativeTiming
    class Middleware < ::Excon::Middleware::Base
      class << self
        # Should point at logger object.
        attr_accessor :logger

        # Should reference a `Statsd` client object.
        attr_accessor :statsd_client

        # Boolean configuration parameter indicating whether the statsd metric should be tagged.
        # This is essentially limited to DataDog.
        attr_accessor :statsd_supports_tags
      end

      private def current_time
        Time.now.utc
      end

      def request_call(datum)
        @request_time = current_time
        @stack.request_call(datum)
      end

      def response_call(datum)
        response_time = current_time
        duration_sec = response_time - @request_time

        runtime = datum.dig(:response, :headers, 'X-Runtime')
        if runtime
          runtime_sec = runtime.to_f
          overhead_sec = duration_sec - runtime_sec

          runtime_ms = (runtime_sec * 1000).round
          overhead_ms = (overhead_sec * 1000).round

          if self.class.statsd_client
            if self.class.statsd_supports_tags
              tags = [
                "request_host:#{datum[:host]}",
                "request_method:#{datum[:method]}",
              ]
              self.class.statsd_client.timing('excon.remote_runtime', runtime_ms, tags: tags)
              self.class.statsd_client.timing('excon.network_overhead', overhead_ms, tags: tags)
            else
              self.class.statsd_client.timing('excon.remote_runtime', runtime_ms)
              self.class.statsd_client.timing('excon.network_overhead', overhead_ms)
            end
          end

          if self.class.logger
            logged_attrs = {
              # Expected to be provided by Rack:
              method: datum.fetch(:method, ''),
              host:   datum.fetch(:host, ''),
              port:   datum.fetch(:port, ''),
              path:   datum.fetch(:path, ''),

              # Specific to this middleware:
              message:             'Relative timing info the API call.',
              remote_runtime_ms:   runtime_ms.to_s,
              network_overhead_ms: overhead_ms.to_s, 
            }
            self.class.logger.info(logged_attrs)
          end
        end

        @stack.response_call(datum)
      end
    end
  end
end

