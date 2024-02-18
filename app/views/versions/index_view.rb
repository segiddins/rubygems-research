# frozen_string_literal: true

class Versions::IndexView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  extend Literal::Attributes
  attribute :versions, Object
  attribute :pagy, Object

  def template
    h1 { "Versions" }
    div(id: "versions") do
      @versions.each do |version|
        render version
        link_to "show version", version
      end

      unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
    end
  end
end
