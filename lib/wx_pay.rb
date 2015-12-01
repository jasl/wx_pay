require 'wx_pay/result'
require 'wx_pay/sign'
require 'wx_pay/service'

module WxPay
  @rest_client_options = {}

  class<< self
    attr_accessor :appid, :mch_id, :key, :apiclient_cert, :apiclient_key, :extra_rest_client_options
  end
end
