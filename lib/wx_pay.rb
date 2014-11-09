require 'wx_pay/utils'
require 'wx_pay/sign'
require 'wx_pay/service'
require 'wx_pay/notify'

module WxPay
  class<< self
    attr_accessor :appid, :mch_id, :key

    def extra_rest_client_options=(options)
      @rest_client_options = options
    end

    def extra_rest_client_options
      @rest_client_options || {}
    end
  end
end
