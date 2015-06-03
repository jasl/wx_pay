require 'rest_client'
require 'active_support/core_ext/hash/conversions'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com/pay'

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    def self.invoke_unifiedorder(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      r = invoke_remote("#{GATEWAY_URL}/unifiedorder", make_payload(params))

      # when trade_type is app, signing again is needed, the sigin params are below 
      # appid，partnerid，prepayid，noncestr，timestamp，package。
      # notice: package is "Sign=WXPay", noncestr is the same as the params[:nonce_str]
      # prepayid is the r["prepay_id"]
      if params[:trade_type] == 'APP' && r["return_code"] == "SUCCESS" && r["result_code"] == "SUCCESS"
        sign_again_params = {
          appid: params[:appid],
          noncestr: params[:nonce_str],
          package: 'Sign=WXPay',
          partnerid: params[:mch_id],
          timestamp: Time.now.to_i.to_s,
          prepayid: r["prepay_id"]
        }
      r["sign"] = Sign.generate(sign_again_params)

      end
      
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
      "<xml>#{params.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}<sign>#{WxPay::Sign.generate(params)}</sign></xml>"
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
