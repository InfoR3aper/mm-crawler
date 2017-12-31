require './mm_crawler'
require 'sidekiq/api'

def clear_sidekiq
  Sidekiq::Queue.new('api').clear
  Sidekiq::Queue.new('photos').clear
end

clear_sidekiq

# Vietnam
MmCrawler::Workers::NearbyCrawler.new.perform(:f, 'Ho%20Chi%20Minh%20City,%20VN')

# USA
MmCrawler::Workers::NearbyCrawler.new.perform(:m, 'Independence,%20KS')
# USA
MmCrawler::Workers::NearbyCrawler.new.perform(:m, 'Kilsby,%20GB')
