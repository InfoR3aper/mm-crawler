module MmCrawler
  module Workers
    class NearbyCrawler
      include Sidekiq::Worker
      sidekiq_options queue: 'api', retry: false

      def perform(gender, location, page_num=0)
        puts "processing #{page_num}"

        raw_json = nearby_response(gender: gender, location: location, page_num: page_num).body
        json = Oj.load(raw_json)
        if json['errorType']
          puts json
          return
        end
        found_members = json['members']&.first['members']
        puts "found #{found_members.length}"
        
        found_members.each do |member_h|
          member_id = member_h['member']['member_id']
          cookie_service.redis.sadd("member_ids", member_id)
          MmCrawler::Workers::GetPhotosJson.perform_async(member_id)
        end

        self.class.perform_in(5, gender, location, page_num + 1) if found_members.any?
      rescue StandardError => e
        puts e
        puts e.backtrace
      end

      def cookie_service
        @cookie_service ||= MmCrawler::CookieService.new
      end

      def nearby_response(gender:, location:, page_num: 0)
        uri = URI.parse("http://friends.meetme.com/mobile/search/meet/#{page_num}?configurationAdSlot=1&includeFriends=t&isOnline=f&locationString=#{location}&minAge=19&maxAge=35&pageSize=29&includeSkoutUsers=t&gender=#{gender}")
        request = Net::HTTP::Get.new(uri)
        request['Host'] = 'friends.meetme.com'
        request['X-Notificationtypes'] = 'friendAccept,newMatch,boostChat,smileSent,newMemberAlert'
        request['Accept-Language'] = 'en_US'
        request['Accept'] = '*/*'
        request['X-Stats'] = '%7B%22memUsed%22%3A%221%22%2C%22memTotal%22%3A%221%22%2C%22methods%22%3A%5B%7B%22key%22%3A%22economyBalance%22%2C%22roundTrip%22%3A%220.1%22%2C%22parse%22%3A%220.000001%22%7D%2C%7B%22key%22%3A%22chatList%22%2C%22roundTrip%22%3A%220.1%22%2C%22parse%22%3A%220.000004%22%7D%5D%7D'
        request['User-Agent'] = 'MeetMe/12.7.0 (iPhone; iOS 11.2.1; Scale/3.00)'
        request['X-Counts'] = '0'
        request['X-Supportedfeatures'] = 'chatSuggestions,messageStickers,StackedNotifications:v5,tags,purchaseRevamp,freeTrial,strictHttps,twoStepRegistration,realtimeAtLogin,meetQueueSayHi,MediaLinkMessages:v1,liveVideo'
        request['Cookie'] = MmCrawler::CookieService.new.cookie

        req_options = {
          use_ssl: uri.scheme == 'https'
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
      end

      def save_member_json(json)
        path = "/results/#{json['member_id']}"
        FileUtils.mkdir_p path
        File.open("#{path}/profile.json", 'w') { |file| file.write(Oj.dump(json)) }
      end
    end
  end
end
