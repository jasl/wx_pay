require 'active_support/core_ext/hash/conversions'
require 'minitest/autorun'
require 'wx_pay'
require 'webmock/minitest'

WxPay.appid = 'wxd930ea5d5a258f4f'
WxPay.key = '8934e7d15453e97507ef794cf7b0519d'
WxPay.mch_id = '1900000109'
WxPay.debug_mode = true
