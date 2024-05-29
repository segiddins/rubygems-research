# frozen_string_literal: true

class VersionsController < ApplicationController
  layout -> { ApplicationLayout }

  def show
    version = Version.includes(:rubygem, :server, :version_data_entries, :metadata_blob, :package_blob, :version_import_error).strict_loading.find(params[:id])
    pagy, version_data_entries = pagy(version.version_data_entries.includes(:blob_excluding_contents), items: 1000)
    render Versions::ShowView.new(version:, version_data_entries:, pagy:)
  end

  def index
    pagy, versions = pagy(Version.includes(:rubygem, :package_blob).strict_loading.order(uploaded_at: :desc), items: 50)
    render Versions::IndexView.new(pagy:, versions:)
  end
end
