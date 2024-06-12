class ServersController < ApplicationController
  before_action :set_server, only: %i[ show hook ]
  skip_before_action :verify_authenticity_token, only: :hook

  # GET /servers or /servers.json
  def index
    @servers = Server.all.strict_loading
  end

  # GET /servers/1 or /servers/1.json
  def show
    @pagy, @rubygems = pagy(@server.rubygems.order(name: :asc).strict_loading)
  end

  def hook
    hook_params = params.permit(:name, :version, :platform, :version_created_at, :spec_sha256, :sha, :yanked, metadata: {})
    name = hook_params.require(:name)
    number = hook_params.require(:version)
    platform = hook_params.require(:platform)
    uploaded_at = hook_params.require(:version_created_at)
    sha256 = hook_params.require(:sha)
    spec_sha256 = params.fetch(:spec_sha, nil)
    metadata = hook_params.fetch(:metadata, {})
    yanked = hook_params.fetch(:yanked, false)

    hashed_api_key = ENV.fetch("RUBYGEMS_HASHED_API_KEY") do
      raise "RUBYGEMS_HASHED_API_KEY is not set" if Rails.env.production?
      ""
    end

    auth = Digest::SHA256.hexdigest([name, number, hashed_api_key].join)
    unless auth == request.headers['Authorization']
      logger.warn "Invalid Authorization header", name: name, version: number, platform: platform, expected: auth, actual: request.headers['Authorization']
      return head :unauthorized
    end

    rubygem = Rubygem.where(server: @server).find_or_create_by!(name: params[:name])
    version = rubygem.versions.create_with(uploaded_at:, sha256:, metadata:, spec_sha256:)
      .find_or_create_by!(number:, platform:)

    # TODO: spec_sha256
    if version.sha256 != sha256
      render json: { error: "sha256 mismatch", version: version.as_json, expected: version.sha256, actual: sha256 }, status: :conflict
    end

    if spec_sha256.present? && version.spec_sha256.present? && version.spec_sha256 != spec_sha256
      render json: { error: "spec_sha256 mismatch", version: version.as_json, expected: version.spec_sha256, actual: spec_sha256 }, status: :conflict
    elsif spec_sha256.present? && version.spec_sha256.nil?
      version.update!(spec_sha256:)
    end

    rubygem.bulk_reorder_versions

    if yanked
      logger.info "Yanking version #{version.full_name}"
      # TODO: add yanked_at
      version.update!(indexed: false)
    else
      version.update!(indexed: true) unless version.indexed
      DownloadVersionBlobsJob.perform_later(version:)
    end

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
