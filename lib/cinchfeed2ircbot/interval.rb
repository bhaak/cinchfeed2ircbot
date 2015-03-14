module CinchFeed2IrcBot

class Interval
  attr_accessor :wait_time

  def initialize(wait_time=600)
    # default wait time is 10 minutes
    @wait_time = wait_time
    @calls = 0
  end

  def next_interval
    @calls += 1
    return @wait_time if @calls >= 5

    intervals = [0,10,45,120,360,900]

    return [@wait_time, intervals[@calls]].min
  end

  def reset
    @calls = 0
  end
end
end
