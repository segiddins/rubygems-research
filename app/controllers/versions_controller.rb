# frozen_string_literal: true

class VersionsController < ApplicationController
  layout -> { ApplicationLayout }

  def show
    version = Version.includes(:rubygem, :server, :version_data_entries, :metadata_blob, :package_blob, :version_import_error).strict_loading.find(params[:id])
    render Versions::ShowView.new(version:)
  end

  def index
    pagy, versions = pagy(Version.includes(:rubygem).strict_loading.order(uploaded_at: :desc))
    render Versions::IndexView.new(pagy:, versions:)
  end
end
