require_relative 'slack'
require_relative 'mattermost'


def generate_message(post, user_name)
  new_message = "**#{user_name}** さん： #{Time.at(post.ts.to_f).localtime("+09:00")}\n> #{post.text.gsub(/\n/, "\n>")}"
end



slack = SlackExport.new
mattermost = Mattermost.new(ENV['MM_USER_ACCESS_TOKEN'])

# 特定の投稿と返信を拾う．
messages = slack.conversations_replies(ENV['SLACK_CHANNEL_ID'], ARGV[0])

root = messages.first

# ユーザ情報をまとめて取得しておく．
users = root["reply_users"]
user_names = Hash.new { |hash, key|
  hash[key] = slack.get_user_name(key)
}
files_info = slack.get_attached_files_info(root)

file_ids = upload_files(ENV['MM_CHANNEL_ID'], files_info) # dry-runは未考慮．
if !file_ids
  puts "アップロードに失敗したファイルがあります．"
  return
end

res = mattermost.post_message(ENV['MM_CHANNEL_ID'], generate_message(root, user_names[root.user]), nil, file_ids)
if res["status_code"]
  puts res
  return
end
root_id = res["id"]
puts "Root ID: #{root_id}"

messages[1..-1].each do |message|
  user = slack.get_user_name(message.user)
  files_info = slack.get_attached_files_info(message)
  file_ids = upload_files(ENV['MM_CHANNEL_ID'], files_info)

  res = mattermost.post_message(ENV['MM_CHANNEL_ID'], generate_message(message, user_names[message.user]), root_id, file_ids)
  puts res
end
