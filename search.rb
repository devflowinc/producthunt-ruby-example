require 'bundler/setup'
require 'dotenv'
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

# Can try semantic, fulltext, or hybrid options
search_chunk_data = TrieveRubyClient::SearchChunkData.new({query: 'What should I use to write articles with citations?', search_type: 'semantic'})

begin
  # search
  result = chunk_api_instance.search_chunk(tr_dataset, search_chunk_data)
  result_chunks = result.score_chunks
  result_chunks[0..2].each do |score_chunk_dto| 
    chunk_data = score_chunk_dto.metadata.first
    puts "Chunk ID: #{chunk_data.tracking_id}"
    puts "HTML: #{chunk_data.chunk_html}"
    # BUG: score datatype cast is going to be fixed in the next release
    puts "Score: #{score_chunk_dto.score / 10000.0}"
    puts "---"
  end
rescue TrieveRubyClient::ApiError => e
  puts "Error when calling ChunkApi->search_chunk: #{e}"
end