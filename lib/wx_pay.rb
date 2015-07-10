require 'wx_pay/result'
require 'wx_pay/sign'
require 'wx_pay/service'

module WxPay
  class<< self
    attr_accessor :appid, :mch_id, :key, :apiclient_cert_path

    def extra_rest_client_options=(options)
      @rest_client_options = options
    end

    def extra_rest_client_options
      @rest_client_options || {}
    end

    def apiclient_cert
      @apiclient_cert ||= OpenSSL::PKCS12.new(WxPay.apiclient_cert_path, WxPay.mch_id)
    end
  end
end
