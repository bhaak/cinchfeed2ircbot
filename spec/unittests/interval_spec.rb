#!/usr/bin/env ruby

require 'cinchfeed2ircbot/interval'

module CinchFeed2IrcBot

describe Interval do
  describe "the constructor" do
    it "should have a default wait time" do
      expect(Interval.new.wait_time).to be > 0
    end

    it "should accept a custom wait time" do
      expect(Interval.new(120).wait_time).to eq 120
    end
  end

  describe "next_interval" do
    it "should return a positive integer" do
      expect(Interval.new.next_interval).to be > 0
    end

    it "should return wait_time after 5 calls" do
      wait_time = 1000
      interval = Interval.new(wait_time)
      4.times { interval.next_interval }
      expect(interval.next_interval).to eq wait_time
    end

    it "should not return an integer greater than wait_time" do
      interval = Interval.new(1)
      5.times { expect(interval.next_interval).to be 1 }
    end

    it "should return increasing intervalls with multiple calls" do
      interval = Interval.new

      first_call = interval.next_interval
      second_call = interval.next_interval
      expect(second_call).to be > first_call

      third_call = interval.next_interval
      expect(third_call).to be > second_call

      fourth_call = interval.next_interval
      expect(fourth_call).to be > third_call
    end

    it "should be able to be reset" do
      interval = Interval.new
      first_call = interval.next_interval

      5.times { interval.next_interval }
      expect(interval.next_interval).to be > first_call

      interval.reset

      expect(interval.next_interval).to eq first_call
    end
  end
end

end
