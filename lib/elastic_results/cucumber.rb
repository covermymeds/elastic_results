require 'cucumber/formatter/gherkin_formatter_adapter'
require 'gherkin/formatter/argument'
require 'gherkin/formatter/json_formatter'
require 'elastic_results'
require 'elasticsearch'
require 'time'
require 'socket'

module ElasticResults
  # Namespace for cucumber related stuff
  module Cucumber
    # Replacement for the stock Json formatter that outputs to elasticsearch
    class JSONFormatter < ::Gherkin::Formatter::JSONFormatter
      def initialize
        @feature_hashes = []
        @current_step_or_hook = nil
      end

      def eof
        feature_hash = @feature_hashes.last
        feature_hash['elements'].each do |scenario_hash|
          record_scenario feature_hash, scenario_hash
        end
      end

      def done
        ElasticResults.write_urls
      end

      private

      def record_scenario(feature_hash, scenario_hash)
        ElasticResults.index_result result_for(feature_hash, scenario_hash)
      end

      def result_for(feature_hash, scenario_hash)
        Result.new.tap do |res|
          res.id = scenario_hash['id']
          res.feature_name = feature_hash['name']
          res.scenario_name = scenario_hash['name']
          res.uri = feature_hash['uri']


          res.tags.append(feature_hash['tags'].map { |t| t['name'] }) unless feature_hash['tags'].nil?


          res.tags.append(scenario_hash['tags'].map { |t| t['name'] }) unless scenario_hash['tags'].nil?

          # Cucumber stores times in nanoseconds for each step, because that's SUPER useful!
          res.runtime = scenario_hash['steps'].map { |s| s['result']['duration'] }.reduce { |a, e| a + e } / 1_000_000_000.0

          failing_step = scenario_hash['steps'].find { |step| !step['result'].nil? && step['result']['status'] == :failed }
          unless failing_step.nil?
            res.exception_msg = failing_step['result']['error_message']
            res.exception_class = res.exception_msg =~ /ExpectationNotMetError/ ? 'ExpectationNotMetError' : 'RuntimeError'
            res.exception_stacktrace = "#{failing_step['name']}\n#{failing_step['match']['location']}"
          end
        end
      end
    end

    # A format adapter that uses our special JSON formatter
    class Formatter < ::Cucumber::Formatter::GherkinFormatterAdapter
      def initialize(_runtime, _io, options)
        options[:expand] = true
        super(ElasticResults::Cucumber::JSONFormatter.new, false, options)
      end
    end
  end
end
