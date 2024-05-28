class Avo::Resources::Rubygem < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :server_id, as: :number
    field :name, as: :text
    field :server, as: :belongs_to
    field :versions, as: :has_many
    field :version_data_entries, as: :has_many, through: :versions
  end
end
