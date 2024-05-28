class ServersController < ApplicationController
  before_action :set_server, only: %i[ show hook ]

  # GET /servers or /servers.json
  def index
    @servers = Server.all.strict_loading
  end

  # GET /servers/1 or /servers/1.json
  def show
    @pagy, @rubygems = pagy(@server.rubygems.order(name: :asc).strict_loading)
  end

  def hook
    hook_params = params.permit(:name, :version, :platform, :version_created_at, :sha256, metadata: {})
    name = hook_params.require(:name)
    version = hook_params.require(:version)
    platform = hook_params.require(:platform)
    uploaded_at = hook_params.require(:version_created_at)
    sha256 = hook_params.require(:sha256)
    metadata = hook_params.require(:metadata)

    hashed_api_key = ENV,fetch("RUBYGEMS_HASHED_API_KEY") do
      raise "RUBYGEMS_HASHED_API_KEY is not set" if Rails.env.production?
      ""
    end

    auth = Digest::SHA256.hexdigest([name, version, hashed_api_key].join)
    unless auth == headers['Authorization']
      logger.warn "Invalid Authorization header", name: name, version: version, platform: platform, expected: auth, actual: headers['Authorization']
      return head :bad_request
    end

    rubygem = Rubygem.where(server: @server).find_or_create_by!(name: params[:name])
    version = rubygem.versions.create_with(uploaded_at:, sha256:)
      .find_or_create_by!(version:, platform:)

    # TODO: spec_sha256
    if version.sha256 != sha256
      render json: { error: "sha256 mismatch", version: version.as_json, expected: version.sha256, actual: sha256 }, status: :bad_request
    end

    DownloadVersionBlobsJob.perform_later(version:)

    render json: version, status: :created
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_server
      @server = Server.strict_loading.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def server_params
      params.require(:server).permit(:url)
    end
end
