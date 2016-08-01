#!/usr/bin/env ruby

require 'rbtv/sendeplan'

describe "Sendeplan::Show" do

  let(:show_data) {
    {
      :timeStart => "2016-08-01T12:25:00+02:00",
      :show => "Almost Daily",
      :title => "Almost Daily #248",
      :timeEnd => "2016-08-01T12:38:33+02:00",
      :topic => "Fett & Feilschen",
      :length => 3693,
      :game => "",
      :type => "wiederholung",
      :id => 13200277
    }
  }
  let(:show) { Sendeplan::Show.new(show_data) }

  describe "#titel" do
    it "shows the title and subtitle of the show" do
      expect(show.title).to eq "Almost Daily #248 - Fett & Feilschen"
    end
  end

  describe "#start_time" do
    it "returns the start time of the show" do
      expect(show.start_time).to eq "12:25"
    end
  end

  describe "#end_time" do
    it "returns the end time of the show" do
      expect(show.end_time).to eq "12:38"
    end
  end

  describe "#to_s" do
    it "outputs a textual description of the show" do
      expect(show.to_s).to eq "[W] Almost Daily #248 - Fett & Feilschen von 12:25 bis 12:38 Uhr"
    end

    it "outputs a textual description of the show" do
      show_data[:type] = ""
      expect(show.to_s).to eq "Almost Daily #248 - Fett & Feilschen von 12:25 bis 12:38 Uhr"
    end
  end
end
