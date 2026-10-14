require "test_helper"

# Oct 2026 reference week used throughout:
#   Mon 2026-10-12, Tue 13, Wed 14, Thu 15, Fri 16, Sat 17, Sun 18, Mon 19
class BusinessHoursTest < ActiveSupport::TestCase
  def t(y = 2026, m = 10, d = 12, h = 9, min = 0)
    Time.zone.local(y, m, d, h, min)
  end

  test "business_time? is true inside a weekday window" do
    assert BusinessHours.business_time?(t(2026, 10, 14, 10, 0)) # Wed 10:00
  end

  test "business_time? is false before open, after close and on weekends" do
    assert_not BusinessHours.business_time?(t(2026, 10, 14, 8, 0))   # Wed 08:00
    assert_not BusinessHours.business_time?(t(2026, 10, 14, 17, 0))  # Wed 17:00 (close, exclusive)
    assert_not BusinessHours.business_time?(t(2026, 10, 14, 18, 30)) # Wed 18:30
    assert_not BusinessHours.business_time?(t(2026, 10, 17, 12, 0))  # Saturday
    assert_not BusinessHours.business_time?(t(2026, 10, 18, 12, 0))  # Sunday
  end

  test "advance within a single working day" do
    assert_equal t(2026, 10, 12, 10, 0), BusinessHours.advance(t(2026, 10, 12, 9, 0), 60)
  end

  test "advance rolls to next morning when the day runs out" do
    # Mon 16:30 + 60 min -> 30 min Mon + 30 min Tue 09:00..09:30
    assert_equal t(2026, 10, 13, 9, 30), BusinessHours.advance(t(2026, 10, 12, 16, 30), 60)
  end

  test "advance skips the weekend" do
    # Fri 16:30 + 120 min -> 30 min Fri + 90 min Mon 09:00..10:30
    assert_equal t(2026, 10, 19, 10, 30), BusinessHours.advance(t(2026, 10, 16, 16, 30), 120)
  end

  test "advance from a weekend starts counting Monday morning" do
    assert_equal t(2026, 10, 19, 10, 0), BusinessHours.advance(t(2026, 10, 17, 12, 0), 60)
  end

  test "advance from before opening starts at open" do
    assert_equal t(2026, 10, 12, 9, 30), BusinessHours.advance(t(2026, 10, 12, 7, 0), 30)
  end

  test "advance exactly one full business day lands on close" do
    assert_equal t(2026, 10, 12, 17, 0), BusinessHours.advance(t(2026, 10, 12, 9, 0), 480)
  end

  test "minutes_between inside one window" do
    assert_equal 90, BusinessHours.minutes_between(t(2026, 10, 12, 9, 0), t(2026, 10, 12, 10, 30))
  end

  test "minutes_between ignores nights and weekends" do
    # Fri 16:00 -> Mon 09:30 = 60 (Fri) + 30 (Mon) = 90 working minutes
    assert_equal 90, BusinessHours.minutes_between(t(2026, 10, 16, 16, 0), t(2026, 10, 19, 9, 30))
  end

  test "minutes_between across a full weekend with no working time is zero" do
    assert_equal 0, BusinessHours.minutes_between(t(2026, 10, 16, 17, 0), t(2026, 10, 19, 9, 0))
  end

  test "minutes_between returns zero when to precedes from" do
    assert_equal 0, BusinessHours.minutes_between(t(2026, 10, 12, 10, 0), t(2026, 10, 12, 9, 0))
  end

  test "advance and minutes_between are inverse over business time" do
    start = t(2026, 10, 13, 11, 15) # Tue 11:15
    due = BusinessHours.advance(start, 500)
    assert_equal 500, BusinessHours.minutes_between(start, due)
  end
end
