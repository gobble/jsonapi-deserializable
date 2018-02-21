module JSONAPI
  module Deserializable
    class RelatedResources
      def initialize(resources)
        return if resources.nil?
        @resources = grouped_resources_by_types(resources)
        sort_resources(@resources)
      end

      def get_resources_for(related_resource)
        type = related_resource["type"]
        resources[type].bsearch do |resource|
          related_resource["id"] <=> resource["id"]
        end
      end

      private

      attr_reader :resources, :grouped_resources

      def grouped_resources_by_types(resources)
        resources.group_by do |resource|
          resource["type"]
        end
      end

      def sort_resources(resources)
        resources.each_pair do |_type, grouped_resources|
          grouped_resources.sort! do |a, b|
            a["id"] <=> b["id"]
          end
        end
      end
    end
  end
end
