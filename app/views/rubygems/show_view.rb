# frozen_string_literal: true

class Rubygems::ShowView < ApplicationView
include Phlex::Rails::Helpers::LinkTo
include Phlex::Rails::Helpers::NumberToHumanSize
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

    platforms = @rubygem.versions.distinct.pluck(:platform)
    unless platforms == ["ruby"]
      div do
        p { "Platforms" }
        ul do
          platforms.each { |pl| li { link_to pl, {platform: pl} } }
        end
      end
    end

    table do
      thead do
        tr do
          th {  }
          th { "Version" }
          th { "Platform" }
          th { "Size" }
          th { "Uploaded" }
          th { "Indexed" }
        end
      end
      tbody do
        @versions.each do |version|
          tr do
            td { link_to version.full_name, version }
            td { version.number }
            td { version.platform }
            td { number_to_human_size version.package_blob&.size }
            td { version.uploaded_at.to_fs }
            td { version.indexed.inspect }
          end
        end
      end
    end

    unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
  end
end
