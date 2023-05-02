require 'slack-ruby-client'
require 'open-uri'
#require_relative 'mattermost'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

class SlackExport

  def initilaize
    @client = ::Slack::Web::Client.new
  end

  def conversations_history(channel, after)
    #res = @client.conversations_history(channel: ENV['SLACK_CHANNEL_ID'], oldest: after.to_f)
    res = @client.conversations_history(channel: channel, oldest: after.to_f)
    res.messages
  end

  def conversations_replies(channel, ts)
    #res = @client.conversations_replies(channel: ENV['SLACK_GRAMMAR_CHANNEL'], ts: ts)
    res = @client.conversations_replies(channel: channel, ts: ts)
    res.messages
  end

  def get_attached_files_info(message)
    if message.files
      files_info = message.files.map do |file|
        #p file
        #puts "\t*** #{file.url_private_download} ***"
        filename = File.basename(file.url_private_download)
        destination = "/tmp/#{filename}"
        uri = URI.parse(file.url_private_download)
        http = Net::HTTP.new(uri.host, uri.port) 
        http.use_ssl = true
        res = http.get(uri.request_uri, { "Authorization" => "Bearer #{ENV['SLACK_API_TOKEN']}" })
        puts res.code
        if (200...300) === res.code.to_i
          File.open(destination, 'w+b') { |t_file|
            t_file << res.body
          }
        end

        [destination, file.mimetype]
      end

      p files_info

      if (files_info.any?{ |id| id.is_a?(Integer) })
        puts "Failed to upload files."
        return nil
      else 
        files_info
      end
    else 
      []
    end
  end

  def get_user_name(user_id)
    #user_id = message.user
    user_res = @client.users_info(user: user_id)
    if (user_res.ok)
      user = user_res.user.profile.display_name
    else
      p user_res
      nil
    end
  end

end

