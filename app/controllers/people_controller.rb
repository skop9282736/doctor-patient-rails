class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update destroy]

  # GET /people or /people.json
  def index
    @people = Person.order(id: :DESC).paginate(page: params[:page], per_page: 10)
  end

  # GET /people/1 or /people/1.json
  def show; end

  # GET /people/new
  def new
    @person = Person.new
  end

  # GET /people/1/edit
  def edit; end

  # POST /people or /people.json
  def create
    @person = Person.new(person_params)
    if @person.commit
      redirect_to person_url(@person), notice: 'Person was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /people/1 or /people/1.json
  def update
    @person.assign_attributes(person_params)
    if @person.commit
      redirect_to person_url(@person), notice: 'Person was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /people/1 or /people/1.json
  def destroy
    @person.delete
    redirect_to people_url, notice: 'Person was successfully destroyed.'
  rescue ActiveRecord::InvalidForeignKey
    redirect_to person_url(@person), alert: 'The person has a patient or doctor associated with it.'
  rescue ActiveRecord::ActiveRecordError
    redirect_to person_url(@person), alert: "something's wrong"
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_person
    @person = Person.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to people_url, alert: 'Person not found'
  end

  # Only allow a list of trusted parameters through.
  def person_params
    params.require(:person).permit(:first_name, :last_name)
  end
end
