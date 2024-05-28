class Avo::Resources::Server < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :url, as: :text
    field :rubygems, as: :has_many
    field :versions, as: :has_many, through: :rubygems
    field :compact_index_entries, as: :has_many
  end
end
