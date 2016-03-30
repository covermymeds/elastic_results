require 'cucumber/formatter/gherkin_formatter_adapter'
require 'gherkin/formatter/argument'
require 'gherkin/formatter/json_formatter'
require 'elastic_results'
require 'elastic_results/cucumber/reportable'

module ElasticResults
  # Namespace for cucumber related stuff
  # This is specifically for cucumber < 2.0
  module Cucumber
    # Replacement for the stock Json formatter that outputs to elasticsearch
    class LegacyJSONFormatter < ::Gherkin::Formatter::JSONFormatter
      include Reportable

      def initialize
        @feature_hashes = []
        @current_step_or_hook = nil
      end

      def eof
        feature_hash = @feature_hashes.last
        unidrectional_indifferent_hash feature_hash
        feature_hash['elements'].each do |scenario_hash|
          unidrectional_indifferent_hash scenario_hash
          record_scenario feature_hash, scenario_hash
        end
      end
      alias_method :after_features, :eof

      def done
        binding.pry
        ElasticResults.write_urls
      end

      private
      def unidrectional_indifferent_hash(hash)
        return unless hash.is_a? Hash
        symbolize = ->(h, key){ h.key?(key.to_s) ? h[key.to_s] : nil }
        hash.default_proc = symbolize
        hash.each do |_, value|
          unidrectional_indifferent_hash value if value.is_a? Hash
          value.each { |element| unidrectional_indifferent_hash element } if value.is_a? Array
        end
      end
    end

    # A format adapter that uses our special JSON formatter
    class LegacyFormatter < ::Cucumber::Formatter::GherkinFormatterAdapter
      def initialize(_runtime, _io, options)
        options[:expand] = true
        super(ElasticResults::Cucumber::LegacyJSONFormatter.new, false, options)
      end
    end
  end
end
