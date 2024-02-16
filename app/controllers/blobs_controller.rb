class BlobsController < ApplicationController
  before_action :set_blob, only: %i[ show raw ]

  # GET /blobs or /blobs.json
  def index
    @pagy, @blobs = pagy(Blob.order(size: :desc).strict_loading)
  end

  # GET /blobs/1 or /blobs/1.json
  def show
    @version_data_entries_pagy, @version_data_entries = pagy(@blob.version_data_entries.includes(:version, :version => :rubygem).order("versions.uploaded_at DESC").strict_loading)
  end

  def raw
    render plain: @blob.decompressed_contents
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blob
      @blob = Blob.find_by!(sha256: params[:sha256])
    end

    # Only allow a list of trusted parameters through.
    def blob_params
      params.require(:blob).permit(:sha256, :contents, :size, :compression)
    end
end
