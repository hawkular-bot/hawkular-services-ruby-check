require 'hawkular_bot_utils'

describe 'hawkular_bot' do
  it 'should parse github pr url' do
    expect(HawkularBotUtils.parse_pull_url('https://github.com/hawkular/hawkular-services/71')).to eq('71')
    expect(HawkularBotUtils.parse_pull_url('https://github.com/josejulio/hawkular-services/80')).to eq('80')
    expect(HawkularBotUtils.parse_pull_url('https://github.com/hawkular/someother_url')).to eq(nil)
  end

  it 'should detect build status as success' do
    build_log = 'bla bla bla bla bla\n+ echo ---Ruby tests succeeded---\nbla bla bla'
    expect(HawkularBotUtils.ruby_test_status(build_log)).to be(:success)
  end

  it 'should detect build status as failed' do
    build_log = 'bla bla bla bla bla\n+ echo ---Ruby tests failed---\nbla bla bla'
    expect(HawkularBotUtils.ruby_test_status(build_log)).to be(:failed)
  end

  it 'should detect build status as unknown' do
    build_log = 'bla bla bla bla bla\nbla bla bla'
    expect(HawkularBotUtils.ruby_test_status(build_log)).to be(:unknown)
  end
end
