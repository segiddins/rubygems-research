class ServersController < ApplicationController
  before_action :set_server, only: %i[ show ]

  # GET /servers or /servers.json
  def index
    @servers = Server.all.strict_loading
  end

  # GET /servers/1 or /servers/1.json
  def show
    @pagy, @rubygems = pagy(@server.rubygems.order(name: :asc).strict_loading)
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
