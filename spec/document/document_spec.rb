require "spec_helper"

describe JSONAPI::Deserializable::Document do

  describe ".call" do
    it "logs the data being processed" do
      document_deseriaizer = build_document_deserializer(
        relationship_to_include: nil
      )
      logger = stub_logger

      document_deseriaizer.call(payload_without_included_data)

      expect(logger).to have_received(:info)
    end

    context "when resource_deserializer is present" do
      it "calls the deserializer when deserializing the document" do
        stub_logger
        deserializer = resource_deserializer
        document_deseriaizer = build_document_deserializer(
          relationship_to_include: nil,
          deserializer: deserializer
        )

        document_deseriaizer.call(payload_without_included_data)

        expect(deserializer).to have_received(:call).once
      end
    end

    context "when resource_deserializer is not present" do
      it "raises NoDeserializableResource error" do
        stub_logger
        document_deseriaizer = Class.new(JSONAPI::Deserializable::Document) do
          resource_deserializer nil
        end
        error = JSONAPI::Deserializable::Errors::NoDeserializableResource

        expect do
          document_deseriaizer.call(payload_without_included_data)
        end.to raise_error(error)
      end

      context "when relationship_to_include is present" do
        it "includes the related resource in the data hash" do
          stub_logger
          deserializer = resource_deserializer
          document_deseriaizer = build_document_deserializer(
            relationship_to_include: "test1",
            deserializer: deserializer
          )
          doc = payload_document("test", 1, "test1", 2)
          resource_with_related_data = {
            "type" => "test",
            "id" => 1,
            "relationships" => {
              "test1" => {
                "data" => {
                  "type" => "test1",
                  "id" => 2,
                  "attributes" => {
                    "name" => "test relationship 1",
                  },
                },
              },
            },
          }

          document_deseriaizer.call(doc)

          expect(deserializer).to have_received(:call).with(
            resource_with_related_data
          )
        end
      end

      context "when relationship_to_include is not present" do
        it "includes all the relationships it can find in the data hash" do
          stub_logger
          deserializer = resource_deserializer
          document_deseriaizer = Class.new(JSONAPI::Deserializable::Document) do
            resource_deserializer deserializer
          end
          doc = {
            "data" =>
              {
                "type" => "test",
                "id" => 1,
                "relationships" => {
                  "test1" => {
                    "data" => {
                      "type" => "test1",
                      "id" => 2,
                    },
                  },
                  "test2" => {
                    "data" => {
                      "type" => "test2",
                      "id" => 3,
                    },
                  },
                },
              },
            "included" => [
              {
                "type" => "test1",
                "id" => 2,
                "attributes" => {
                  "name" => "test relationship 1",
                },
              },
              {
                "type" => "test2",
                "id" => 3,
                "attributes" => {
                  "name" => "test relationship 2",
                },
              },
            ],
          }
          resource_with_related_data = {
            "type" => "test",
            "id" => 1,
            "relationships" => {
              "test1" => {
                "data" => {
                  "type" => "test1",
                  "id" => 2,
                  "attributes" => {
                    "name" => "test relationship 1",
                  },
                },
              },
              "test2" => {
                "data" => {
                  "type" => "test2",
                  "id" => 3,
                  "attributes" => {
                    "name" => "test relationship 2",
                  },
                },
              },
            },
          }

          document_deseriaizer.call(doc)

          expect(deserializer).to have_received(:call).with(
            resource_with_related_data
          )
        end
      end
    end

  end

  describe ".process_each_resource" do
    context "when document is an array" do
      it "yields deserialized resources" do
        stub_logger
        document_deseriaizer = build_document_deserializer(
          relationship_to_include: "test1"
        )
        doc = payload_document("test", 1, "test1", 2)

        expect do |block|
          document_deseriaizer.process_each_resource(doc, &block)
        end.to yield_with_args
      end
    end

    context "when document is not an array" do
      it "does not yield to block" do
        stub_logger
        
        document_deseriaizer = build_document_deserializer(
          relationship_to_include: "test1"
        )
        doc = payload_without_included_data(type: "test1")

        expect do |block|
          document_deseriaizer.process_each_resource(doc, &block)
        end.not_to yield_with_args
      end
    end
  end

  def resource_deserializer
    deserializer = class_double("Deserializer", call: {})
    allow(deserializer).to receive(:call)
    deserializer
  end

  def stub_logger
    logger = Logger.new(STDOUT)
    allow(Logger).to receive(:new).and_return(logger)
    allow(logger).to receive(:info)
    logger
  end

  def payload_without_included_data(type: "test1")
    {
      "data" => {
        "type" => type,
        "id" => 1,
      },
    }
  end

  def payload_document(type, id, relationship_type, relationship_id)
    {
      "data" =>
        [{
          "type" => type,
          "id" => id,
          "relationships" => {
            "#{relationship_type}" => {
              "data" => {
                "type" => relationship_type,
                "id" => 2,
              },
            },
          },
        }],
      "included" => [
        {
          "type" => relationship_type,
          "id" => relationship_id,
          "attributes" => {
            "name" => "test relationship 1",
          },
        },
      ],
    }
  end

  def build_document_deserializer(relationship_to_include: "test1", 
                                  deserializer: nil)
    deserializer ||= resource_deserializer
    Class.new(JSONAPI::Deserializable::Document) do
      resource_deserializer deserializer
      relationship_to_include relationship_to_include
    end
  end
end
