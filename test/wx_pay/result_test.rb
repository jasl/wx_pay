require 'test_helper'

class WxPay::ResultTest < MiniTest::Test
  def test_success_method_with_true
    r = WxPay::Result[
      Hash.from_xml(
        <<-XML
        <xml>
          <return_code>SUCCESS</return_code>
          <result_code>SUCCESS</result_code>
        </xml>
        XML
      )
    ]

    assert_equal r.success?, true
  end

  def test_nonexistent_key
    r = WxPay::Result[
      Hash.from_xml(
        <<-XML
        <xml>
          <return_code>SUCCESS</return_code>
          <code_url>wx_code_url</code_url>
          <result_code>SUCCESS</result_code>
        </xml>
        XML
      )
    ]

    assert_equal r['return_code'].nil?, false
    assert_equal r['prepay_id'].nil?, true
    assert_equal r.keys, ['return_code', 'code_url', 'result_code']
  end

  def test_success_method_with_false
    r = WxPay::Result[
      Hash.from_xml(
        <<-XML
        <xml>
        </xml>
        XML
      )
    ]

    assert_equal r.success?, false
  end
end
