# frozen_string_literal: true

module Maintenance
  class ImportRubygemsFromDumpTask < MaintenanceTasks::Task
    include SemanticLogger::Loggable

    def collection
      Dump::Rubygem.all.order(id: :asc).in_batches(of: 1000)
    end

    def process(batch)
      @server ||= Server.sole
      Rubygem.where(server: @server).import(
        batch.map { |dump_rubygem| {name: dump_rubygem.name} }
      )
    rescue => e
      logger.error "Failed to process #{element.inspect}: #{e}", error: e
      raise
    end
  end
end
