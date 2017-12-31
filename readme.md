# MM Crawler

This project scrapes profiles from meetme.com using docker.  Follow the quick start and it will create an API for accessing all of the created profiles to be hosted on netlify.

Scrapes profiles between ages 19 and 35.

## Quick start

### Required ENV variables

- MM_EMAIL=
- MM_PASSWORD=

### Steps

Note the locations in `app.rb`.

1. `docker-compose up --build`
1. ssh into docker host
1. run `ruby app.rb`
1. wait for sidekiq jobs to finish (takes about 1-2 hours)
1. run `ruby consolidate.rb` - creates `/results/profiles.json` with all crawled profile info and relative photo paths

### Netlify deploy

In the `~/Desktop/results`, run `netlify deploy`.  Make note of the domain.

## Workers

1. `nearby_crawler` - fetches the profiles nearby and stores them. Queues fetching photo json
1. `get_photo_jsons(member_id)` - returns json of photos
1. `get_photo(url)` - persists photos

Output folder structure (in Docker):

`/results/{member_id}/`

- {member_id}.json
- {member_id}_{photo_id}.jpg
