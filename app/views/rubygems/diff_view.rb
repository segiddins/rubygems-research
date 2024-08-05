# frozen_string_literal: true

class Rubygems::DiffView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo

  extend Literal::Properties
  prop :rubygem, Rubygem
  prop :v1, Version
  prop :v2, Version

  def template
    h2 { "Gemspec" }

    render DiffComponent.new(data_old: @v1.metadata_blob.decompressed_contents, data_new: @v2.metadata_blob.decompressed_contents)

    h2 { "Files" }

    all_files.each do |name, (o, n)|
      h3 { link_to name, diff_rubygem_file_history_path(@rubygem.name, path: name, v1: @v1.number, v2: @v2.number) }
      if o&.blob != n&.blob
        data_old = o&.blob&.decompressed_contents || ""
        data_new = n&.blob&.decompressed_contents || ""
        render DiffComponent.new(data_old:, data_new:)
      end
    end
  end

  def all_files
    h = Hash.new { |h, k| h[k] = [nil, nil] }

    @v1.version_data_entries.each do |entry|
      h[entry.full_name][0] = entry
    end
    @v2.version_data_entries.each do |entry|
      h[entry.full_name][1] = entry
    end

    h = h.sort_by(&:first)
    # h.prepend([:gemspec, [@v1.metadata_blob, @v2.metadata_blob]])
  end
end
