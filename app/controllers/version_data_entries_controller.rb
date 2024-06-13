# frozen_string_literal: true

class VersionDataEntriesController < ApplicationController
  layout -> { ApplicationLayout }

  def search
    search = VersionDataEntry
      .preload(:version, :rubygem, :blob_excluding_contents)
      .ransack!(params[:q])
    search.build_grouping if search.groupings.blank?
    search.build_condition if search.conditions.blank?
    search.build_sort if search.sorts.blank?
    distinct = params[:distinct]
    result = search.result(distinct:)

    pagy, version_data_entries = pagy(result)
    render VersionDataEntries::SearchView.new(
      search:,
      pagy:,
      version_data_entries:
    )
  end
end
