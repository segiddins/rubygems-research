# frozen_string_literal: true

class Rubygems::SearchView < ApplicationView

  include Phlex::Rails::Helpers::LinkTo

  extend Literal::Properties
  prop :rubygems, Object
  prop :pagy, Object
  prop :search, Object

  def view_template
    h1 { "Rubygems Search" }

    pre { plain @rubygems.unscope(:limit, :offset).to_sql }

    render RansackAdvancedSearchComponent.new(
      search: @search,
      search_url: search_rubygems_url,
      condition_associations: %i[versions],
      sort_associations: %i[versions]
    )

    ul do
      @rubygems.each do |rubygem|
        li do
          link_to rubygem.name, rubygem.name
        end
      end
    end
  end
end
