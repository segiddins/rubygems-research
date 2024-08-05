# frozen_string_literal: true

class FileHistory::DiffView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  extend Literal::Properties
  prop :v1_entry, Object
  prop :v2_entry, Object

  def template
    h1 do
      version_data_entry @v1_entry
      whitespace
      plain "vs"
      whitespace
      version_data_entry @v2_entry
    end

    p {
      span{ "- old" }
      br
      span{ "+ new" }
    }


    render DiffComponent.new(data_old: @v1_entry.blob.decompressed_contents, data_new: @v2_entry.blob.decompressed_contents)
  end

  def version_data_entry(entry)
    plain entry.full_name
    whitespace
    plain "in"
    whitespace
    link_to entry.version.full_name, entry.version
  end
end
