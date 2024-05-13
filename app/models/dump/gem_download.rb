# == Schema Information
#
# Table name: gem_downloads
#
#  id         :integer          not null, primary key
#  count      :bigint
#  rubygem_id :integer          not null
#  version_id :integer          not null
#
# Indexes
#
#  index_gem_downloads_on_count                                (count)
#  index_gem_downloads_on_rubygem_id_and_version_id            (rubygem_id,version_id) UNIQUE
#  index_gem_downloads_on_version_id_and_rubygem_id_and_count  (version_id,rubygem_id,count)
#
class Dump::GemDownload < Dump::Record
  belongs_to :rubygem, class_name: "Dump::Rubygem"
  belongs_to :version, class_name: "Dump::Version"
end
