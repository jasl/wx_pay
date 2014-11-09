module WxPay
  module Notify
    GATEWAY = 'https://gw.tenpay.com/gateway/simpleverifynotifyid.xml'
    SUCCESS_STR = '<retcode>0</retcode>'

    def self.verify?(params)
      return false unless Sign.verify?(params)

      params = {
          'input_charset' => 'UTF-8',
          'partner' => WxPay.appid,
          'notify_id' => CGI.escape(params[:notify_id].to_s)
      }

      open("#{GATEWAY}?#{Utils.make_query_string(params)}").read.include?(SUCCESS_STR)
    end
  end
end
