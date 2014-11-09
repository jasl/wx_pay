require 'test_helper'

class WxPay::UtilsTest < MiniTest::Unit::TestCase
  def test_stringify_keys
    hash = { 'a' => 1, :b => 2 }
    assert_equal({ 'a' => 1, 'b' => 2 }.sort, WxPay::Utils.stringify_keys(hash).sort)
  end
end
