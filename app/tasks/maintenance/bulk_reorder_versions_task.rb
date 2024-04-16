# frozen_string_literal: true

module Maintenance
  class BulkReorderVersionsTask < MaintenanceTasks::Task
    def collection
      Rubygem.all.includes(:versions)
    end

    def process(element)
      element.bulk_reorder_versions
    end
  end
end
