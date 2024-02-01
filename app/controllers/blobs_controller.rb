class BlobsController < ApplicationController
  before_action :set_blob, only: %i[ show edit update destroy ]

  # GET /blobs or /blobs.json
  def index
    @blobs = Blob.all
  end

  # GET /blobs/1 or /blobs/1.json
  def show
  end

  # GET /blobs/new
  def new
    @blob = Blob.new
  end

  # GET /blobs/1/edit
  def edit
  end

  # POST /blobs or /blobs.json
  def create
    @blob = Blob.new(blob_params)

    respond_to do |format|
      if @blob.save
        format.html { redirect_to blob_url(@blob), notice: "Blob was successfully created." }
        format.json { render :show, status: :created, location: @blob }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @blob.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blobs/1 or /blobs/1.json
  def update
    respond_to do |format|
      if @blob.update(blob_params)
        format.html { redirect_to blob_url(@blob), notice: "Blob was successfully updated." }
        format.json { render :show, status: :ok, location: @blob }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blob.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blobs/1 or /blobs/1.json
  def destroy
    @blob.destroy!

    respond_to do |format|
      format.html { redirect_to blobs_url, notice: "Blob was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blob
      @blob = Blob.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def blob_params
      params.require(:blob).permit(:sha256, :contents, :size, :compression)
    end
end
