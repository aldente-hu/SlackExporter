require_relative 'slack'
require_relative 'mattermost'


def upload_files(files_info, dry_run = false)
  files_info.map do |file_info|
    response = Mattermost.upload_file(file_info[0], file_info[1])
    p response
    if response.is_a?(Integer)
      puts response
      response
    else
      puts "OKOK"
      p response["file_infos"]
      response["file_infos"][0]['id']
    end
  end
  # Mattermost側のファイルIDの配列を返す．
end


def export_diary(channel, diary, user_name, file_ids, dry_run = false)
  new_message = "**#{user_name}** さんが日記を投稿しました。 #{Time.at(diary.ts.to_f).localtime("+09:00")}\n> #{diary.text.gsub(/\n/, "\n>")}"

  if dry_run
    p new_message
  else
    Mattermost.post_message(channel, new_message, file_ids)
  end

end


slack = SlackExport.new
mattermost = MatterMost.new(ENV['MM_USER_ACCESS_TOKEN'])

messages = slack.conversations_history(ENV['SLACK_CHANNEL_ID'], Time.now - 3600) # check latest 1 hour.

messages.each do |message|
  user = slack.get_user_name(message.user)
  files_info = slack.get_attached_files_info(message)

  file_ids = upload_files(files_info)
  export_diary(ENV['MM_CHANNEL_ID'], diary, user, false)
end
