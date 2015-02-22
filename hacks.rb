#!/usr/bin/env ruby

require 'bundler/setup'
require 'octokit'
require 'logger'
require "csv"

class Time
  # remove timezone information
  def to_s
    self.strftime "%Y-%m-%d %H:%M:%S"
  end
end

class PullRequestRecord
  RECORD_DEF = {
    number: -> (pr){ pr.pull_request.number},
    title: -> (pr){ pr.pull_request.title },
    user_login: -> (pr){ pr.pull_request.user.login },
    created_at: -> (pr){ pr.pull_request.created_at },
    closed_at: -> (pr){ pr.closed_at },
    merged_at: ->  (pr){ pr.merged_at },
    merged_in: ->  (pr){ pr.pull_request.merged },
    commits: -> (pr) { pr.pull_request.commits },
    additions: -> (pr) { pr.pull_request.additions },
    deletions: -> (pr) { pr.pull_request.deletions },
    comments: -> (pr) { pr.pull_request.comments },
    chonged_files: -> (pr) { pr.pull_request.changed_files },
    first_commit: -> (pr) { pr.first_commit },
    last_commit: -> (pr) { pr.commits.last[:commit][:committer][:date] },
    number_of_commiters: -> (pr) { pr.commits.uniq{|c| c[:commit][:committer][:email] }.size },
    people_involved: -> (pr) { pr.comments.uniq{|c| c[:user][:login] }.size },
    cycle_time_in_seconds: -> (pr) { pr.cycle_time },
    cycle_time_in_days: -> (pr) { pr.cycle_time / (60*60*24) },
  }

  attr_reader :pull_request
  def initialize(pull_request)
    @pull_request = pull_request
  end

  def self.header
    RECORD_DEF.keys
  end

  def to_a
    serialize.values
  end

  def serialize
    RECORD_DEF.inject({}) do |h, arry|
      h[arry.first] = arry.last.call(self)
      h
    end
  end

  def closed_at
    @pull_request.closed_at
  end

  def cycle_time
    @cycle_time ||= (merged_at || closed_at) - first_commit
  end

  def first_commit
    commits.first[:commit][:committer][:date]
  end

  def merged_at
    @pull_request.merged_at
  end

  def commits
    @commits ||= @pull_request.rels[:commits].get.data
  end

  def comments
    @comments ||= @pull_request.rels[:comments].get.data
  end
end

class QuickCache
  def initialize(file_name)
    @file_name = file_name
    @cache = if File.exists?(file_name)
      read_from_file
    else
      Array.new
    end
  end

  def add(number)
    @cache << number
    flush
  end

  def has?(number)
    @cache.include?(number)
  end

  private
  def read_from_file
    @cache = Marshal.load(File.read(@file_name))
  end

  def flush
    File.open(@file_name, 'w') do |f|
      f.write(Marshal.dump(@cache))
    end
  end
end

# credentials in ~/.netrc
require 'netrc'

#machine api.github.com
  #login sparrovv
  #password .....

client = Octokit::Client.new(:netrc => true)
client.auto_paginate = !!ENV["IMPORT_ALL"] || false # for testing
closed_pull_requests = client.pulls 'simplybusiness/chopin', :state => 'closed'

logger = Logger.new("log/github.log")
logger.level = Logger::INFO
repo = client.repo 'simplybusiness/chopin'
rel = repo.rels[:pulls]
cache = QuickCache.new('cache.log')

logger.info('start importing')
CSV.open("pull_requests.csv", "wb") do |csv|

  csv << PullRequestRecord.header
  closed_pull_requests.each do |pr|
    number = pr[:number]
    if cache.has?(number)
      logger.info("PR number: #{number} is cached, skipping")
      next
    end

    logger.info("Fetching PR number: #{number}")
    npr = rel.get(:uri => {:number => number}).data
    record = PullRequestRecord.new(npr)

    logger.debug("Writing to file: #{number}")
    csv << record.to_a

    cache.add(number)
  end

end
