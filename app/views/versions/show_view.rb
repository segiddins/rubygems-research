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
    p { link_to "quick gemspec", blob_path(@version.spec_sha256) } if @version.spec_sha256
    p { link_to ".gem", blob_path(@version.sha256) } if @version.sha256
    p { link_to ".gem metadata (gemspec)", blob_path(@version.metadata_blob.sha256) } if @version.metadata_blob
    @version.attributes.each do |key, value|
      p { "#{key}: #{value}" }
    end
    p { "Gem size: #{number_to_human_size @version.package_blob.size}" }

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
        end
      end

      tbody do
        @version.version_data_entries.includes(:blob).find_each do |entry|
          tr do
            td do
              if entry.blob
                link_to entry.full_name, blob_path(entry.blob.sha256)
              else
                entry.full_name
              end
            end
            td { entry.mode.to_s(8) }
            td { entry.uid.to_s(8) }
            td { entry.gid.to_s(8) }
            td { entry.mtime }
            td { entry.linkname }
            td { number_to_human_size entry.blob&.size }
          end
        end
      end
    end

  end
end
