require 'rest_client'
require 'json'
require 'cgi'
require 'securerandom'
require 'active_support/core_ext/hash/conversions'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com'.freeze
    SANDBOX_GATEWAY_URL = 'https://api.mch.weixin.qq.com/sandboxnew'.freeze
    FRAUD_GATEWAY_URL = 'https://fraud.mch.weixin.qq.com'.freeze

    def self.generate_authorize_url(redirect_uri, state = nil)
      state ||= SecureRandom.hex 16
      "https://open.weixin.qq.com/connect/oauth2/authorize?appid=#{WxPay.appid}&redirect_uri=#{CGI::escape redirect_uri}&response_type=code&scope=snsapi_base&state=#{state}"
    end

    def self.authenticate(authorization_code, options = {})
      options = WxPay.extra_rest_client_options.merge(options)
      payload = {
        appid: options.delete(:appid) || WxPay.appid,
        secret: options.delete(:appsecret) || WxPay.appsecret,
        code: authorization_code,
        grant_type: 'authorization_code'
      }
      url = "https://api.weixin.qq.com/sns/oauth2/access_token"

      ::JSON.parse(RestClient::Request.execute(
        {
          method: :get,
          headers: {params: payload},
          url: url
        }.merge(options)
      ), quirks_mode: true)
    end

    def self.get_sandbox_signkey(mch_id = WxPay.mch_id, options = {})
      params = {
        mch_id: mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }
      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/pay/getsignkey", xmlify_payload(params))))
      yield r if block_given?
      r
    end

    def self.authenticate_from_weapp(js_code, options = {})
      options = WxPay.extra_rest_client_options.merge(options)
      payload = {
        appid: options.delete(:appid) || WxPay.appid,
        secret: options.delete(:appsecret) || WxPay.appsecret,
        js_code: js_code,
        grant_type: 'authorization_code'
      }
      url = "https://api.weixin.qq.com/sns/jscode2session"

      ::JSON.parse(RestClient::Request.execute(
        {
          method: :get,
          headers: {params: payload},
          url: url
        }.merge(options)
      ), quirks_mode: true)
    end

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = [:body, :out_trade_no, :total_fee, :spbill_create_ip, :notify_url, :trade_type]
    def self.invoke_unifiedorder(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/pay/unifiedorder", make_payload(params), options)))

      yield r if block_given?

      r
    end

    INVOKE_CLOSEORDER_REQUIRED_FIELDS = [:out_trade_no]
    def self.invoke_closeorder(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_CLOSEORDER_REQUIRED_FIELDS)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/pay/closeorder", make_payload(params), options)))

      yield r if block_given?

      r
    end

    GENERATE_APP_PAY_REQ_REQUIRED_FIELDS = [:prepayid, :noncestr]
    def self.generate_app_pay_req(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        partnerid: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        package: 'Sign=WXPay',
        timestamp: Time.now.to_i.to_s
      }.merge(params)

      check_required_options(params, GENERATE_APP_PAY_REQ_REQUIRED_FIELDS)

      params[:sign] = WxPay::Sign.generate(params)

      params
    end

    GENERATE_JS_PAY_REQ_REQUIRED_FIELDS = [:prepayid, :noncestr]
    def self.generate_js_pay_req(params, options = {})
      check_required_options(params, GENERATE_JS_PAY_REQ_REQUIRED_FIELDS)

      params = {
        appId: options.delete(:appid) || WxPay.appid,
        package: "prepay_id=#{params.delete(:prepayid)}",
        key: options.delete(:key) || WxPay.key,
        nonceStr: params.delete(:noncestr),
        timeStamp: Time.now.to_i.to_s,
        signType: 'MD5'
      }.merge(params)

      params[:paySign] = WxPay::Sign.generate(params)
      params
    end

    INVOKE_REFUND_REQUIRED_FIELDS = [:out_refund_no, :total_fee, :refund_fee, :op_user_id]
    # out_trade_no 和 transaction_id 是二选一(必填)
    def self.invoke_refund(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      params[:op_user_id] ||= params[:mch_id]

      check_required_options(params, INVOKE_REFUND_REQUIRED_FIELDS)
      warn("WxPay Warn: missing required option: out_trade_no or transaction_id must have one") if ([:out_trade_no, :transaction_id] & params.keys) == []

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/secapi/pay/refund", make_payload(params), options)))

      yield r if block_given?

      r
    end

    REFUND_QUERY_REQUIRED_FIELDS = [:out_trade_no]
    def self.refund_query(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, ORDER_QUERY_REQUIRED_FIELDS)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/pay/refundquery", make_payload(params), options)))

      yield r if block_given?

      r
    end

    INVOKE_TRANSFER_REQUIRED_FIELDS = [:partner_trade_no, :openid, :check_name, :amount, :desc, :spbill_create_ip]
    def self.invoke_transfer(params, options = {})
      params = {
        mch_appid: options.delete(:appid) || WxPay.appid,
        mchid: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        key: options.delete(:key) || WxPay.key
      }.merge(params)

      check_required_options(params, INVOKE_TRANSFER_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaymkttransfers/promotion/transfers", make_payload(params), options)))

      yield r if block_given?

      r
    end

    GETTRANSFERINFO_FIELDS = [:partner_trade_no]
    def self.gettransferinfo(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        key: options.delete(:key) || WxPay.key
      }.merge(params)

      check_required_options(params, GETTRANSFERINFO_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaymkttransfers/gettransferinfo", make_payload(params), options)))

      yield r if block_given?

      r
    end

    # 获取加密银行卡号和收款方用户名的RSA公钥
    def self.risk_get_public_key(options = {})
      params = {
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        key: options.delete(:key) || WxPay.key,
        sign_type: 'MD5'
      }

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        gateway_url: FRAUD_GATEWAY_URL
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/risk/getpublickey", make_payload(params), options)))

      yield r if block_given?

      r
    end

    PAY_BANK_FIELDS = [:enc_bank_no, :enc_true_name, :bank_code, :amount, :desc]
    def self.pay_bank(params, options = {})
      params = {
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        key: options.delete(:key) || WxPay.key,
      }.merge(params)

      check_required_options(params, PAY_BANK_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaysptrans/pay_bank", make_payload(params), options)))

      yield r if block_given?

      r
    end

    QUERY_BANK_FIELDS = [:partner_trade_no]
    def self.query_bank(params, options = {})
      params = {
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        key: options.delete(:key) || WxPay.key,
      }.merge(params)

      check_required_options(params, QUERY_BANK_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaysptrans/query_bank", make_payload(params), options)))

      yield r if block_given?

      r
    end

    INVOKE_REVERSE_REQUIRED_FIELDS = [:out_trade_no]
    def self.invoke_reverse(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_REVERSE_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/secapi/pay/reverse", make_payload(params), options)))

      yield r if block_given?

      r
    end

    INVOKE_MICROPAY_REQUIRED_FIELDS = [:body, :out_trade_no, :total_fee, :spbill_create_ip, :auth_code]
    def self.invoke_micropay(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_MICROPAY_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/pay/micropay", make_payload(params), options)))

      yield r if block_given?

      r
    end

    ORDER_QUERY_REQUIRED_FIELDS = [:out_trade_no]
    def self.order_query(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)


      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/pay/orderquery", make_payload(params), options)))
      check_required_options(params, ORDER_QUERY_REQUIRED_FIELDS)

      yield r if block_given?

      r
    end

    DOWNLOAD_BILL_REQUIRED_FIELDS = [:bill_date, :bill_type]
    def self.download_bill(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      check_required_options(params, DOWNLOAD_BILL_REQUIRED_FIELDS)

      r = invoke_remote("/pay/downloadbill", make_payload(params), options)

      yield r if block_given?

      r
    end

    DOWNLOAD_FUND_FLOW_REQUIRED_FIELDS = [:bill_date, :account_type]
    def self.download_fund_flow(params, options = {})
      params = {
          appid: options.delete(:appid) || WxPay.appid,
          mch_id: options.delete(:mch_id) || WxPay.mch_id,
          nonce_str: SecureRandom.uuid.tr('-', ''),
          key: options.delete(:key) || WxPay.key
      }.merge(params)

      check_required_options(params, DOWNLOAD_FUND_FLOW_REQUIRED_FIELDS)

      options = {
          ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
          ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
          verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = invoke_remote("/pay/downloadfundflow", make_payload(params, WxPay::Sign::SIGN_TYPE_HMAC_SHA256), options)

      yield r if block_given?

      r
    end

    def self.sendgroupredpack(params, options={})
      params = {
        wxappid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      #check_required_options(params, INVOKE_MICROPAY_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaymkttransfers/sendgroupredpack", make_payload(params), options)))

      yield r if block_given?

      r
    end

    def self.sendredpack(params, options={})
      params = {
        wxappid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        key: options.delete(:key) || WxPay.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      #check_required_options(params, INVOKE_MICROPAY_REQUIRED_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaymkttransfers/sendredpack", make_payload(params), options)))

      yield r if block_given?

      r
    end

    # 用于商户对已发放的红包进行查询红包的具体信息，可支持普通红包和裂变包。
    GETHBINFO_FIELDS = [:mch_billno, :bill_type]
    def self.gethbinfo(params, options = {})
      params = {
        appid: options.delete(:appid) || WxPay.appid,
        mch_id: options.delete(:mch_id) || WxPay.mch_id,
        nonce_str: SecureRandom.uuid.tr('-', ''),
        key: options.delete(:key) || WxPay.key
      }.merge(params)

      check_required_options(params, GETHBINFO_FIELDS)

      options = {
        ssl_client_cert: options.delete(:apiclient_cert) || WxPay.apiclient_cert,
        ssl_client_key: options.delete(:apiclient_key) || WxPay.apiclient_key,
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      r = WxPay::Result.new(Hash.from_xml(invoke_remote("/mmpaymkttransfers/gethbinfo", make_payload(params), options)))

      yield r if block_given?

      r
    end

    class << self
      private

      def get_gateway_url
        return SANDBOX_GATEWAY_URL if WxPay.sandbox_mode?
        GATEWAY_URL
      end

      def check_required_options(options, names)
        return unless WxPay.debug_mode?
        names.each do |name|
          warn("WxPay Warn: missing required option: #{name}") unless options.has_key?(name)
        end
      end

      def xmlify_payload(params, sign_type = WxPay::Sign::SIGN_TYPE_MD5)
        sign = WxPay::Sign.generate(params, sign_type)
        "<xml>#{params.except(:key).sort.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}<sign>#{sign}</sign></xml>"
      end

      def make_payload(params, sign_type = WxPay::Sign::SIGN_TYPE_MD5)
        # TODO: Move this out
        if WxPay.sandbox_mode? && !WxPay.manual_get_sandbox_key?
          r = get_sandbox_signkey
          if r['return_code'] == WxPay::Result::SUCCESS_FLAG
            params = params.merge(
              mch_id: r['mch_id'] || WxPay.mch_id,
              key: r['sandbox_signkey']
            )
          else
            warn("WxPay Warn: fetch sandbox sign key failed #{r['return_msg']}")
          end
        end

        xmlify_payload(params, sign_type)
      end

      def invoke_remote(url, payload, options = {})
        options = WxPay.extra_rest_client_options.merge(options)
        gateway_url = options.delete(:gateway_url) || get_gateway_url
        url = "#{gateway_url}#{url}"

        RestClient::Request.execute(
          {
            method: :post,
            url: url,
            payload: payload,
            headers: { content_type: 'application/xml' }
          }.merge(options)
        )
      end
    end
  end
end
