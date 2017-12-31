module MmCrawler
  module Workers
    class GetPhoto
      include Sidekiq::Worker
      sidekiq_options queue: 'photos', retry: false

      def perform(member_id, photo_id, url)
        puts url
        IO.copy_stream(open(url), "/results/#{member_id}_#{photo_id}.jpg")
      rescue StandardError => e
        puts e
        puts e.backtrace
      end
    end
  end
end
