require 'elastic_results/version'
require 'elastic_results/result'
require 'elasticsearch'
require 'json'

require "net/https"
require "uri"

require 'time'
require 'socket'



# Our root namespace for all objects
module ElasticResults
  class << self
    attr_accessor :suite_name
    attr_accessor :suite_type
    attr_accessor :es_url
    attr_accessor :es_index_result
    attr_accessor :es_index_coverage
    attr_accessor :es_type_result
    attr_accessor :es_type_coverage
    attr_accessor :es_log
    attr_accessor :team_name
    attr_accessor :build_id
    attr_accessor :google_api_key
    attr_accessor :kibana_url
    attr_accessor :use_unsafe_index
  end

  # Return the mapping JSON for used in creating indicies
  # the which paramter should map to to a filename in the setup folder
  def self.mapping_for(which)
    setup_folder = File.expand_path('./elastic_results/setup', File.dirname(__FILE__))
    File.read("#{setup_folder}/#{which.to_s}.json")
  end

  # Memoized instance of the elasticsearch client
  def self.client
    @@client ||= Elasticsearch::Client.new url: ElasticResults.es_url, log: ElasticResults.es_log
  end

  # Given a payload store it as a test result
  def self.index_result(payload)
    index ElasticResults.es_index_result, ElasticResults.es_type_result, payload
  end

  # Given a payload store it as coverage data
  def self.index_coverage(payload)
    index ElasticResults.es_index_coverage,  ElasticResults.es_type_coverage, payload
  end

  # Generic index function that knows when to use the elasticsearch API.
  def self.index(index, type, payload)
    begin
      with_disabled_mocks {
        if ElasticResults.use_unsafe_index
          unsafe_index index, type, payload.to_hash
        else
          client.index index: index, type: type, body: payload.to_hash
        end
      }
    rescue Exception => ex
      puts "#{ex.message} while storing results in Elasticsearch"
    end


  end

  # An "unsafe" index routine which uses Net:HTTP with SSL validation turned off.  Needed for when WebMock is in use
  # as it breaks SSL cert validations.
  def self.unsafe_index(index, type, payload)
    uri = URI.parse(ElasticResults.es_url)
    http = Net::HTTP.new(uri.host, uri.port)

    if ElasticResults.es_url =~ /https/
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Post.new("/#{index}/#{type}")
    request.body = payload.to_json
    response = http.request(request)
  end

  # Write out a tab deliminated file containing links to the build information
  def self.write_urls(filename = 'build_links.txt')
    File.open(filename, 'w') { |file| file.write("View failures in Kibana\t#{ElasticResults.fails_url}\t\nView all results in Kibana\t#{ElasticResults.results_url}\t") }
  end

  # Returns a link to the results. shortened URL if possible otherwise the full URL from long_results_url.
  def self.results_url
    if ElasticResults.google_api_key.nil?
      long_results_url
    else
      require 'googl'
      Googl.shorten(long_results_url, '127.0.0.1', ElasticResults.google_api_key).short_url
    end
  end

  # Returns a link to the failures. shortened URL if possible otherwise the full URL from long_fails_url.
  def self.fails_url
    if ElasticResults.google_api_key.nil?
      long_fails_url
    else
      require 'googl'
      Googl.shorten(long_fails_url, '127.0.0.1', ElasticResults.google_api_key).short_url
    end
  end


  # Set up defaults for the meta data
  ElasticResults.team_name ||= ENV['TEAM_NAME'].nil? ? '???' : ENV['TEAM_NAME']
  ElasticResults.suite_name ||= ENV['SUITE_NAME'].nil? ? File.basename(Dir.pwd) : ENV['SUITE_NAME']
  ElasticResults.suite_type ||= ENV['SUITE_TYPE'].nil? ? 'integration' : ENV['SUITE_TYPE']
  ElasticResults.es_url ||= ENV['ES_HOST'].nil? ? 'http://localhost' : ENV['ES_HOST']
  ElasticResults.es_index_result ||= ENV['ES_INDEX_RESULT'].nil? ? "test_results-#{DateTime.now.strftime('%F')}" : ENV['ES_INDEX_RESULT']
  ElasticResults.es_type_result ||= ENV['ES_TYPE_RESULT'].nil? ? 'test_result' : ENV['ES_TYPE_RESULT']
  ElasticResults.es_log ||= ENV['DEBUG'].nil? ? false : true
  ElasticResults.build_id ||= DateTime.now.strftime('%Y%m%d%H%M%S%L')
  ElasticResults.es_index_coverage ||= ENV['ES_INDEX_COVERAGE'].nil? ? "coverage-#{DateTime.now.strftime('%F')}" : ENV['ES_INDEX_COVERAGE']
  ElasticResults.es_type_coverage ||= ENV['ES_TYPE_COVERAGE'].nil? ? 'simplecov' : ENV['ES_TYPE_COVERAGE']
  ElasticResults.google_api_key ||= ENV['GOOGLE_API_KEY']
  ElasticResults.kibana_url ||= ENV['KIBANA_URL'].nil? ? 'http://localhost:5601' : ENV['KIBANA_URL']
  ElasticResults.use_unsafe_index ||= defined?(WebMock) ? true : false


  private
  # Returns a full link to the discover page showing the test results for the current build
  def self.long_results_url
    build_id =  ENV['BUILD_NUMBER'] ? ENV['BUILD_NUMBER'] : ElasticResults.build_id
    "#{ElasticResults.kibana_url}/#/discover/?_g=(refreshInterval:(display:Off,pause:!f,section:0,value:0),time:(from:now%2Fd,mode:quick,to:now%2Fd))&_a=(columns:!(team,suite_name,build_number,environment,runtime,outcome,feature_name,scenario_name,exception_class,exception_msg,exception_stacktrace),filters:!(),index:'test_results-*',interval:auto,query:(query_string:(analyze_wildcard:!t,query:'build_number:#{build_id}')),sort:!('@timestamp',desc))"
  end

  # Returns a full link to the discover page showing the test failures for the current build
  def self.long_fails_url
    build_id =  ENV['BUILD_NUMBER'] ? ENV['BUILD_NUMBER'] : ElasticResults.build_id
    "#{ElasticResults.kibana_url}/#/discover/?_g=(refreshInterval:(display:Off,pause:!f,section:0,value:0),time:(from:now%2Fd,mode:quick,to:now%2Fd))&_a=(columns:!(team,suite_name,build_number,environment,runtime,outcome,feature_name,scenario_name,exception_class,exception_msg,exception_stacktrace),filters:!(),index:'test_results-*',interval:auto,query:(query_string:(analyze_wildcard:!t,query:'build_number:#{build_id}%20AND%20(outcome:broke%20OR%20outcome:fail)')),sort:!('@timestamp',desc))"
  end

  # Memoize the git_commit to avoid hitting git for each result
  def self.git_commit
    @@git_commit ||= ENV['GIT_COMMIT'] ? ENV['GIT_COMMIT'] : `git rev-parse HEAD`.chomp
  end

  # Memoize the git_url to avoid hitting git for each result
  def self.git_url
    @@git_url ||= ENV['GIT_URL'] ? ENV['GIT_URL'] : `git config --get remote.origin.url`.chomp
  end

  # Memoize the git_branch to avoid hitting git for each result
  def self.git_branch
    @@git_branch ||= ENV['GIT_BRANCH'] ? ENV['GIT_BRANCH'] : `git rev-parse --abbrev-ref HEAD`.chomp
  end

  # Helper function to disable mocks before calling out to the web (and getting blocked)
  def self.with_disabled_mocks
    should_reenable_webmock = false
    if defined? WebMock
      if !WebMock.net_connect_allowed?
        should_reenable_webmock = true
        WebMock.disable!
      end
    end

    if defined? VCR
      VCR.turned_off {
        yield
      }
    else
      yield
    end

    if should_reenable_webmock
      WebMock.enable!
    end
  end
end
