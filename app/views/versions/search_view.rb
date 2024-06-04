# frozen_string_literal: true

class Versions::SearchView < ApplicationView

  include Phlex::Rails::Helpers::LinkTo

  extend Literal::Attributes
  attribute :versions, Object
  attribute :pagy, Object
  attribute :search, Object

  def view_template
    h1 { "Versions Search" }

    pre { plain @versions.unscope(:limit, :offset).to_sql }

    render RansackAdvancedSearchComponent.new(
      search: @search,
      search_url: search_versions_url,
      condition_associations: %i[rubygem server package_blob version_import_error quick_spec_blob version_data_entries data_blobs],
      sort_associations: %i[rubygem package_blob metadata_blob]
    )

    render VersionsTableComponent.new(versions: @versions)
    unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
  end
end
