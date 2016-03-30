RSpec::Support.require_rspec_core 'formatters/base_formatter'
require 'elastic_results'

module ElasticResults
  module RSpec
    # @private
    class Formatter < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :example_passed, :example_failed, :close

      def initialize(output)
        super
      end

      def example_passed(notification)
        record_example notification.example
      end

      def example_failed(notification)
        record_example notification.example
      end

      def record_example(example)
        ElasticResults.index_result result_for(example)
      end

      def close(_notification)
        ElasticResults.write_urls
      end

      private

      def result_for(example)
        Result.new.tap do |res|
          res.id = example.id
          res.feature_name = example.description
          res.scenario_name = example.full_description
          res.uri = example.location
          res.runtime = example.metadata[:execution_result].run_time
          unless example.exception.nil?
            res.exception_class = example.exception.class.name
            res.exception_msg = example.exception.message
            res.exception_stacktrace = example.exception.backtrace
          end
        end
      end
    end
  end
end
