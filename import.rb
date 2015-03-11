#!/usr/bin/env ruby

usage = <<-USAGE
USAGE:
  bundle exec import.rb "user/repo_name"
USAGE

require 'bundler/setup'
require 'octokit'
require 'logger'
require "csv"
require 'netrc'
require 'faraday-http-cache'
require 'active_support/cache'
require 'benchmark'

require_relative 'lib/extensions'
require_relative 'lib/pull_request_record'
require_relative 'lib/pull_request_loader'

repository_name = ARGV[0] # the format is "user/repo_name"

if repository_name.nil? || repository_name.empty? || !repository_name.match(/.+\/.+/)
  puts usage
  exit(1)
end

safe_repository_name = repository_name.gsub(/\//, "_")

# cache setup
cache_path = File.join(File.expand_path('..', __FILE__), 'cache')
store  = ActiveSupport::Cache::FileStore.new(cache_path, expires_in: (60*60*24*365))

# logger setup
logger = Logger.new("log/#{safe_repository_name}.log")
logger.level = Logger::DEBUG #Logger::INFO

# octokit setup
stack = Faraday::RackBuilder.new do |builder|
  builder.use :http_cache, store: store, logger: logger, shared_cache: false, serializer: Marshal
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack
client = Octokit::Client.new(:netrc => true)

logger.info('Starting')

loader = PullRequestLoader.new(repository_name, logger, client)
loader.load_all!
