require 'jsonapi/deserializable/relationship'
require 'jsonapi/deserializable/resource'
require 'jsonapi/deserializable/document'
require 'logger'

module JSONAPI
  module Deserializable

    class << self

      def log
        @logger ||= initialize_logger
      end

      private

      def initialize_logger
        logger = Logger.new(log_output)
        logger.level = Logger::DEBUG
        logger.datetime_format = "%Y-%m-%d %H:%M:%S "
        logger
      end

      def log_output
        if defined?(Rails)
          "log/#{Rails.env}.log"
        else
          STDOUT
        end
      end
    end
  end
end
