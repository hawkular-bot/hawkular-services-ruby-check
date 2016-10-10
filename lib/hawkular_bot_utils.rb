class HawkularBotUtils
  RUBY_SUCCEEDED_MESSAGE = '---Ruby tests succeeded---'.freeze
  RUBY_FAILED_MESSAGE = '---Ruby tests failed---'.freeze

  STATUS_UNKNOWN = :unknown
  STATUS_SUCCESS = :success
  STATUS_FAILED = :failed

  def self.status_unknown
    STATUS_UNKNOWN
  end

  def self.status_success
    STATUS_SUCCESS
  end

  def self.status_failed
    STATUS_FAILED
  end

  def self.parse_pull_url url
    pr = URI(url).path.split('/').last
    return pr if pr =~ /^\d+$/
    nil
  end

  def self.ruby_test_status build_log
    if build_log.include? RUBY_SUCCEEDED_MESSAGE
      STATUS_SUCCESS
    elsif build_log.include? RUBY_FAILED_MESSAGE
      STATUS_FAILED
    else
      STATUS_UNKNOWN
    end
  end
end
