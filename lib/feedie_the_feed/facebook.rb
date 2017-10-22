require 'koala'

require 'feedie_the_feed/exceptions'

require 'feedie_the_feed/helper_extensions/string'

module FeedieTheFeed
  # This module handles Facebook queries
  module Facebook
    # This hash is used to store default values for things like Facebook posts
    # limit.
    @@defaults = { facebook_posts_limit: 10 }

    private

    def get_facebook_feed(url,
                          facebook_posts_limit,
                          facebook_appid = @facebook_appid_global,
                          facebook_secret = @facebook_secret_global)
      authorise_facebook(facebook_appid, facebook_secret)
      facebook_posts_limit ||= @@defaults[:facebook_posts_limit]
      posts = @fb_graph_api.get_connection(
        get_fb_page_name(url),
        'posts',
        limit: facebook_posts_limit, # max 100
        fields: %w[message id from type picture link created_time]
      )
      formalize_fb_feed_array(posts.to_a)
    end

    def authorise_facebook(facebook_appid, facebook_secret)
      facebook_appid ||= ENV['FACEBOOK_APPID']
      facebook_secret ||= ENV['FACEBOOK_SECRET']
      oauth = Koala::Facebook::OAuth.new(facebook_appid, facebook_secret)

      begin
        access_token = oauth.get_app_access_token
      rescue Koala::Facebook::OAuthTokenRequestError => e
        raise FacebookAuthorisationError.new('Failing to authorise with ' \
          'given facebook_appid and facebook_secret.', e)
      end

      @fb_graph_api = Koala::Facebook::API.new(access_token)
    end

    def get_fb_page_name(url)
      URI.parse(url).path.match(
        %r{\A/([^/]*)}
      )[1]
    end

    def formalize_fb_feed_array(array)
      array.each do |hash|
        hash['entry_id'] = hash.delete('id')
        hash['summary'] = hash.delete('message')
        hash['title'] = hash['summary'].truncate(80) if hash['summary']
        hash['url'] = hash.delete('link')
        hash['published'] = Time.parse(hash.delete('created_time'))
        hash['image'] = hash.delete('picture')
      end
    end
  end
end