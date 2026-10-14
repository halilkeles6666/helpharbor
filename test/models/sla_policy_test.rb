require "test_helper"

class SlaPolicyTest < ActiveSupport::TestCase
  test "for_priority returns the active policy for a priority" do
    assert_equal sla_policies(:urgent), SlaPolicy.for_priority("urgent")
  end

  test "for_priority ignores inactive policies" do
    sla_policies(:urgent).update!(active: false)
    assert_nil SlaPolicy.for_priority("urgent")
  end

  test "priority must be unique" do
    dup = SlaPolicy.new(name: "Dup", priority: "normal", first_response_minutes: 10, resolution_minutes: 20)
    assert_not dup.valid?
  end

  test "minutes must be positive integers" do
    policy = SlaPolicy.new(name: "Bad", priority: "weird", first_response_minutes: 0, resolution_minutes: -5)
    assert_not policy.valid?
    assert policy.errors[:first_response_minutes].any?
    assert policy.errors[:resolution_minutes].any?
  end
end
