class RubygemsController < ApplicationController
  before_action :set_rubygem, only: %i[ show edit update destroy ]

  # GET /rubygems or /rubygems.json
  def index
    @rubygems = Rubygem.all
  end

  # GET /rubygems/1 or /rubygems/1.json
  def show
  end

  # GET /rubygems/new
  def new
    @rubygem = Rubygem.new
  end

  # GET /rubygems/1/edit
  def edit
  end

  # POST /rubygems or /rubygems.json
  def create
    @rubygem = Rubygem.new(rubygem_params)

    respond_to do |format|
      if @rubygem.save
        format.html { redirect_to rubygem_url(@rubygem), notice: "Rubygem was successfully created." }
        format.json { render :show, status: :created, location: @rubygem }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rubygem.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rubygems/1 or /rubygems/1.json
  def update
    respond_to do |format|
      if @rubygem.update(rubygem_params)
        format.html { redirect_to rubygem_url(@rubygem), notice: "Rubygem was successfully updated." }
        format.json { render :show, status: :ok, location: @rubygem }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rubygem.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rubygems/1 or /rubygems/1.json
  def destroy
    @rubygem.destroy!

    respond_to do |format|
      format.html { redirect_to rubygems_url, notice: "Rubygem was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rubygem
      @rubygem = Rubygem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def rubygem_params
      params.require(:rubygem).permit(:server_id, :name)
    end
end
