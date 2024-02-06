# frozen_string_literal: true

class Rubygems::ShowView < ApplicationView
include Phlex::Rails::Helpers::LinkTo
  extend Literal::Attributes
  attribute :rubygem, Rubygem
  attribute :versions, Object
  attribute :pagy, Pagy
  def template
    p(style: "color: green") { helpers.notice }
    h1 { @rubygem.name }
    unsafe_raw helpers.render @rubygem
    table do
      thead do
        tr do
          th {  }
          th { "Version" }
          th { "Platform" }
        end
      end
      tbody do
        @versions.each do |version|
          tr do
            td { link_to version.full_name, version }
            td { version.number }
            td { version.platform }
          end
        end
      end
    end

    unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
  end
end
