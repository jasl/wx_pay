require 'test_helper'

class WxPay::SignTest < MiniTest::Test
  def setup
    @params = {
      appid: 'wxd930ea5d5a258f4f',
      auth_code: 123456,
      body: 'test',
      device_info: 123,
      mch_id: 1900000109,
      nonce_str: '960f228109051b9969f76c82bde183ac',
      out_trade_no: '1400755861',
      spbill_create_ip: '127.0.0.1',
      total_fee: 1
    }

    @sign = '729A68AC3DE268DBD9ADE442382E7B24'
  end

  def test_generate_sign
    assert_equal @sign, WxPay::Sign.generate(@params)
  end

  def test_verify_sign
    assert WxPay::Sign.verify?(@params.merge(:sign => @sign))
  end

  def test_verify_sign_when_fails
    assert !WxPay::Sign.verify?(@params.merge(:danger => 'danger', :sign => @sign))
  end

  def test_accept_pars_key_to_generate_sign
    @params.merge!(key: "key")

    assert_equal "1454C32E885B8D9E4A05E976D1C45B88", WxPay::Sign.generate(@params)
  end
end
