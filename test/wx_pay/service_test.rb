class ServiceTest < MiniTest::Test
  def setup
    WxPay.appid = 'xxxxxxxxxxxxxx'
    WxPay.key = 'xxxxxxxxxxxxxxx'
    WxPay.mch_id = 'xxxxxxxxxxxxxx'
    WxPay.apiclient_cert_file = '/Users/jimmy/Workspace/shopshow-ultron/public/apiclient_cert.p12'

    @params = {
      transaction_id: '1217752501201407033233368018',
      op_user_id: '10000100',
      out_refund_no: '1415701182',
      out_trade_no: '1415757673',
      refund_fee: 1,
      total_fee: 1
    }
  end

  def test_invoke_refund
    response_body = <<-EOF
     <xml>
       <return_code><![CDATA[SUCCESS]]></return_code>
       <return_msg><![CDATA[OK]]></return_msg>
       <appid><![CDATA[wx2421b1c4370ec43b]]></appid>
       <mch_id><![CDATA[10000100]]></mch_id>
       <nonce_str><![CDATA[NfsMFbUFpdbEhPXP]]></nonce_str>
       <sign><![CDATA[B7274EB9F8925EB93100DD2085FA56C0]]></sign>
       <result_code><![CDATA[SUCCESS]]></result_code>
       <transaction_id><![CDATA[1008450740201411110005820873]]></transaction_id>
       <out_trade_no><![CDATA[1415757673]]></out_trade_no>
       <out_refund_no><![CDATA[1415701182]]></out_refund_no>
       <refund_id><![CDATA[2008450740201411110000174436]]></refund_id>
       <refund_channel><![CDATA[]]></refund_channel>
       <refund_fee>1</refund_fee>
       <coupon_refund_fee>0</coupon_refund_fee>
     </xml>    
    EOF

    FakeWeb.register_uri(
      :post,
      %r|https://api\.mch\.weixin\.qq\.com*|,
      body: response_body
    )

    r = WxPay::Service.invoke_refund(@params)
    assert_equal r.success?, true 
  end
end