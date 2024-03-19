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

topic_api_instance = TrieveRubyClient::TopicApi.new

create_topic_data = TrieveRubyClient::CreateTopicData.new
create_topic_data.first_user_message = 'What should I use to write articles with citations?'

begin
  # create_topic
  result = topic_api_instance.create_topic(tr_dataset, create_topic_data)
  topic_id = result.id
  p "Created topic with ID: #{topic_id}"
rescue TrieveRubyClient::ApiError => e
  puts "Error when calling TopicApi->create_topic: #{e}"
end

message_api_instance = TrieveRubyClient::MessageApi.new

create_message_data = TrieveRubyClient::CreateMessageData.new({new_message_content: 'What should I use to write articles with citations?', topic_id: topic_id})

begin
  # create_message
  result = message_api_instance.create_message_completion_handler(tr_dataset, create_message_data)
  # Citations and generated message are separated by ||
    # This is done for easy streaming support, check how we handle it by looking at the code for the Chat UI at devflowinc/trieve
  # Performance of RAG here can be improved by adjusting `RAG_PROMPT` in the admin dashboard, by using a custom prompt on the request, or by using different models that better suit the use-case
    # The default prompt is 'Respond to the instruction and include the doc numbers that you used in square brackets at the end of the sentences that you used the docs for:'
  citations = JSON.parse(result.split('||')[0])
  generated_message = result.split('||')[1]
  p "Citations: #{citations}"
  p "Generated message: #{generated_message}"
rescue TrieveRubyClient::ApiError => e
  puts "Error when calling MessageApi->create_message_completion_handler: #{e}"
end