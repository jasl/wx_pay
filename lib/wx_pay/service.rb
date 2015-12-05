require 'rest_client'
require 'active_support/core_ext/hash/conversions'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com'

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    def self.invoke_unifiedorder(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      r = invoke_remote("#{GATEWAY_URL}/pay/unifiedorder", make_payload(params), options)

      yield r if block_given?

      r
    end

    GENERATE_APP_PAY_REQ_REQUIRED_FIELDS = %i(prepayid noncestr)
    def self.generate_app_pay_req(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        partnerid: options.delete(:mch_id) || WxPay.mch_id,
        package: 'Sign=WXPay',
        timestamp: Time.now.to_i.to_s
      }.merge(params)

      check_required_options(params, GENERATE_APP_PAY_REQ_REQUIRED_FIELDS)

      params[:sign] = WxPay::Sign.generate(params)

      params
    end

    INVOKE_REFUND_REQUIRED_FIELDS = %i(out_refund_no total_fee refund_fee op_user_id)
    def self.invoke_refund(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      params[:op_user_id] ||= params[:mch_id]

      check_required_options(params, INVOKE_REFUND_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = invoke_remote("#{GATEWAY_URL}/secapi/pay/refund", make_payload(params), options)

      yield r if block_given?

      r
    end

    INVOKE_TRANSFER_REQUIRED_FIELDS = %i(partner_trade_no openid check_name amount desc spbill_create_ip)
    def self.invoke_transfer(params, options = {})
      params = {
        mch_appid: options.delete(:appid) || WxPay.appid,
        mchid: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_TRANSFER_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = invoke_remote("#{GATEWAY_URL}/mmpaymkttransfers/promotion/transfers", make_payload(params), options)

      yield r if block_given?

      r
    end

    INVOKE_REVERSE_REQUIRED_FIELDS = %i(out_trade_no)
    def self.invoke_reverse(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_REVERSE_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = invoke_remote("#{GATEWAY_URL}/secapi/pay/reverse", make_payload(params), options)

      yield r if block_given?

      r
    end

    INVOKE_MICROPAY_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip auth_code)
    def self.invoke_micropay(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_MICROPAY_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = invoke_remote("#{GATEWAY_URL}/pay/micropay", make_payload(params), options)

      yield r if block_given?

      r
    end

    ORDER_QUERY_REQUIRED_FIELDS = %i(out_trade_no)
    def self.order_query(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, ORDER_QUERY_REQUIRED_FIELDS)

      r = invoke_remote("#{GATEWAY_URL}/pay/orderquery", make_payload(params), options)

      yield r if block_given?

      r
    end

    class << self
      private

      def check_required_options(options, names)
        names.each do |name|
          warn("WxPay Warn: missing required option: #{name}") unless options.has_key?(name)
        end
      end

      def make_payload(params)
        sign = WxPay::Sign.generate(params)
        params.delete(:key) if params[:key]
        "<xml>#{params.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}<sign>#{sign}</sign></xml>"
      end

      def invoke_remote(url, payload, options = {})
        options = WxPay.extra_rest_client_options.merge(options)

        r = RestClient::Request.execute(
          {
            method: :post,
            url: url,
            payload: payload,
            headers: { content_type: 'application/xml' }
          }.merge(options)
        )

        if r
          WxPay::Result.new(Hash.from_xml(r))
        else
          nil
        end
      end
    end
  end
end
