require 'cgi'
require 'open-uri'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com/pay'

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    def self.invoke_unifiedorder(params)
      params = {
        app_id: WxPay.appid,
        mch_id: WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      WxPay::Utils.invoke_remote("#{GATEWAY_URL}/unifiedorder", WxPay::Utils.make_payload(params))
    end

    private

    def self.check_required_options(options, names)
      names.each do |name|
        warn("WxPay Warn: missing required option: #{name}") unless options.has_key?(name)
      end
    end
  end
end
