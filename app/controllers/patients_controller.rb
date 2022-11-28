class PatientsController < ApplicationController
  before_action :set_patient, only: %i[show edit update destroy]

  # GET /patients
  def index
    @patients = Patient.includes(:person, :doctor).order('person_id DESC')
  end

  # GET /patients/1
  def show; end

  # GET /patients/new
  def new
    @patient = Patient.new
  end

  # GET /patients/1/edit
  def edit; end

  # POST /patients
  def create
    @patient = Patient.new(patient_params)

    if @patient.commit
      redirect_to @patient, notice: 'Patient was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /patients/1
  def update
    if @patient.update(patient_params)
      redirect_to @patient, notice: 'Patient was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /patients/1
  def destroy
    @patient.destroy
    redirect_to patients_url, notice: 'Patient was successfully destroyed.'
  rescue ActiveRecord::InvalidForeignKey
    redirect_to patient_url(@patient), alert: 'This Patient has appointments that you must delete before.'
  rescue ActiveRecord::ActiveRecordError
    redirect_to patient_url(@patient), alert: "something's wrong"
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_patient
    @patient = Patient.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def patient_params
    params.require(:patient).permit(:upi, :person_id, :doctor_id)
  end
end