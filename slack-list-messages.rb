require_relative 'slack'

if (ARGV.size < 1)
    puts "Usage: ruby slack-list-messages.rb channel_id"
    return
end


slack = SlackExport.new

# タイムスタンプと冒頭50字を出力する．
slack.conversations_history(ARGV[0]).each do |message|
    puts "#{message.ts}  #{message.text[0...50]}"
end

