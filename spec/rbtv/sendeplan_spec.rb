#!/usr/bin/env ruby

require 'rbtv/sendeplan'

describe "Sendeplan::Show" do
  before :each do
    xml = <<-XML
      <div class="show">
        <div>
        <span class="scheduleTime">12:25</span>
        <div class="showDetails">
          <h4>RBTV</h4>
          <span class="game">Something</span>
          <div class="showInfo">
            <span class="showDuration">13 Min.</span>
            <span class="smallBtn">wiederholung</span>
          </div>
        </div>
      </div>
    XML
    @xml = Nokogiri::HTML(xml)
  end

  describe "#titel" do
    it "shows the title and subtitle of the show" do
      show = Sendeplan::Show.new(@xml)
      expect(show.title).to eq "RBTV - Something"
    end
  end

  describe "#start_time" do
    it "parses the start time of the show" do
      show = Sendeplan::Show.new(@xml)
      expect(show.start_time).to eq "12:25"
    end
  end

  describe "#end_time" do
    it "parses the duration and adds it to start_time" do
      show = Sendeplan::Show.new(@xml)
      expect(show.end_time).to eq "12:38"
    end

    it "parses a duration with hours and second" do
      @xml.at_css(".showDuration").child.content = "3 Std. 13 Min."
      binding.pry
      show = Sendeplan::Show.new(@xml)
      expect(show.end_time).to eq "15:38"
    end
  end

  describe "#to_s" do
    it "outputs a textual description of the show" do
      show = Sendeplan::Show.new(@xml)
      expect(show.to_s).to eq "[W] RBTV - Something von 12:25 bis 12:38 Uhr"
    end
  end
end
