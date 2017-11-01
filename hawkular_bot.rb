require 'sinatra'
require 'json'
require 'rest_client'
require 'uri'
require 'base64'
require_relative 'lib/hawkular_bot_utils'

GITHUB_URL = 'https://api.github.com'.freeze
TRAVIS_URL = 'https://api.travis-ci.org'.freeze
ENABLED_REPOS = ['hawkular/hawkular-services'].freeze

post '/notifications' do
  payload = params[:payload]
  signature = request.env['HTTP_SIGNATURE']
  unless signature_is_valid signature, payload
    status 401
    return 'Invalid signature'
  end
  notification = JSON.parse payload
  repo_slug = "#{notification['repository']['owner_name']}/#{notification['repository']['name']}"
  unless ENABLED_REPOS.include? repo_slug
    status 500
    return "Unknown repository #{repo_slug}"
  end

  unless notification['type'] == 'pull_request'
    status 500
    return 'Only valid for pull-requests'
  end
  commit = notification['commit']

  build_id = notification['id']
  travis_client = RestClient::Resource.new(TRAVIS_URL)
  travis_headers = {
    'accept'          => 'application/vnd.travis-ci.2+json',
    'accept-encoding' => 'gzip, deflate',
    'user-agent'      => 'hawkular-bot'
  }
  build = JSON.parse(travis_client["builds/#{build_id}"].get(travis_headers))
  build_status = HawkularBotUtils.status_unknown
  job_failed_id = nil
  build['build']['job_ids'].each do |job_id|
    job_log = travis_client["jobs/#{job_id}/log"].get 'accept' => 'text/plain', 'accept-encoding' => 'gzip, deflate'
    job_status = HawkularBotUtils.ruby_test_status job_log
    build_status = job_status unless job_status == HawkularBotUtils.status_unknown
    if build_status == HawkularBotUtils.status_failed
      job_failed_id = job_id
      break
    end
  end

  github_status = case build_status
                  when :success
                    {
                      'state'       => 'success',
                      'description' => 'The tests succeeded'
                    }
                  when :failed
                    {
                      'state'       => 'failure',
                      'description' => 'The tests failed',
                      'target_url'  => "https://travis-ci.org/#{repo_slug}/jobs/#{job_failed_id}"
                    }
                  else
                    status 500
                    return "Did not detect any Build status on #{repo_slug}"
                  end
  github_status['context'] = 'hawkular-client-tests/ruby'

  github_client = RestClient::Resource.new(GITHUB_URL)
  github_header = {
    Authorization: "token #{ENV['GITHUB_TOKEN']}"
  }
  github_client["repos/#{repo_slug}/statuses/#{commit}"].post(github_status.to_json, github_header)
end

def signature_is_valid(signature, payload)
  pkey = OpenSSL::PKey::RSA.new(public_key)
  pkey.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(signature), payload)
end

def public_key
  client = RestClient::Resource.new(TRAVIS_URL)
  JSON.parse(client['config'].get)['config']['notifications']['webhook']['public_key']
end
