require "jsonapi/deserializable/errors/errors"
require "jsonapi/deserializable/document/related_resources"

module JSONAPI
  module Deserializable
    class Document
      def initialize(payload)
        @data = payload["data"]
        @resource_deserializer = self.class.resource_deserializer_klass
        @included_resources = payload["included"]
        @related_resources = RelatedResources.new(included_resources)
        @relationship_to_include = retrieve_included_relationship_keys
      end

      class << self

        attr_reader(
          :resource_deserializer_klass,
          :relationship_to_include_keys
        )

        def call(payload)
          new(payload).to_a
        end

        def process_each_resource(payload, &block)
          new(payload).each_resource(&block)
        end

        private

        def resource_deserializer(klass)
          @resource_deserializer_klass = klass
        end

        def relationship_to_include(*keys)
          @relationship_to_include_keys = keys
        end
      end

      def to_a
        fail Errors::NoDeserializableResource unless deserializer_present?
        deserialize
        if data.is_a? Array
          process_resources_collection
        else
          log(data)
          resource_deserializer.call(data)
        end
      end

      def each_resource(&block)
        fail Utils::NoDeserializableResource unless deserializer_present?
        return unless data.is_a? Array
        data.each do |resource|
          map_related_resource_for(resource)
          log(resource)
          yield resource_deserializer.call(resource)
        end
      end

      private

      attr_reader(
        :resource_deserializer,
        :data,
        :included_resources,
        :relationship_to_include,
        :related_resources
      )

      def deserialize
        return if no_included_relationship?
        if data.is_a? Array
          map_related_resources
        else
          map_related_resource_for data
        end
      end

      def retrieve_included_relationship_keys
        self.class.relationship_to_include_keys || default_options
      end

      def default_options
        return if no_included_relationship?
        resource_relationships.keys
      end

      def resource_relationships
        if data.is_a? Array
          data[0]["relationships"]
        else
          data["relationships"]
        end
      end

      def map_related_resources
        data.each do |resource|
          map_related_resource_for resource
        end
      end

      def map_related_resource_for(resource)
        return if relationship_to_include.nil?
        relationships = resource["relationships"]
        if !relationships.nil?
          relationship_to_include.each do |key|
            related_data = relationships[key]["data"]
            relationships[key]["data"] = merge_included_data(related_data)
          end
        end
      end

      def merge_included_data(resource_data)
        if resource_data.is_a? Array
          get_related_resources_collection(resource_data)
        else
          related_resources.get_resources_for(resource_data)
        end
      end

      def get_related_resources_collection(resource_data)
        resource_data.map do |resource|
          related_resources.get_resources_for(resource)
        end
      end

      def no_included_relationship?
        included_resources.nil? || included_resources.empty?
      end

      def deserializer_present?
        !resource_deserializer.nil?
      end

      def process_resources_collection
        data.map do |resource|
          log(resource)
          resource_deserializer.call(resource)
        end
      end

      def log(resource)
        message = "#{self.class}: Deserializing #{resource}"
        JSONAPI::Deserializable.log.info(message)
      end
    end
  end
end


