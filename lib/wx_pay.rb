require 'wx_pay/result'
require 'wx_pay/sign'
require 'wx_pay/service'
require 'openssl'

module WxPay
  SANDBOX_SIGNKEY_URL = 'https://api.mch.weixin.qq.com/sandboxnew/pay/getsignkey'.freeze

  @extra_rest_client_options = {}
  @debug_mode = true
  @sandbox = false


  class<< self
    attr_accessor :appid, :mch_id, :key, :appsecret, :extra_rest_client_options, :debug_mode, :sandbox
    attr_reader :apiclient_cert, :apiclient_key

    def set_apiclient_by_pkcs12(str, pass)
      pkcs12 = OpenSSL::PKCS12.new(str, pass)
      @apiclient_cert = pkcs12.certificate
      @apiclient_key = pkcs12.key

      pkcs12
    end

    def apiclient_cert=(cert)
      @apiclient_cert = OpenSSL::X509::Certificate.new(cert)
    end

    def apiclient_key=(key)
      @apiclient_key = OpenSSL::PKey::RSA.new(key)
    end

    def debug_mode?
      @debug_mode
    end

    def sandbox?
      @sandbox
    end

    def key
      return @key if !sandbox? || @fetched_sandbox_key

      params = { mch_id: WxPay.mch_id, nonce_str: SecureRandom.uuid.tr('-', '') }

      response = WxPay::Service.post(SANDBOX_SIGNKEY_URL, params, {})

      @key = response.fetch('sandbox_signkey')
      @fetched_sandbox_key = true
    end
  end
end
