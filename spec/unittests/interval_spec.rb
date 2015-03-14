#!/usr/bin/env ruby

require 'cinchfeed2ircbot/interval'

describe Interval do
  describe "the constructor" do
    it "should have a default wait time" do
      Interval.new.wait_time.should > 0
    end

    it "should accept a custom wait time" do
      Interval.new(120).wait_time == 120
    end
  end

  describe "next_interval" do
    it "should return a positive integer" do
      Interval.new.next_interval.should > 0
    end

    it "should return wait_time after 5 calls" do
      wait_time = 1000
      interval = Interval.new(wait_time)
      4.times { interval.next_interval }
      interval.next_interval.should == wait_time
    end

    it "should not return an integer greater than wait_time" do
      interval = Interval.new(1)
      5.times { interval.next_interval.should == 1 }
    end

    it "should return increasing intervalls with multiple calls" do
      interval = Interval.new

      first_call = interval.next_interval
      second_call = interval.next_interval
      second_call.should > first_call

      third_call = interval.next_interval
      third_call.should > second_call

      fourth_call = interval.next_interval
      fourth_call.should > third_call
    end

    it "should be able to be reset" do
      interval = Interval.new
      first_call = interval.next_interval

      5.times { interval.next_interval }
      interval.next_interval > first_call

      interval.reset

      interval.next_interval == first_call
    end
  end
end
