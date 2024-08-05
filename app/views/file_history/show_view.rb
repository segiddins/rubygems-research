# frozen_string_literal: true

class FileHistory::ShowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  extend Literal::Properties
  prop :entries, Object
  prop :rubygem, Rubygem
  prop :path, String

  def template
    h1 { "File History" }
    h2 do
      code { @path }
      whitespace
      plain "in"
      whitespace
      link_to @rubygem.name, rubygem_path(@rubygem.name)
    end


    p { "#{grouped_entries.size} total files" }
    grouped_entries.each_with_index do |(blob, versions), idx|
      div do
        first = versions.first
        last = versions.drop(1).last

        h4 do
          link_to first.full_name, first
          if last
              whitespace
              plain "to"
              whitespace
              link_to last.full_name, last
              whitespace
              plain "(#{versions.size} versions)"
          end
        end
        if blob
          link_to "Download", raw_blob_path(blob.sha256)
          if idx > 0 && (prev = grouped_entries[idx - 1]) && prev.first
            br
            link_to "Diff with previous", diff_rubygem_file_history_path(path: @path, v1: prev.last.last.slug, v2: versions.first.slug)
          end
        else
          plain "Not present"
        end
      end
    end
  end

  def grouped_entries
    entries = @entries.to_h { [_1.version_id, _1] }
    @rubygem.versions.sort.each_with_object([]) do |version, acc|
      entry = entries[version.id]
      if acc.none? || entry&.blob_id != acc.last.first&.id
        acc << [entry&.blob_excluding_contents, [version]]
      else
        acc.last.last << version
      end
    end
  end
end
