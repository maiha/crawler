require "./spec_helper"

describe Crawl::Lookup do
  describe ".parse?" do
    it "[css]" do
      Crawl::Lookup.parse?(["css:div"]).try(&.map(&.to_s)).should eq ["css:div"]
    end

    it "[regex]" do
      Crawl::Lookup.parse?(["regex: href=\"(.*?)\""]).try(&.map(&.to_s)).should eq ["regex:href=\"(.*?)\""]
    end

    it "[strip]" do
      Crawl::Lookup.parse?(["strip:"]).try(&.map(&.to_s)).should eq ["strip:"]
    end

    it "[xxx] # raises Crawl::Config::Error" do
      expect_raises(Crawl::Config::Error, /invalid pattern 'xxx:'/) do
        Crawl::Lookup.parse?(["xxx:"])
      end
    end
  end
end
