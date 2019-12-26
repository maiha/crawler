require "./spec_helper"

module Crawl::Str2xxx
  describe Crawl::Str2xxx do
    it "#str2range_int" do
      str2range_int("10").should eq(10..10)
      str2range_int("10..50").should eq(10..50)
      str2range_int("10-50").should eq(10..50)
      str2range_int("1k..5000").should eq(1000..5000)
      str2range_int("3..11M").should eq(3..11000000)

      expect_raises(ArgumentError) do
        str2range_int("1..2..3")
      end
    end

    it "#str2range_float" do
      str2range_float("1").should eq(1.0..1.0)
      str2range_float("1.5").should eq(1.5..1.5)
      str2range_float("2..2.5").should eq(2.0..2.5)
      str2range_float("2-5").should eq(2.0..5.0)
      str2range_float("1k..5000").should eq(1000.0..5000.0)
      str2range_float("3..11M").should eq(3.0..11000000.0)

      expect_raises(ArgumentError) do
        str2range_float("1.0..2.0..3.0")
      end
    end
  end
end
