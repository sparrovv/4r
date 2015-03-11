# Holds the defitnion of the record
class PullRequestRecord
  ATTRIBUTES = {
    number: -> (pr){ pr.pull_request.number},
    title: -> (pr){ pr.pull_request.title },
    user_login: -> (pr){ pr.user_login},
    created_at: -> (pr){ pr.created_at },
    closed_at: -> (pr){ pr.closed_at },
    merged_at: ->  (pr){ pr.merged_at },
    merged_in: ->  (pr){ pr.pull_request.merged },
    commits: -> (pr) { pr.pull_request.commits },
    additions: -> (pr) { pr.pull_request.additions },
    deletions: -> (pr) { pr.pull_request.deletions },
    comments: -> (pr) { pr.pull_request.comments },
    chonged_files: -> (pr) { pr.pull_request.changed_files },
    first_commit: -> (pr) { pr.first_commit },
    last_commit: -> (pr) { pr.last_commit },
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
    ATTRIBUTES.keys
  end

  def to_csv
    serialize.values
  end

  def serialize
    ATTRIBUTES.inject({}) do |h, arry|
      h[arry.first] = arry.last.call(self)
      h
    end
  end

  def created_at
    @pull_request.created_at
  end

  def closed_at
    @pull_request.closed_at
  end

  def cycle_time

    @cycle_time ||= (merged_at || closed_at) - first_commit
  end

  def last_commit
    return closed_at if commits.last.nil? # it really happens

    commits.last[:commit][:committer][:date]
  end

  def first_commit
    return created_at if commits.first.nil? # it really happens

    commits.first[:commit][:committer][:date]
  end

  def user_login
    @pull_request.user.try(:login) || "NO-USER" # it has happened that there was not user
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
