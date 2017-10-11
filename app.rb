# Demonstrates a Sinatra server listening for webhook notifications from the Square Connect API
#
# See Webhooks Overview for more information:
# https://docs.connect.squareup.com/api/connect/v1/#webhooks-overview
#
# This sample requires the following gems:
#   sinatra (http://www.sinatrarb.com/)
#   unirest (http://unirest.io/ruby.html)
$stdout.sync = true

require 'base64'
require 'digest/sha1'
require 'json'
require 'openssl'
require 'sinatra'
require 'square_connect'

# Your application's access token
ACCESS_TOKEN = 'sq0atp-hCgUIoG-UUWDOPvIftrrWQ'

# Your application's webhook signature key, available from your application dashboard
WEBHOOK_SIGNATURE_KEY = '_ABw6Ih64Z7bLxyddKHOcw'

# The URL that this server is listening on (e.g., 'http://example.com/events')
# Note that to receive notifications from Square, this cannot be a localhost URL
WEBHOOK_URL = 'https://fierce-mountain-94709.herokuapp.com/events'

SquareConnect.configure do |config|
  # Configure OAuth2 access token for authorization: oauth2
  config.access_token = ACCESS_TOKEN
end

post '/events' do
  
  callback_body = request.body.string
  callback_signature = request.env['HTTP_X_SQUARE_SIGNATURE']

  if not is_valid_callback(callback_body, callback_signature)
    puts 'Webhook event with invalid signature detected!'
    return
  end

  callback_body_json = JSON.parse(callback_body)

  if callback_body_json.has_key?('event_type') and callback_body_json['event_type'] == 'PAYMENT_UPDATED'

    location_id = callback_body_json['location_id']
    payment_id = callback_body_json['entity_id']
    
    api_instance = SquareConnect::V1TransactionsApi.new
    response = api_instance.retrieve_payment(location_id, payment_id)
    
    puts response
  end
end


def is_valid_callback(callback_body, callback_signature)
  string_to_sign = WEBHOOK_URL + callback_body
  string_signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', WEBHOOK_SIGNATURE_KEY, string_to_sign))
  return Digest::SHA1.base64digest(string_signature) == Digest::SHA1.base64digest(callback_signature)
end
