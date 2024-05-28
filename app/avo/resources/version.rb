class Avo::Resources::Version < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :rubygem_id, as: :number
    field :number, as: :text
    field :platform, as: :text
    field :spec_sha256, as: :text
    field :sha256, as: :text
    field :metadata, as: :code
    field :metadata_blob_id, as: :number
    field :position, as: :number
    field :version_data_entries_count, as: :number
    field :uploaded_at, as: :date_time
    field :indexed, as: :boolean
    field :rubygem, as: :belongs_to
    field :server, as: :belongs_to
    field :package_blob, as: :has_one
    # field :package_blob_with_contents, as: :has_one
    field :version_data_entries, as: :has_many
    field :version_import_error, as: :has_one
  end
end
