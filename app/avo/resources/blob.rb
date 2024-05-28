class Avo::Resources::Blob < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :sha256, as: :text
    field :contents, as: :binary
    field :size, as: :number
    field :compression, as: :text
    field :version_data_entries, as: :has_many
    field :data_entry_versions, as: :has_many, through: :version_data_entries
    field :data_entry_rubygems, as: :has_many, through: :data_entry_versions
    field :package_version, as: :has_one
    field :quick_spec_version, as: :has_one
    field :package_spec_version, as: :has_one
  end
end
