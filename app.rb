$stdout.sync = true

require 'base64'
require 'digest/sha1'
require 'json'
require 'openssl'
require 'sinatra'
require 'square_connect'

# アクセストークンを指定します
ACCESS_TOKEN = 'YOUR_ACCESS_TOKEN'

# Webhookの署名を指定します
WEBHOOK_SIGNATURE_KEY = 'YOUR_WEBHOOK_SIGNATURE_KEY'

# WebhookのURLを指定します
WEBHOOK_URL = 'https://fierce-mountain-94709.herokuapp.com/events'

# Square connectの初期設定
SquareConnect.configure do |config|
  config.access_token = ACCESS_TOKEN
end

# POST /events に対してWebhookがきます
post '/events' do
  
  # リクエストの妥当性をチェックします
  callback_body = request.body.string
  callback_signature = request.env['HTTP_X_SQUARE_SIGNATURE']

  if not is_valid_callback(callback_body, callback_signature)
    puts 'Webhook event with invalid signature detected!'
    return
  end
  
  # JSONデータの取得
  callback_body_json = JSON.parse(callback_body)

  # PAYMENT_UPDATEイベントかどうかを判断します
  if callback_body_json.has_key?('event_type') and callback_body_json['event_type'] == 'PAYMENT_UPDATED'
    
    # テンプレートと取引IDを取得します
    location_id = callback_body_json['location_id']
    payment_id = callback_body_json['entity_id']
    
    # Square APIにアクセスして決済情報の詳細を取得します
    api_instance = SquareConnect::V1TransactionsApi.new
    response = api_instance.retrieve_payment(location_id, payment_id)
    
    puts response
  end
  
  # こちらはテストの場合です
  if callback_body_json.has_key?('event_type') and callback_body_json['event_type'] == 'TEST_NOTIFICATION'
    puts callback_body_json
  end
end

# リクエストの妥当性チェックを行います
def is_valid_callback(callback_body, callback_signature)
  string_to_sign = WEBHOOK_URL + callback_body
  string_signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', WEBHOOK_SIGNATURE_KEY, string_to_sign))
  return Digest::SHA1.base64digest(string_signature) == Digest::SHA1.base64digest(callback_signature)
end
