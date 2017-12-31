module MmCrawler
  module Workers
    class GetPhotosJson
      include Sidekiq::Worker
      sidekiq_options queue: 'api', retry: false

      def perform(member_id)
        puts "processing #{member_id}"

        raw_json = photos_json_response(member_id: member_id).body
        save_json(member_id, raw_json)

        json = Oj.load(raw_json)
        photos = json['data']['photos']
        photos.each_with_index do |photo, i|
          photo_id = photo['photoId'] || i
          url = photo['photoLarge'].include?('.com') ? photo['photoLarge'] : 'http://images.meetmecdna.com/' + photo['photoLarge']
          MmCrawler::Workers::GetPhoto.perform_async(member_id, photo_id, url)
        end
      rescue StandardError => e
        puts e
        puts e.backtrace
      end

      def cookie_service
        @cookie_service ||= MmCrawler::CookieService.new
      end

      def photos_json_response(member_id:)
        uri = URI.parse("http://profile.meetme.com/mobile/photos/#{member_id}/0?pageSize=10&configurationAdSlot=1&addMemberData=t&source=thumbnails")
        request = Net::HTTP::Get.new(uri)
        request['Host'] = 'profile.meetme.com'
        request['X-Notificationtypes'] = 'friendAccept,newMatch,boostChat,smileSent,newMemberAlert'
        request['Accept-Language'] = 'en_US'
        request['Accept'] = '*/*'
        request['X-Stats'] = '%7B%22memUsed%22%3A%221%22%2C%22memTotal%22%3A%221%22%2C%22methods%22%3A%5B%7B%22key%22%3A%22economyBalance%22%2C%22roundTrip%22%3A%221%22%2C%22parse%22%3A%220.000002%22%7D%2C%7B%22key%22%3A%22batchEvent%22%2C%22roundTrip%22%3A%220.518738%22%2C%22parse%22%3A%220.000001%22%7D%2C%7B%22key%22%3A%22chatList%22%2C%22roundTrip%22%3A%221%22%2C%22parse%22%3A%220.000001%22%7D%5D%7D'
        request['User-Agent'] = 'MeetMe/12.7.0 (iPhone; iOS 11.2.1; Scale/3.00)'
        request['X-Supportedfeatures'] = 'chatSuggestions,messageStickers,StackedNotifications:v5,tags,purchaseRevamp,freeTrial,strictHttps,twoStepRegistration,realtimeAtLogin,meetQueueSayHi,MediaLinkMessages:v1,liveVideo'
        request['Cookie'] = MmCrawler::CookieService.new.cookie

        req_options = {
          use_ssl: uri.scheme == 'https'
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
      end

      def save_json(member_id, raw_json)
        path = "/results/#{member_id}.json"
        File.open(path, 'w') { |file| file.write(raw_json) }
      end
    end
  end
end
