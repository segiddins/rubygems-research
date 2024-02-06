# frozen_string_literal: true

class FileHistory::ShowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  extend Literal::Attributes
  attribute :entries, Object
  attribute :rubygem, Rubygem
  attribute :path, String
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
    grouped_entries.each do |blob, versions|
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
        else
          plain "Not present"
        end
      end
    end
  end

  def grouped_entries
    @rubygem.versions.sort.each_with_object([]) do |version, acc|
      entry = @entries.find { _1.version_id == version.id }
      if acc.none? || entry&.blob_id != acc.last.first&.id
        acc << [entry&.blob, [version]]
      else
        acc.last.last << version
      end
    end
  end
end
