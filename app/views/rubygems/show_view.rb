# frozen_string_literal: true

class Rubygems::ShowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  extend Literal::Attributes
  attribute :rubygem, Rubygem
  attribute :versions, Object
  attribute :pagy, Pagy
  attribute :platform, Object
  def template
    p(style: "color: green") { helpers.notice }
    h1 { @rubygem.name }
    h2 { @platform } if @platform
    unsafe_raw helpers.render @rubygem

    # p {
    #   plain "Info file"
    #   pre {@rubygem.server.compact_index_entries.find_by(path: "info/#{@rubygem.name}").pretty_inspect}
    # }

    platforms = @rubygem.versions.distinct.unscope(:order).pluck(:platform)
    unless platforms == ["ruby"]
      div do
        p { "Platforms" }
        ul do
          platforms.each { |pl| li { link_to pl, {platform: pl} } }
        end
      end
    end

    render VersionsTableComponent.new(versions: @versions)

    unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
  end
end
