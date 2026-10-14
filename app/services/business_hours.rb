# BusinessHours
#
# The heart of HelpHarbor's SLA engine and the fix for the #1 user pain we
# cloned from (see README: "SLA clock keeps counting on weekends / outside
# working hours"). Every SLA duration is expressed in *business minutes* and
# only elapses during configured working hours on working days. Nights and
# weekends do not consume the clock.
#
# To change the working-week rules (e.g. "the SLA must not count weekends",
# or "we now work Saturdays"), edit the three constants below — this is the
# single source of truth the whole app points at.
module BusinessHours
  # Working days as Ruby wday numbers (Sunday = 0 ... Saturday = 6).
  # Monday–Friday. Remove/add a number here to change which days count.
  WORKDAYS = [ 1, 2, 3, 4, 5 ].freeze

  # Daily working window, in the application time zone (config.time_zone).
  OPEN_HOUR  = 9   # 09:00
  OPEN_MIN   = 0
  CLOSE_HOUR = 17  # 17:00
  CLOSE_MIN  = 0

  MAX_DAY_SCAN = 31 # safety bound so day-scanning never loops forever

  module_function

  # Is +time+ on a working day?
  def working_day?(time)
    WORKDAYS.include?(time.in_time_zone.wday)
  end

  # Start of the working window on +time+'s date (e.g. 09:00 local).
  def window_open(time)
    time.in_time_zone.change(hour: OPEN_HOUR, min: OPEN_MIN, sec: 0)
  end

  # End of the working window on +time+'s date (e.g. 17:00 local).
  def window_close(time)
    time.in_time_zone.change(hour: CLOSE_HOUR, min: CLOSE_MIN, sec: 0)
  end

  # Is +time+ inside a working window right now?
  def business_time?(time)
    t = time.in_time_zone
    working_day?(t) && t >= window_open(t) && t < window_close(t)
  end

  # The first business instant at or after +time+.
  # If +time+ is already inside a window, it is returned unchanged.
  def next_business_start(time)
    t = time.in_time_zone
    MAX_DAY_SCAN.times do
      if working_day?(t)
        open  = window_open(t)
        close = window_close(t)
        return open if t < open
        return t    if t < close
      end
      # Past close, or a non-working day: jump to 00:00 of the next day.
      t = (t.to_date + 1).in_time_zone
    end
    raise "BusinessHours: no working day found within #{MAX_DAY_SCAN} days"
  end

  # The wall-clock Time that is +minutes+ business-minutes after +from+.
  # Counting begins at the next business instant on/after +from+, so a ticket
  # opened Saturday starts its clock Monday morning.
  def advance(from, minutes)
    minutes = minutes.to_i
    cursor  = from.in_time_zone
    return cursor if minutes <= 0

    cursor    = next_business_start(cursor)
    remaining = minutes

    while remaining > 0
      close     = window_close(cursor)
      available = ((close - cursor) / 60).floor
      if available >= remaining
        return cursor + remaining * 60
      else
        remaining -= available
        cursor = next_business_start(close)
      end
    end
    cursor
  end

  # Count of business minutes between +from+ and +to+ (0 if +to+ <= +from+).
  def minutes_between(from, to)
    from = from.in_time_zone
    to   = to.in_time_zone
    return 0 if to <= from

    total  = 0
    cursor = next_business_start(from)
    return 0 if cursor >= to

    while cursor < to
      close       = window_close(cursor)
      segment_end = [ close, to ].min
      total += ((segment_end - cursor) / 60).floor
      break if segment_end == to
      cursor = next_business_start(close)
    end
    total
  end
end
