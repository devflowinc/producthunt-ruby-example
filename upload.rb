require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'dotenv'
require 'base64'
require 'bigdecimal'
require 'csv'
require 'time'

require 'trieve_ruby_client'

Dotenv.load

tr_dataset = ENV['TRIEVE_DATASET_ID']
api_key = ENV['TRIEVE_API_KEY']

TrieveRubyClient.configure do |config|
  config.api_key['ApiKey'] = api_key
  config.host = 'https://api.trieve.ai'
  config.scheme = 'https'
end

chunk_api_instance = TrieveRubyClient::ChunkApi.new

url = 'https://www.producthunt.com'
response = HTTParty.get(url)

parsed_html = Nokogiri::HTML(response.body)
next_data = parsed_html.css('script#__NEXT_DATA__').first.text

next_data = JSON.parse(next_data)
apolloState = next_data['props']['apolloState']

# load every key from apolloState that starts with Post followed by a number like Post4432
post_keys = apolloState.keys.select { |key| key.match(/Post\d+/) }

for key in post_keys
  post = apolloState[key]

  id = post['id']
  name = post['name']
  tagline = post['tagline']
  createdAt = DateTime.parse(post['createdAt']).iso8601
  votesCount = post['votesCount']
  slug = post['slug']

  # TODO: should remove this once the scrape is no longer using the dirty NEXT_DATA method
  if tagline.nil?
    p "skipping post due to empty tagline: #{id}"
    next
  end

  begin
    topics = post['topics({"first":4})']['edges'].map { |edge| apolloState[edge['node']['__ref']]['slug'] }
  rescue
    topics = []
  end

  create_chunk_data = TrieveRubyClient::CreateChunkData.new
  create_chunk_data.chunk_html = "<div>#{name} - #{tagline}</div>"
  create_chunk_data.tracking_id = id
  create_chunk_data.time_stamp = createdAt
  create_chunk_data.tag_set = topics
  create_chunk_data.weight = votesCount
  create_chunk_data.link = "https://www.producthunt.com/posts/#{slug}"
  # this would be the tracking_id of the group you want to add the chunk to (if you make groups for each company)
  # chunk.group_tracking_ids = []
  create_chunk_data.upsert_by_tracking_id = true
  # can include any other custom fields you want to add
  create_chunk_data.metadata = {}

  begin
    # create_chunk
    queued_chunk = chunk_api_instance.create_chunk(tr_dataset, create_chunk_data)
    p "Queued chunk for creation: #{queued_chunk.chunk_metadata.id}"
  rescue TrieveRubyClient::ApiError => e
    puts "Error when calling ChunkApi->create_chunk: #{e}"
  end
end
