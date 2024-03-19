# ProductHunt Trieve Example

## Set .env variables

1. Go to [dashboard.trieve.ai](https://dashboard.trieve.ai) and create an account
2. Create a dataset on the dashboard (preferably use jina embeddings for performance)
3. Copy the `dataset_id` into the `.env` file as the value for `TRIEVE_DATASET_ID` 
4. Create an API key and copy it into the `.env` as the value for `TRIEVE_API_KEY`

## Test Functionality 

Run `bundle install`

### Upload the current frontpage to Trieve 

`bundle exec ruby ./upload.rb`

### Try out search 

`bundle exec ruby ./search.rb`

### Try out chat

`bundle exec ruby ./chat.rb`