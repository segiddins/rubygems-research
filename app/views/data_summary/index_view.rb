# frozen_string_literal: true

class DataSummary::IndexView < ApplicationView
include Phlex::Rails::Helpers::LinkTo
include Phlex::Rails::Helpers::NumberToHumanSize

def limit = 10
  def template
    Server.find_each do |s|
      h2 { link_to s.url, s }
    end
    table do
      thead do
        th {"Table"}
        th {"Count"}
        th {"Size"}
      end
      tbody do
        [Rubygem, Version, VersionDataEntry, Blob].each do |model|
          tr do
            td { model.table_name }
            td { model.count.to_fs(:delimited) }
            # td { model.connection.select_value('SELECT SUM("pgsize") FROM "dbstat" WHERE name= ?;', model.table_name) }
            td
          end
        end
      end
    end

    h3 { "Indexed versions" }

    plain Version.where.associated(:metadata_blob).count.to_fs(:delimited)

    h3 { "Blob storage" }

    render TableComponent.new(contents: Blob.connection.execute('select count(*), sum(length(contents)), sum(size), compression, contents is null from blobs group by 4, 5')) do |table|
      table.column("Count") { |row| plain row[0].to_fs(:delimited) }
      table.column("Stored size") { |row| plain number_to_human_size row[1] }
      table.column("Size") { |row| plain number_to_human_size row[2] }
      table.column("Compression") { |row| plain row[3] }
      table.column("Contents is null") { |row| plain row[4] }
    end if false || true

    h3 { "Biggest gems" }

    render TableComponent.new(contents: Blob.excluding_contents.where.associated(:package_version).select("length(blobs.contents) as length").order('size desc').includes(package_version: :rubygem).limit(limit)) do |table|
      table.column("SHA256") { |b| link_to b.sha256, blob_path(b.sha256) }
      table.column("Length") { |b| number_to_human_size b.length }
      table.column("Size") { |b| number_to_human_size b.size }
      table.column("Gem") { |b| link_to b.package_version.full_name, version_path(b.package_version) }
    end

    h3 { "Biggest files" }

    render TableComponent.new(contents: Blob.excluding_contents.select("length(blobs.contents) as length").where.missing(:package_version).order('length(contents) desc').limit(limit)) do |table|
      table.column("SHA256") { |b| link_to b.sha256, blob_path(b.sha256) }
      table.column("Length") { |b| number_to_human_size b.length }
      table.column("Size") { |b| number_to_human_size b.size }
    end

    h3 { "Most referenced files" }

    render TableComponent.new(contents: VersionDataEntry.group(:blob).limit(limit).order('count_all desc').count) do |table|
      table.column("Ref count") { |_, c| plain c.to_fs(:delimited) }
      table.column("SHA256") { |blob, _| link_to blob.sha256, blob_path(blob.sha256) if blob }
      table.column("Size") { |b, _| number_to_human_size b&.size }
    end
  end
end
