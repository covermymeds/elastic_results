require 'simplecov'
require 'elastic_results'

module ElasticResults
  module SimpleCov
    # A simple formatter that converts a SimpleCov Result to a hash to be stored in elastic search
    class Formatter
      def format(result)
        data = base_info

        data[:command_name] = result.command_name
        data[:metrics] = {
          covered_percent: result.covered_percent,
          covered_strength: result.covered_strength.nan? ? 0.0 : result.covered_strength,
          covered_lines: result.covered_lines,
          total_lines: result.total_lines
        }

        ElasticResults.with_disabled_mocks {
          if ElasticResults.use_unsafe_index
            ElasticResults.unsafe_index ElasticResults.es_index_coverage, ElasticResults.es_type_coverage, data
          else
            ElasticResults.client.index index: ElasticResults.es_index_coverage, type: ElasticResults.es_type_coverage, body: data
          end
        }
      end

      private

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
end
