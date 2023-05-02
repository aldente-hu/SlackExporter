require 'net/http'
require 'json'

class Mattermost

  def initialize(access_token)
    @access_token = access_token # This was ENV['MM_USER_ACCESS_TOKEN']
  end

  # ENV['MM_CHANNEL_ID']
  def post_message(channel, message, root_id = nil, file_ids = [])
    url = URI.parse("https://mattermost.eng-eng.group/api/v4/posts")
    body = {"channel_id" => channel, "message" => message}
    if root_id
      body["root_id"] = root_id
    end
    if !file_ids.empty?
      body["file_ids"] = file_ids
    end

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.start { |session|
      response = session.post(url.request_uri, body.to_json, { 'ContentType' => 'application/json', 'Authorization' => "Bearer #{@access_token}" })
      code = response.code.to_i
      if (200...300) === code
        puts code
      else
        puts response.body
      end
    }
  end
  #module_function :post_message

  def upload_file(channel, local_path, mimetype)
    url = URI.parse("https://mattermost.eng-eng.group/api/v4/files")
    File.open(local_path) { |file|
      data = [ ["channel_id", channel], ["files" ,  file ] ]
      #query = "channel_id=#{ENV['MM_CHANNEL_ID']}&filename=#{File.basename(local_path)}"
      #url.query = query

      body = File.read(local_path)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.start { |session|
        req = Net::HTTP::Post.new(url.request_uri)
        req.set_form(data, "multipart/form-data")
        req['Authorization'] = "Bearer #{@access_token}"
        response = session.request(req)

        #response = session.post(url.request_uri, body, { 'ContentType' => mimetype, 'Authorization' => "Bearer #{ENV['MM_USER_ACCESS_TOKEN']}" })
        code = response.code.to_i
        if (200...300) === code
          JSON.parse(response.body)
        else
          code
        end
      }
    }
  end

  #module_function :upload_file

end



#Mattermost.post_message("Post with Ruby code via mattermost api, again.")

