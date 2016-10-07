require 'sinatra'
require 'json'
require 'rest_client'
require 'uri'
require_relative 'lib/hawkular_bot_utils'

GITHUB_URL = 'https://api.github.com'.freeze
TRAVIS_URL = 'https://api.travis-ci.org'.freeze
ENABLED_REPOS = ['hawkular/hawkular-services'].freeze

get '/job/:job' do
  job_id = params['job']
  github_token = ENV['GITHUB_TOKEN']

  travis_client = RestClient::Resource.new(TRAVIS_URL)
  travis_headers = {
    'accept'          => 'application/vnd.travis-ci.2+json',
    'accept-encoding' => 'gzip, deflate',
    'user-agent'      => 'hawkular-bot'
  }
  job = JSON.parse(travis_client["jobs/#{job_id}"].get(travis_headers))
  repo_slug = job['job']['repository_slug']

  unless ENABLED_REPOS.include? repo_slug
    status 500
    return "Unknown repository #{repo_slug}"
  end

  pull = HawkularBotUtils.parse_pull_url job['commit']['compare_url']

  build_log = travis_client["jobs/#{job_id}/log"].get 'accept' => 'text/plain', 'accept-encoding' => 'gzip, deflate'
  ruby_status = HawkularBotUtils.ruby_test_status build_log

  github_message = case ruby_status
                   when :success
                     'This PR seem to be working well with '\
                     '[hawkular-client-ruby](https://github.com/hawkular/hawkular-client-ruby) :+1:.'
                   when :failed
                     'This PR potentially fails with '\
                     '[hawkular-client-ruby](https://github.com/hawkular/hawkular-client-ruby).'
                   else
                     status 500
                     return "Did not detect any Ruby status on #{repo_slug}"
                   end

  github_client = RestClient::Resource.new(GITHUB_URL)
  github_header = {
    Authorization: "token #{github_token}"
  }
  github_comment_body = {
    body: github_message
  }
  github_client["repos/#{repo_slug}/issues/#{pull}/comments"].post(github_comment_body.to_json, github_header)
end
