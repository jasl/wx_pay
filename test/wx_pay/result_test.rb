require 'test_helper'

class WxPay::ResultTest < MiniTest::Test
  def test_success_method_with_true
    r = WxPay::Result.new(
      Hash.from_xml(
        <<-XML
        <xml>
          <return_code>SUCCESS</return_code>
          <result_code>SUCCESS</result_code>
        </xml>
        XML
      ))

    assert_equal r.success?, true
  end

  def test_success_method_with_false
    r = WxPay::Result.new(
      Hash.from_xml(
        <<-XML
        <xml>
        </xml>
        XML
      ))

    assert_equal r.success?, false
  end
end
