require "json"
require "sinatra"

class Chef
  class Node
    # dummy class for JSON parsing
  end
end

module ApiHelpers
  def self.payload_type(payload)
    message_type = payload["message_type"]
    status       = payload["status"]

    message_type == "run_converge" ? "#{message_type}.#{status}" : message_type
  end
end

class Counter
  def self.reset
    @@counters = Hash.new { |h, k| h[k] = 0 }
  end

  def self.increment(payload)
    counter_name = ApiHelpers.payload_type(payload)
    @@counters[counter_name] += 1
  end

  def self.to_json
    @@counters.to_json
  end
end

class MessageCache
  include ApiHelpers

  def self.reset
    @@message_cache = {}
  end

  def self.store(payload)
    cache_key = ApiHelpers.payload_type(payload)

    @@message_cache[cache_key] = payload
  end

  def self.fetch(cache_key)
    @@message_cache[cache_key].to_json
  end
end

Counter.reset

get "/" do
  "Data Collector API server"
end

get "/reset-counters" do
  Counter.reset
  "counters reset"
end

get "/counters" do
  Counter.to_json
end

get "/cache/:key" do |cache_key|
  MessageCache.fetch(cache_key)
end

get "/reset-cache" do
  MessageCache.reset
  "cache reset"
end

post "/data-collector/v0" do
  body = request.body.read
  payload = JSON.load(body)

  Counter.increment(payload)
  MessageCache.store(payload)

  status 201
  "message received"
end
