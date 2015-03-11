class PullRequestLoader
  attr_reader :pull_requests
  def initialize(repository_name, logger, api_client)
    @repository_name = repository_name
    @logger = logger
    @api_client = api_client
    @pull_requests = []
    @csv_file_name = "data/#{@repository_name.gsub(/\//, "_")}_prs.csv"
  end

  def load_all!
    @logger.info('Initial loading')

    @pull_requests = @api_client.pulls(@repository_name, :state => 'closed')
    @last_response = @api_client.last_response
    @logger.info('Start iterating')
    CSV.open(@csv_file_name, "wb") do |csv|
      csv << PullRequestRecord.header
      _load_all(csv)
    end
  end

  private
  def load_pr(pr)
    tries ||= 2
    @logger.info("Fetching PR number: #{pr[:number]}")
    record = PullRequestRecord.new(
      rel.get(:uri => {:number => pr[:number]}).data
    )
    record.to_csv
  rescue Octokit::TooManyRequests => e
    @logger.warn("Rate limit exception: #{e.message}")
    p "Hourly rate limit exceeded! Please wait and resume in 1.hour"
    sleep 60*60 #1.hour
    retry unless (tries -= 1).zero?
  end

  def _load_all(csv)
    pull_requests.each do |pr|
      begin
        csv << load_pr(pr)
      rescue Octokit::InternalServerError => e
        # Can't do much about it, just continue
        @logger.warn("Internal github error: #{e.message}")
      end
    end

    load_more! # what will happen if it reaches end?

    unless pull_requests.empty?
      _load_all(csv)
    end
  end

  def rel
    @rel ||= @api_client.repo(@repository_name).rels[:pulls]
  end

  def load_more!
    @logger.info('Loading more')
    @last_response = @last_response.rels[:next].get
    @pull_requests = @last_response.data
  end
end
