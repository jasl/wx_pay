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

    INVOKE_REFUND_REQUIRED_FIELDS = %i(transaction_id out_trade_no out_refund_no total_fee refund_fee)
    def self.invoke_refund(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        op_user_id: WxPay.mch_id
      }.merge(params)

      check_required_options(params, INVOKE_REFUND_REQUIRED_FIELDS)

      # 微信退款需要双向证书
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_4
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3

      WxPay.extra_rest_client_options = {
        ssl_client_cert: WxPay.apiclient_cert.certificate,
        ssl_client_key: WxPay.apiclient_cert.key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }

      r = invoke_remote "#{GATEWAY_URL}/pay/closeorder", make_payload(params)

      yield(r) if block_given?

      r
    end

    CLOSE_ORDER_REQUIRED_FIELDS = %i(out_trade_no)
    def self.close_order(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      check_required_options(params, CLOSE_ORDER_REQUIRED_FIELDS)

      r = invoke_remote "#{GATEWAY_URL}/secapi/pay/refund", make_payload(params)

      yield(r) if block_given?

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

    def self.invoke_remote(url, payload)
      r = RestClient::Request.execute(
        {
          method: :post,
          url: url,
          payload: payload,
          headers: { content_type: 'application/xml' }
        }.merge(WxPay.extra_rest_client_options)
      )

      if r
        WxPay::Result.new Hash.from_xml(r)
      else
        nil
      end
    end
  end
end
