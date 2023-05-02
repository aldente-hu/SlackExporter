require_relative 'slack'



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