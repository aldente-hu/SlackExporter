require_relative 'slack'
require_relative 'mattermost'

def upload_files(files_info, dry_run = false)
  files_info.map do |file_info|
    response = Mattermost.upload_file(file_info[0], file_info[1])
    p response
    if response.is_a?(Integer)
      response
    else
      puts "OKOK"
      p response["file_infos"]
      response["file_infos"][0]['id']
    end
  end
  # Mattermost側のファイルIDの配列を返す．
end

def export_root(client, post, dry_run = false)
    file_ids = upload_attached_files(client, post)
    if !file_ids
      puts "Something went wrong."
      return
    end
    user_name = get_user_name(client, post)
    export_message = "**#{user_name}** さんが投稿しました。 #{Time.at(post.ts.to_f).localtime("+09:00")}\n> #{post.text.gsub(/\n/, "\n>")}"
  
    if dry_run
      p export_message
    else
      Mattermost.post_message(export_message, file_ids)
    end
end
  
def export_children(client, post, names = {}, dry_run = false)
end


def export_thread(client, ts, dry_run = false)
    messages = conversations_replies(ts)
    root = messages.first
    # ルート記事を投稿
    export_root()
    messages[1..-1].each do |reply|
      # 返信を投稿

    end


end


def generate_message(post, user_name)
  new_message = "**#{user_name}** さん： #{Time.at(post.ts.to_f).localtime("+09:00")}\n> #{post.text.gsub(/\n/, "\n>")}"
end



slack = SlackExport.new
mattermost = Mattermost.new(ENV['MM_USER_ACCESS_TOKEN'])

# 特定の投稿と返信を拾う．
messages = slack.conversations_history(ENV['SLACK_CHANNEL_ID'], ARGV[0])

root = messages.first

# ユーザ情報をまとめて取得しておく．
users = root["reply_users"]
user_names = Hash.new { |hash, key|
  hash[key] = slack.get_user_name(key)
}
files_info = slack.get_attached_files_info(root)

# dry-runは未考慮．
file_ids = upload_files(files_info)
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
  file_ids = upload_files(files_info)

  res = mattermost.post_message(ENV['MM_CHANNEL_ID'], generate_message(message, user_names[message.user]), root_id, file_ids)
  puts res
end
