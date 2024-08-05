# frozen_string_literal: true

class Versions::IndexView < ApplicationView
  extend Literal::Properties
  prop :versions, Object
  prop :pagy, Object

  def template
    h1 { "Versions" }
    div(id: "versions") do
      render VersionsTableComponent.new(versions: @versions)

      unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
    end
  end
end
