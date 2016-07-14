module RedditJapanStats
  class DataFetcher
    COMPLAINT_SEARCH_URL = "https://www.reddit.com/r/japanlife/search.json?q=Weekly+Complaint+Thread+author%3AAutoModerator&sort=new&restrict_sr=on&limit=100&t=all"
    COMPLAINT_TITLE_REGEX = /Weekly Complaint Thread - /
    PRAISE_SEARCH_URL = "https://www.reddit.com/r/japanlife/search.json?q=Weekly+Praise+Thread+author%3AAutoModerator&sort=new&restrict_sr=on&limit=100&t=all"
    PRAISE_TITLE_REGEX = /Weekly Praise Thread - /

    attr_accessor :thread_type

    # type: ["complaint", "praise"]
    def initialize(thread_type: "complaint")
      @thread_type = thread_type
    end

    private

    def title_regex
      case thread_type
      when "complaint" then COMPLAINT_TITLE_REGEX
      else PRAISE_TITLE_REGEX
    end
  end
end

