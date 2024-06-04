class RubygemsController < ApplicationController
  before_action :set_server
  before_action :set_rubygem, only: %i[ show diff ]

  # GET /rubygems or /rubygems.json
  def index
    @pagy, @rubygems = pagy(Rubygem.all)
  end

  # GET /rubygems/1 or /rubygems/1.json
  def show
    platform = params.permit(:platform).fetch(:platform, nil)
    versions = @rubygem.versions.order(uploaded_at: :desc).includes(:package_blob).strict_loading
    versions = versions.where(platform:) if platform
    @pagy, @versions = pagy(versions)
    render Rubygems::ShowView.new(rubygem: @rubygem, versions: @versions, platform:, pagy: @pagy)
  end

  def diff
    v1 = @rubygem.versions.includes(:metadata_blob, version_data_entries: :blob).find_by!(number: params[:v1])
    v2 = @rubygem.versions.includes(:metadata_blob, version_data_entries: :blob).find_by!(number: params[:v2])

    render Rubygems::DiffView.new(rubygem: @rubygem, v1:, v2:)
  end

  def search
    search = Rubygem.all.ransack!(params[:q])
    search.build_grouping if search.groupings.blank?
    search.build_condition if search.conditions.blank?
    search.build_sort if search.sorts.blank?
    distinct = params[:distinct]
    result = search.result(distinct:)

    pagy, rubygems = pagy(result)
    render Rubygems::SearchView.new(
      search:,
      pagy:,
      rubygems:
    )
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rubygem
      @rubygem = @server.rubygems.find_by!(name: params[:name])
    end

    # Only allow a list of trusted parameters through.
    def rubygem_params
      params.require(:rubygem).permit(:server_id, :name)
    end

    def set_server
      if params[:server_id].present?
        @server = Server.find(server_id)
      else
        @server = Server.find_by!(url: "https://rubygems.org")
      end
    end
end
