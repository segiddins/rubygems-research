# frozen_string_literal: true

class VersionsController < ApplicationController
  layout -> { ApplicationLayout }

  def show
    version = Version.includes(:rubygem, :server, :metadata_blob, :package_blob, :version_import_error).strict_loading.find(params[:id])
    pagy, version_data_entries = pagy(version.version_data_entries.includes(:blob_excluding_contents), items: 1000)
    render Versions::ShowView.new(version:, version_data_entries:, pagy:)
  end

  def gemspec
    version = Version.includes(:metadata_blob).strict_loading.find(params[:id])
    render plain: version.gemspec.to_ruby
  end

  def index
    pagy, versions = pagy(Version.includes(:rubygem, :package_blob).strict_loading.order(uploaded_at: :desc), items: 50)
    render Versions::IndexView.new(pagy:, versions:)
  end

  def search
    search = Version
      .preload(:rubygem, :package_blob)
      .ransack!(params[:q])
    search.build_grouping if search.groupings.blank?
    search.build_condition if search.conditions.blank?
    search.build_sort if search.sorts.blank?
    distinct = params[:distinct]
    result = search.result(distinct:)

    pagy, versions = pagy(result)
    render Versions::SearchView.new(
      search:,
      pagy:,
      versions:
    )
  end
end
