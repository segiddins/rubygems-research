class Avo::Resources::VersionDataEntry < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :version_id, as: :number
    field :blob_id, as: :number
    field :full_name, as: :text
    field :name, as: :text
    field :mode, as: :number
    field :uid, as: :number
    field :gid, as: :number
    field :mtime, as: :date_time
    field :linkname, as: :text
    field :sha256, as: :text
    field :version, as: :belongs_to
    field :rubygem, as: :belongs_to
    field :blob_excluding_contents, as: :belongs_to
  end
end
