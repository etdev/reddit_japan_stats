require_relative "./data_fetcher"

# fetch the data from reddit and store in DB
# parse command_line args
cmd_line_args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]

# fetch URLs
puts "thread_type: #{cmd_line_args['thread_type']}"
fetcher = RedditJapanStats::DataFetcher.new(
  thread_type: cmd_line_args["thread_type"] || "complaint",
  session_cookie: cmd_line_args["reddit_session"] || ""
)

thread_urls = fetcher.fetch_thread_crawl_urls

# fetch data for each URL
# --reddit_session=28881092%2C2016-04-26T08%3A47%3A24%2C7f9442a3be3fc882543b7f3c7bf10384a702d204

threads = thread_urls.each_with_object({}) do |thread_url, threads|
  threads[thread_url] = fetcher.fetch_thread_data(thread_url)
  begin
    sleep(5)
    fetcher.store_thread_data_in_db(
      thread_data: threads[thread_url],
      user: cmd_line_args["user"],
      password: ""
    )
  rescue => e
    puts "Failed to store thread data in DB #{e.message}"
  end
end


# store in DB
