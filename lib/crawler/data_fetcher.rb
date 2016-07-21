require "uri"
require "date"
require "pry"
require "json"
require "open-uri"
require "net/http"
require "sequel"

module RedditJapanStats
  class DataFetcher
    COMPLAINT_SEARCH_URL = "https://www.reddit.com/r/japanlife/search.json?q=Weekly+Complaint+Thread+author%3AAutoModerator&sort=new&restrict_sr=on&limit=100&t=all"
    COMPLAINT_TITLE_REGEX = /Weekly Complaint Thread - /
    PRAISE_SEARCH_URL = "https://www.reddit.com/r/japanlife/search.json?q=Weekly+Praise+Thread+author%3AAutoModerator&sort=new&restrict_sr=on&limit=100&t=all"
    PRAISE_TITLE_REGEX = /Weekly Praise Thread - /
    UA_STRING = "Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0"

    attr_accessor :thread_type
    attr_reader :session_cookie

    def initialize(thread_type: "complaint", session_cookie: "")
      @thread_type = thread_type
      @session_cookie = session_cookie
    end

    def fetch_thread_crawl_urls
      raw_response = fetch_json_from_url(search_url)
      thread_urls = []
      with_default_error_check do
        json_data = JSON.parse(raw_response.body)
        threads = json_data.dig("data", "children").select do |thread|
          thread.dig("data", "title") =~ title_regex
        end
        urls = threads.map{ |thread| thread.dig("data", "url") }
                 .map{ |url| url[0...-1] + ".json?limit=1500" }
      end
    end

    def fetch_thread_data(thread_url)
      fail "No thread urls stored" if thread_url.nil? || thread_url.empty?
      thread = {}
      with_default_error_check do
        raw_response = fetch_json_from_url(thread_url)
        json_data = JSON.parse(raw_response.body)
        created_at = json_data[0]["data"]["children"][0]["data"]["created"]
        comments = find_all_comments(json_data[1]).select{ |x| !x["body"].nil? && x["body"] != "[deleted]" }
        thread = { date: DateTime.strptime(created_at.to_s, "%s"), type: thread_type, comments: comments }
      end
      thread
    end

    def store_thread_data_in_db(thread_data:, user:, password: '')
      puts "Storing thread data for #{thread_data[:date]}"
      db = Sequel.connect(adapter: "postgres", host: "localhost", database: "reddit_japan_stats", user: user, password: password)
      comments_attr_arr = thread_data[:comments]
      # store thread
      thread_data.reject! { |k, v| k == :comments }
      threads, comments = db.from(:threads), db.from(:comments)
      threads.insert(thread_data)
      thread_id = threads.where(date: thread_data[:date]).first[:id]
      # store comments
      comments_attr_arr.each do |comment_attrs|
        comments.insert(comment_attrs.merge("thread_id" => thread_id))
      end
    end


    private

    def fetch_json_from_url(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Cookie'] = "reddit_session=#{session_cookie}"
      request['User-Agent'] = UA_STRING
      http.request(request)
    end

    def title_regex
      case thread_type
      when "complaint" then COMPLAINT_TITLE_REGEX
      else PRAISE_TITLE_REGEX
      end
    end

    def search_url
      case thread_type
      when "complaint" then COMPLAINT_SEARCH_URL
      else PRAISE_SEARCH_URL
      end
    end

    def with_default_error_check
      begin
        yield if block_given?
      rescue => e
        puts "Failed: #{e.message}"
      end
    end

    def find_all_comments(hsh, so_far=[])
      unless hsh.nil?
        hsh.dig("data", "children").each do |child|
          current_comment = Hash[["score", "body", "author"].zip(child["data"].values_at("score", "body", "author"))]
          # if has replies
          unless child.nil?
            if child.dig("data", "replies") != ""
              so_far = find_all_comments(child.dig("data", "replies"), so_far)
            end
          end
          so_far << current_comment
        end
      end
      so_far
    end

    def deep_find_all(hsh, key, so_far=[])
      hsh.each_key do |k|
        if k == "children"
          so_far = deep_find_all(hsh[k], key, so_far)
        else
          so_far << hsh[k] if k == key
        end
      end
      so_far
    end
  end
end

