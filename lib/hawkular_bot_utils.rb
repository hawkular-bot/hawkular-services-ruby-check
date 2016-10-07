class HawkularBotUtils
  RUBY_SUCCEEDED_MESSAGE = '---Ruby tests succeeded---'.freeze
  RUBY_FAILED_MESSAGE = '---Ruby tests failed---'.freeze

  def self.parse_pull_url url
    pr = URI(url).path.split('/').last
    return pr if pr =~ /^\d+$/
    nil
  end

  def self.ruby_test_status build_log
    if build_log.include? RUBY_SUCCEEDED_MESSAGE
      :success
    elsif build_log.include? RUBY_FAILED_MESSAGE
      :failed
    else
      :unknown
    end
  end
end
