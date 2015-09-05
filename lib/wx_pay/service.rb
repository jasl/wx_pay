require 'rest_client'
require 'active_support/core_ext/hash/conversions'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com'

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    def self.invoke_unifiedorder(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      r = invoke_remote("#{GATEWAY_URL}/pay/unifiedorder", make_payload(params))

      yield r if block_given?

      r
    end

    GENERATE_APP_PAY_REQ_REQUIRED_FIELDS = %i(prepayid noncestr)
    def self.generate_app_pay_req(params)
      params = {
        appid: WxPay.appid,
        partnerid: WxPay.mch_id,
        package: 'Sign=WXPay',
        timestamp: Time.now.to_i.to_s
      }.merge(params)

      check_required_options(params, GENERATE_APP_PAY_REQ_REQUIRED_FIELDS)

      params[:sign] = WxPay::Sign.generate(params)

      params
    end

    INVOKE_REFUND_REQUIRED_FIELDS = %i(out_refund_no total_fee refund_fee)
    def self.invoke_refund(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        op_user_id: WxPay.mch_id
      }.merge(params)

      check_required_options(params, INVOKE_REFUND_REQUIRED_FIELDS)

      r = invoke_remote_with_cert("#{GATEWAY_URL}/secapi/pay/refund", make_payload(params))

      yield(r) if block_given?

      r
    end

    INVOKE_TRANSFER_REQUIRED_FIELDS = %i(partner_trade_no openid check_name amount desc spbill_create_ip)
    def self.invoke_transfer params
      params = {
        mch_appid: WxPay.appid,
        mchid: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_TRANSFER_REQUIRED_FIELDS)

      r = invoke_remote_with_cert("#{GATEWAY_URL}/mmpaymkttransfers/promotion/transfers", make_payload(params))

      yield r if block_given?

      r
    end


    private

    def self.check_required_options(options, names)
      names.each do |name|
        warn("WxPay Warn: missing required option: #{name}") unless options.has_key?(name)
      end
    end

    def self.make_payload(params)
      sign = WxPay::Sign.generate(params)
      params.delete(:key) if params[:key]
      "<xml>#{params.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}<sign>#{sign}</sign></xml>"
    end

    def self.invoke_remote_with_cert(url, payload)
      # 微信退款、企业付款等需要双向证书
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_4
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3

      invoke_remote(url, payload, {
        ssl_client_cert: WxPay.apiclient_cert.certificate,
        ssl_client_key: WxPay.apiclient_cert.key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      })
    end

    def self.invoke_remote(url, payload, extra_rest_client_options = {})
      r = RestClient::Request.execute(
        {
          method: :post,
          url: url,
          payload: payload,
          headers: { content_type: 'application/xml' }
        }.merge(WxPay.extra_rest_client_options).merge(extra_rest_client_options)
      )

      if r
        WxPay::Result.new Hash.from_xml(r)
      else
        nil
      end
    end
  end
end
