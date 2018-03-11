# frozen_string_literal: true

require "redfish_client/connector"

RSpec.describe RedfishClient::Connector do
  context ".new" do
    it "raises error for bad URI" do
      expect do
        described_class.new("bad_uri")
      end.to raise_error(ArgumentError)
    end

    it "returns a connector instance" do
      expect(described_class.new("http://example.com")).to(
        be_a RedfishClient::Connector
      )
    end
  end

  before(:all) do
    Excon.defaults[:mock] = true
    # Stubs are pushed onto a stack - they match from bottom-up. So place
    # least specific stub first in order to avoid staring blankly at errors.
    Excon.stub({ host: "example.com" },                     { status: 200 })
    Excon.stub({ host: "example.com", path: "/missing" },   { status: 404 })
    Excon.stub({ host: "example.com", path: "/forbidden" }, { status: 403 })
    Excon.stub({ host: "example.com", path: "/post", method: :post },
               { status: 201 })
    Excon.stub({ host: "example.com", path: "/delete", method: :delete },
               { status: 204 })
  end

  after(:all) do
    Excon.stubs.clear
  end

  subject { described_class.new("http://example.com") }

  context "#get" do
    it "returns response instance" do
      expect(subject.get("/")).to be_a Excon::Response
    end

    it "keeps host stored" do
      expect(subject.get("/missing").status).to eq(404)
      expect(subject.get("/forbidden").status).to eq(403)
      expect(subject.get("/").status).to eq(200)
    end
  end

  context "#post" do
    it "returns response instance" do
      expect(subject.post("/post")).to be_a Excon::Response
    end

    it "send post request" do
      expect(subject.post("/post", '{"key": "value"}').status).to eq(201)
    end
  end

  context "#delete" do
    it "returns response instance" do
      expect(subject.delete("/delete")).to be_a Excon::Response
    end

    it "send post request" do
      expect(subject.delete("/delete").status).to eq(204)
    end
  end
end
