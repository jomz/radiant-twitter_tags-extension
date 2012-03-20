module TwitterTags
  include Radiant::Taggable
  include ActionView::Helpers # for auto_link

  desc "Creates an context for the twitter functionality" 
  tag "twitter" do |tag|
    # we need a user in the user attribute
    raise StandardError::new('the twitter-tag needs a username in the user attribute') if tag.attr['user'].blank?
    tag.locals.user = tag.attr['user']
    tag.expand
  end

  desc "Creates the loop for the tweets - takes count and order optionally"
  tag "twitter:tweets" do |tag|
    count = (tag.attr['count'] || 10).to_i # reminder: "foo".to_i => 0
    order = (tag.attr['order'] || 'desc').downcase
    
    raise StandardError::new('the count attribute should be a positive integer') unless count > 0
    raise StandardError::new('the order attribute should be "asc" or "desc"') unless %w{asc desc}.include?(order)

    # iterate over the tweets
    result = []
    if tag.attr['list']
      Twitter.list_timeline(tag.locals.user, tag.attr['list'])[0..(count.to_i - 1)].each do |tweet|
        tag.locals.tweet = tweet
        tag.locals.author = tweet.user.screen_name
        tag.locals.author_avatar_url = tweet.user.profile_image_url
        result << tag.expand
      end
    else
      Twitter.user_timeline(tag.locals.user)[0..(count -1)].each do |tweet|
        tag.locals.tweet = tweet
        tag.locals.author_avatar_url = tweet.profile_image_url
        result << tag.expand
      end
    end
    
    result.flatten.join('')
  end
  
  desc "Creates the context within which the tweet can be examined"
  tag "twitter:tweets:tweet" do |tag|
    tag.expand
  end
  
  desc "Returns the text from the tweet"
  tag "twitter:tweets:tweet:text" do |tag|
    tweet = tag.locals.tweet
    auto_link tweet['text']
  end

  desc "Returns the date & time from the tweet"
  tag "twitter:tweets:tweet:date" do |tag|
    tweet = tag.locals.tweet
    format = (tag.attr['format'] || "%H:%M %b %d")
    tweet['created_at'].to_time.strftime(format)
  end

  desc "Returns the url from the tweet"
  tag "twitter:tweets:tweet:url" do |tag|
    tweet = tag.locals.tweet
    
    "http://www.twitter.com/#{tag.locals.user}/statuses/#{tweet['id']}"
  end
  
  desc "Returns the twitter username of the current tweet (only makes sense when iterating tweets from a list)"
  tag "twitter:tweets:tweet:author" do |tag|
    tag.locals.author
  end
  
  desc "Returns the url to the user's avatar"
  tag "twitter:tweets:tweet:avatar" do |tag|
    tag.locals.author_avatar_url
  end
end
