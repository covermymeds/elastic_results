module ElasticResults
  # A common data format for test results.  The Cucumber and Rspec formatters populate this class.
  class Result
    attr_accessor :outcome, :exception_class, :exception_msg, :exception_stacktrace, :runtime
    attr_accessor :id, :uri, :feature_name, :scenario_name, :build_number

    def to_hash
      result_hash = base_info

      [:outcome, :exception_class, :exception_msg, :exception_stacktrace, :runtime,
       :id, :uri, :feature_name, :scenario_name, :tags].each do |field|
        result_hash[field] = send field
      end
      result_hash
    end

    def tags
      @tags ||= []
    end

    def outcome
      @outcome ||= exception_class.nil? ? 'pass' : fail_type
    end

    def fail_type
      exception_class =~ /ExpectationNotMet/ ? :fail : :broke
    end

    def base_info
      {
        '@timestamp' => Time.now.iso8601(3),
        build_number: ENV['BUILD_NUMBER'] ? ENV['BUILD_NUMBER'] : ElasticResults.build_id,
        build_url: ENV['BUILD_URL'],
        node_name: ENV['NODE_NAME'] ? ENV['NODE_NAME'] : Socket.gethostname,
        job_name: ENV['JOB_NAME'],
        build_tag: ENV['BUILD_TAG'],
        environment: ENV['TEST_ENV'] || ENV['RAILS_ENV'],
        git_commit: ElasticResults.git_commit,
        git_url: ElasticResults.git_url,
        git_branch: ElasticResults.git_branch,
        suite_name: ElasticResults.suite_name,
        suite_type: ElasticResults.suite_type,
        team: ElasticResults.team_name
      }
    end
  end
end
