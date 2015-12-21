# ElasticResults

Store the results of your test runs in Elasticsearch via custom formatters.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elastic_results', git: 'git@git.innova-partners.com:testing/elastic_results.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elastic_results

## Cucumber Usage
Add this line to your features/support/env.rb file:
```ruby
require 'elastic_results/cucumber'
```

Tell cucumber to use elastic_results:
```
bundle exec cucumber  --format ElasticResults::Cucumber::Formatter
```

Tell cucumber to use elastic_results but still give normal output:
```
bundle exec cucumber --format pretty --format ElasticResults::Cucumber::Formatter -o /dev/null
```

Make this the default by adding the following to config/cucumber.yml
```
default: --format pretty --format ElasticResults::Cucumber::Formatter -o /dev/null
```

## RSpec Usage
Add this line to your spec_helper.rb file:
```ruby
require 'elastic_results/rspec'
```

Tell rspec to use elastic_results:
```
bundle exec rspec -r 'elastic_results/rspec'  --format ElasticResults::RSpec::Formatter
```

Tell rspec to use elastic_results but still give normal output:
```
bundle exec rspec -r 'elastic_results/rspec'  --format ElasticResults::RSpec::Formatter --format progress
```

Make this the default by adding the following to spec_helper.rb
```ruby
RSpec.configure do |config|
  config.add_formatter 'ElasticResults::RSpec::Formatter'
  config.add_formatter 'progress'
  # the rest of your rspec configuration
end
```
Then run rspec as normal.


## SimpleCov Usage
Add this lines to your spec_helper.rb file:
```ruby
require 'elastic_results/simplecov'
SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, ElasticResults::SimpleCov::Formatter]
```
Then run simplecov as normal.



## Configuration
elastic_results exposes several configuration points that can be set via environment variables or by accssing them on the ElasticResults module:

| ENV                | ElasticResults    | Default                                       | Notes                                                                                                                             |
|--------------------|-------------------|-----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| ES_URL             | es_url            | http://localhost                              | The URL where elasticsearch can be reached                                                                                        |
| ES_INDEX_RESULT    | es_index_result   | test_results-YYYY-MM-DD                       | The index to post test results to.  The default uses a prefix of test_results and a suffix of today's date                        |
| ES_TYPE_RESULT     | es_type_result    | test_result                                   | The data type to use for test results.                                                                                            |
| ES_INDEX_COVERAGE  | es_index_coverage | coverage-YYYY-MM-DD                           | The index to post coverage data to. The default uses a prefix of coverage and a suffix of today's date                            |
| ES_TYPE_COVERAGE   | es_type_coverage  | simplecov                                     | The data type to use for coverage data.                                                                                           |
| ES_LOG             | es_log            | ENV['DEBUG']                                  | Log calls to elasticsearch to STDOUT? (useful for debugging elastic_results)                                                      |
| SUITE_NAME         | suite_name        | Dir.pwd                                       | The name of your suite.  If not given, it will be guessed using the name of the current folder when you launch your tests.        |
| SUITE_TYPE         | suite_type        | integration                                   | The type of suite you're running. i.e. unit, integration, regression, etc                                                         |
| GIT_COMMIT         |                   | Output of: git rev-parse HEAD                 | The git revision being tested.  Jenkins will set this in CI, otherwise it's pulled from git.                                      |
| GIT_URL            |                   | Output of: git config --get remote.origin.url | The url to the git repo being used.  Jenkins will set this in CI, otherwise it's pulled from git.                                 |
| GIT_BRANCH         |                   | Output of: git rev-parse --abbrev-ref HEAD    | The git branch being used.  Jenkins will set this in CI, otherwise it's pulled from git.                                          |
| TEAM_NAME          | team_name         | ???                                           | The name of your team.  This makes it possible to slice your results easier.                                                      |
| BUILD_URL          |                   |                                               | The url to your Jenkins build if any.  Set by Jenkins.                                                                            |
| NODE_NAME          |                   | Socket.gethostname                            | The node that ran the test.  Set by Jenkins, or pulled from the machine.                                                          |
| BUILD_NUMBER       |                   | MMDDYYHHMMSSUU                                | The jenkins build number.  If not present, a fake build number will be built using the current date/time down to the millisecond. |
| JOB_NAME           |                   |                                               | The jenkins job name.                                                                                                             |
| BUILD_TAG          |                   |                                               | The jenkins build tag.                                                                                                            |
| TEST_ENV/RAILS_ENV |                   |                                               | The enivironment the tests were run against.  Will use TEST_ENV if present, otherwise will use RAILS_ENV                          |
|                    | use_unsafe_index  | true if WebMock is defined, otherwise false   | If true, validation of the SSL cert for the elasticsearch host will be skipped.  Useful when your testing tools break things.     |


## Example config block:
```ruby
ElasticResults.team_name = 'MyTeam - MySubTeam'
ElasticResults.suite_type = 'unit'
ElasticResults.kibana_url = 'https://kibana.mycompany.com'
ElasticResults.es_url =  %w(https://es1.mycompany.net:9200 https://es1.mycompany.net:9200).sample
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/elastic_results.

