# frozen_string_literal: true

module Maintenance
  class ImportGemNamesTask < MaintenanceTasks::Task
    include SemanticLogger::Loggable

    def collection
      Server.all
    end

    def process(server)
      Faraday.get("#{server.url}/names").body.lines(chomp: true).each do |name|
        Rubygem.find_or_create_by!(name: name, server: server)
      end
    end
  end
end
