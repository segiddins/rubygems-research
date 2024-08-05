# frozen_string_literal: true

class VersionsTableComponent < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::NumberToHumanSize

  extend Literal::Properties
  prop :versions, Object

  def view_template
    table(class: "table-auto") do
      thead(class: "border-b") do
        tr do
          th {  }
          th { "Version" }
          th { "Platform" }
          th { "Size" }
          th { "Uploaded" }
          th { "Indexed" }
          th { "Extensions" }
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
            td { version.extensions.presence&.inspect }
          end
        end
      end
    end
  end
end
