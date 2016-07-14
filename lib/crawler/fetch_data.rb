require "data_fetcher"

# actually fetch the data from reddit and store in DB
# parse command_line args
cmd_line_args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]

# fetch URLs
crawl_urls = RedditJapanStats::DataFetcher.new(type: .fetch_crawl_urls
# fetch data for each URL
# store in DB
