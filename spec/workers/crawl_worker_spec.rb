require 'sidekiq/testing'

RSpec.describe Sledgehammer::CrawlWorker, sidekiq: :fake do

  before(:example) do
    fixture_directory = File.expand_path('../../fixtures', __FILE__)
    Typhoeus.stub('http://www.example.com').and_return Typhoeus::Response.new(code: 200, body: File.read(File.join(fixture_directory, 'example_com.html')))
    Typhoeus.stub('http://www.example.com/testing').and_return Typhoeus::Response.new(code: 200, body: File.read(File.join(fixture_directory, 'example_com_testing.html')))
    Typhoeus.stub('http://www.example2.com').and_return Typhoeus::Response.new(code: 200, body: File.read(File.join(fixture_directory, 'example2_com.html')))
  end

  let(:worker) { Sledgehammer::CrawlWorker.new }

  describe "#perform" do
    it "finds all e-mail addresses on the first site" do
      worker.perform(['http://www.example.com'])
      expect(Sledgehammer::Contact.count).to eq(3)
    end

    it "doesn't work when the depth limit is hit" do
      worker.perform(['http://www.example.com'], 2, 2)
      expect(Sledgehammer::Contact.count).to eq(0)
    end

    it "crawls all pages and finds e-mails on them" do
      Sidekiq::Testing.inline! do
        worker.perform(['http://www.example.com'])
        expect(Sledgehammer::Contact.count).to eq(5)
        expect(Sledgehammer::Page.count).to eq(3)
      end
    end
  end
end
