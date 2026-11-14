class DialectSubstitutionsController < ApplicationController
  before_action :require_admin
  before_action :set_substitution, only: %i[edit update destroy]

  def index
    @substitutions = DialectSubstitution.ordered
  end

  def new
    @substitution = DialectSubstitution.new
  end

  def create
    @substitution = DialectSubstitution.new(substitution_params)
    if @substitution.save
      redirect_to dialect_substitutions_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @substitution.update(substitution_params)
      redirect_to dialect_substitutions_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @substitution.destroy
    redirect_to dialect_substitutions_path, notice: t(".destroyed")
  end

  private

  def set_substitution
    @substitution = DialectSubstitution.find(params[:id])
  end

  def substitution_params
    params.require(:dialect_substitution).permit(:other_form, :mayo_form, :other_source, :mayo_source, :note)
  end
end
