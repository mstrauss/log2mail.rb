def parse_configtest_output( txt )
  rows = []; keys = nil
  first_line = true
  txt.each_line do |line|
    next if line =~ /[+-]+/
    if first_line
      keys = line.split('|').map(&:strip) - ['|', '']
      first_line = false
    else
      values = line.split('|').map(&:strip) - ['|', '']
      rows << Hash[keys.zip(values)]
    end
  end
  rows
end

Given(/^I use mode "(.*?)"$/) do |mode|
  @mode = mode
end

Given(/^config "(.*?)"$/) do |config|
  @config = config
end

Given(/^parameter "(.*?)"$/) do |args|
  @args = args
end

When(/^log(\d+)mail is run$/) do |arg1|
  @output = `bundle exec bin/log2mail.rb #{@mode} --config features/log2mail_configurations/#{@config} #{@args}`
  # puts @output.inspect
  # puts parse_configtest_output(@output).inspect
end

Then(/^the output should be:$/) do |table|
  # table is a Cucumber::Ast::Table
  table.map_headers!
  table.map_column!(:Settings) { |cell| cell.empty? ? nil : cell } \
    if table.hashes.first[:Settings]
  table.diff! parse_configtest_output(@output), :surplus_col => true
end
