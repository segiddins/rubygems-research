class Avo::Resources::VersionImportError < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :version_id, as: :number
    field :error, as: :text
    field :version, as: :belongs_to
  end
end
