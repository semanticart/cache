# Cache

Don't use this in production, I just built it to play around with elixir :)

A basic cache that allows setting expiration times.

It has no ceiling on memory usage and doesn't purge old items. I'm claiming YAGNI for this prototype but depending on the usage, a periodic call to purge old items (or something more intelligent) might be desired.
