module MmCrawler
  class CookieService
    def cookie
      redis.get(key) || get_cookie
    end

    def get_cookie
      new_cookie = relogin

      cache_cookie(new_cookie)
      puts 'new cookie'
      new_cookie
    end

    def relogin
      uri = URI.parse('https://ssl.meetme.com/mobile/login')
      request = Net::HTTP::Post.new(uri)
      request['Host'] = 'ssl.meetme.com'
      request['Accept'] = '*/*'
      request['X-Notificationtypes'] = 'friendAccept,newMatch,boostChat,smileSent,newMemberAlert'
      request['Accept-Language'] = 'en-US-US'
      request['X-Stats'] = '%7B%22memUsed%22%3A%221%22%2C%22memTotal%22%3A%221%22%2C%22methods%22%3A%5B%7B%22key%22%3A%22logout%22%2C%22roundTrip%22%3A%220.1%22%2C%22parse%22%3A%220.000007%22%7D%5D%7D'
      request['User-Agent'] = 'MeetMe/12.4.2 (iPhone; iOS 10.3.3; Scale/2.00)'
      request['X-Counts'] = '0'
      request['X-Supportedfeatures'] = 'chatSuggestions,messageStickers,StackedNotifications:v5,tags,purchaseRevamp,freeTrial,strictHttps,twoStepRegistration,realtimeAtLogin,meetQueueSayHi,MediaLinkMessages:v1,liveVideo'
      request.set_form_data(
        'emailId' => ENV['MM_EMAIL'],
        'lat' => '1.1',
        'long' => '1.1',
        'password' => ENV['MM_PASSWORD'],
        'skipResponseKeys' => 'targeting',
        'systemInfo' => '{"hardwareVersion":"iPhone9,1","osVersion":"10.3.3","connectionType":"WiFi"}'
      )

      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      response['Set-Cookie']
    end

    def cache_cookie(new_cookie)
      redis.setex(key, 60, new_cookie)
    end

    def key
      'mm_crawler:cookie'
    end

    def redis
      @redis ||= Redis.new
    end
  end
end
