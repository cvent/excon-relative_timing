# Excon::RelativeTiming

When one app makes an API call to another app, at the highest level there are only two components
involved. When you look more closely, you can see many more components. This becomes important when
investigating performance issues. When the API call is made, requestor spends some time generating
and sending the request. The receiver spends some time responding to the request. The remainder of
the time is spent waiting for the network to shuffle the bytes back and forth. Here _"the network"_
refers to everything between the requestor and the responder. This can include tranditional
networking equipment but it can also refer to "middleboxes" (e.g. reverse proxies, load balancers,
application firewalls, etc).

This gem aides in debugging performance problems, by measuring the time it takes to complete an API
call from the requestor's point of view. It relies on the response including an `X-Runtime` header
that represents the time spent responding to the request from the responding application's point of
view. The requestor subtracts the `X-Runtime` value from it's own measurement to determine what
portion isn't accounted for by either the requestor or the respondor.

## Configuration

To configure this gem, just set these module attributes. If you're using this from within a Rails
app, consider doing this in an initializer.

```
# If you want to have timings logged, set this to a logger instance. It will receive a `Hash`, so be
# sure that your logger will properly format the `Hash`.
Excon::RelativeTiming::Middleware.logger = Rails.logger

# If you want to have timings sent to statsd, set this to an instance of `Statsd`.
require 'statsd-ruby'
Excon::RelativeTiming::Middleware.statsd_client = Statsd.new('127.0.0.1', 8125)
Excon::RelativeTiming::Middleware.statsd_supports_tags = false

# If you're using DataDog and you want the timings tagged by request host and method then you can
# set this to an instance of `Datadog::Statsd`.
require 'datadog/statsd'
Excon::RelativeTiming::Middleware.statsd_client = Datadog::Statsd.new('127.0.0.1', 8125)
Excon::RelativeTiming::Middleware.statsd_supports_tags = true
```

## Notes

This middleware does not do anything special to account for retried requests. If you use Excon's
automatic retry feature you will have to take the average retry rate into account when interpreting
the stats reported by this gem.

## License

This gem is licensed under the Apache 2.0. See the `LICENSE` file.

