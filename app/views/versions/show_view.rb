# frozen_string_literal: true

class Versions::ShowView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::NumberToHumanSize
  extend Literal::Attributes
  attribute :version, Version
  def template
    h1 { @version.full_name }
    p { @version.server.url }
    p { link_to @version.rubygem.name, rubygem_path(@version.rubygem.name)}
    p { link_to "quick gemspec", blob_path(@version.spec_sha256) } if @version.spec_sha256.present?
    p { link_to ".gem", blob_path(@version.sha256) } if @version.sha256
    p { link_to ".gem metadata (gemspec)", blob_path(@version.metadata_blob.sha256) } if @version.metadata_blob
    if @version.version_import_error
      p do
        plain "Import error:"
        br
        code { @version.version_import_error.error }
      end
    end
    @version.attributes.each do |key, value|
      next if key.end_with?("_id")
      p { "#{key}: #{value}" }
    end
    p { "Gem size: #{number_to_human_size @version.package_blob.size}" } if @version.package_blob

    h2 { "Version Data Entries" }
    p { "Total: #{@version.version_data_entries.count.to_fs(:delimited)}" }
    p { "Unpacked size: #{number_to_human_size @version.data_blobs.sum(:size)}" }
    table do
      thead do
        tr do
          th { "Full Name" }
          th { "Mode" }
          th { "UID" }
          th { "GID" }
          th { "Mtime" }
          th { "Linkname" }
          th { "Size" }
          th { "SHA" }
        end
      end

      tbody do
        @version.version_data_entries.includes(:blob_excluding_contents).find_each do |entry|
          tr do
            td { link_to entry.full_name, rubygem_file_history_path(@version.rubygem.name, path: entry.full_name) }
            td { entry.mode.to_s(8) }
            td { entry.uid.to_s(8) }
            td { entry.gid.to_s(8) }
            td { entry.mtime }
            td { entry.linkname }
            td { number_to_human_size entry.blob_excluding_contents&.size }
            td { link_to entry.blob_excluding_contents.sha256, blob_path(entry.blob_excluding_contents.sha256) if entry.blob_excluding_contents }
          end
        end
      end
    end

  end
end
