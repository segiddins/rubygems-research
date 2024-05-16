# frozen_string_literal: true

class VersionImportErrorsController < ApplicationController
  layout -> { ApplicationLayout }

  def index
    counts = VersionImportError.group(:error).pluck("error", "count(version_id)")
    pagy, version_import_errors = pagy(VersionImportError.all)
    render VersionImportErrors::IndexView.new(pagy:, version_import_errors:, counts:)
  end
end
