import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCenters from '@salesforce/apex/createEventsLWCController.getCenters';
import getSpecialties from '@salesforce/apex/createEventsLWCController.getSpecialties';
import getAvailableDoctors from '@salesforce/apex/createEventsLWCController.getAvailableDoctors';
import getAvailableTimeSlots from '@salesforce/apex/CreateEventsLWCController.getAvailableTimeSlots';
import createEvent from '@salesforce/apex/createEventsLWCController.createEvent';



export default class CreateEventsLWC extends LightningElement {
    @track step = 0; // Inicialmente mostramos la página inicial

    @track minDate = new Date().toISOString().slice(0, 10);
    @track selectedDate;
    @track selectedCenter;
    @track selectedSpecialty;
    @track centers = [];
    @track specialties = [];

    @track doctors = [];
    @track selectedDoctor;

    @track timeSlots = []; // Lista de horarios disponibles
    @track selectedTimeSlot; // Horario seleccionado

    @track durations = [
        { label: '15 minutos', value: '15' },
        { label: '30 minutos', value: '30' },
        { label: '1 hora', value: '60' },
        { label: '2 horas', value: '120' },
        { label: '4 horas', value: '240' }
    ];
    @track selectedDuration;


    // Definición de las variables para almacenar los datos del formulario
    @track contactFirstName = '';
    @track contactLastName = '';
    @track contactEmail = '';
    @track contactPhone = '';
    @track contactObservations = '';

    @track selectedDoctorName;
    @track selectedCenterName;
    @track selectedStartTime;
    @track selectedEndTime;

    validationErrorInput = false;



    // Propiedad computada para determinar si se muestra la página inicial
    get isInitialPage() {
        return this.step === 0;
    }
    // Estas propiedades computadas determinan cuál de los pasos se muestra
    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }
    get isStep4() { return this.step === 4; }

    nextStep() {
        if (this.step < 4) this.step++;
    }

    prevStep() {
        if (this.step > 1) this.step--;
    }

    startSearch() {
        this.step = 1; // Avanzar a la primera etapa de la búsqueda de la cita
    }

    @wire(getCenters)
    wiredCenters({ error, data }) {
        if (data) {
            this.centers = data.map(center => {
                return {
                    label: center.Name,
                    value: center.Id
                };
            });
        } else if (error) {
        }
    }

    handleDateChange(event) {


        if (new Date(event.detail.value) < new Date(this.minDate)) {

            // Restablecer el valor de la fecha seleccionada
            this.validationErrorInput = true;
        } else {
            // Continuar con el procesamiento normal
            this.validationErrorInput = false;
        }

        this.selectedDate = event.detail.value;

        this.selectedDoctor = null;

        this.selectedDoctorName = null; 

        this.selectedDuration = null;

        this.selectedStartTime = null;
        this.selectedEndTime = null;
        this.selectedTimeSlot = null;
    }

    handleCenterChange(event) {
        this.selectedCenter = event.detail.value;
        const selectedCenter = this.centers.find(center => center.value === this.selectedCenter);
        if (selectedCenter) {
            // Asigna el label del doctor seleccionado a selectedCenterName
            this.selectedCenterName = selectedCenter.label;

            this.selectedSpecialty = null;

            this.selectedDoctor = null;

            this.selectedDoctorName = null; 

            this.selectedDuration = null;

            this.selectedStartTime = null;
            this.selectedEndTime = null;
            this.selectedTimeSlot = null;
        }
    }

    handleSpecialtyChange(event) {
        this.selectedSpecialty = event.detail.value;

        this.selectedDoctor = null;

        this.selectedDoctorName = null; 

        this.selectedDuration = null;

        this.selectedStartTime = null;
        this.selectedEndTime = null;
        this.selectedTimeSlot = null;
    }



    @wire(getSpecialties, { centerId: '$selectedCenter' })
    wiredSpecialties({ error, data }) {
        if (data) {
            this.specialties = data.map(specialty => {
                return { label: specialty, value: specialty };
            });
        } else if (error) {
        }
    }


    @wire(getAvailableDoctors, { centerId: '$selectedCenter', speciality: '$selectedSpecialty', appointmentDate: '$selectedDate' })
    loadDoctors({ error, data }) {
        if (data) {
            this.doctors = data.map(doc => {
                return { label: doc.Name, value: doc.Id };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.doctors = undefined;
        }
    }
    handleDoctorChange(event) {
        this.selectedDoctor = event.detail.value;
        const selectedDoctor = this.doctors.find(doctor => doctor.value === this.selectedDoctor);
        if (selectedDoctor) {
            // Asigna el label del doctor seleccionado a selectedDoctorName
            this.selectedDoctorName = selectedDoctor.label;

            this.selectedDuration = null;

            this.selectedStartTime = null;
            this.selectedEndTime = null;
            this.selectedTimeSlot = null;
        }
    }


    @wire(getAvailableTimeSlots, { doctorId: '$selectedDoctor', centerId: '$selectedCenter', duration: '$selectedDuration', targetDate: '$selectedDate' })
    timeSlots({ error, data }) {
        if (data) {
            this.timeSlots = data;
        } else if (error) {
        }
    }
    
    handleTimeSlotChange(event) {
        this.selectedTimeSlot = event.detail.value;
        if (this.selectedTimeSlot) {
            // Parsea la cadena en un objeto Date
            const startDate = new Date(this.selectedTimeSlot);
            
            // Obtiene la hora y los minutos
            const startHours = startDate.getUTCHours();
            const startMinutes = startDate.getUTCMinutes();
    
            // Formatea la hora y los minutos en una cadena "HH:MM"
            this.selectedStartTime = String(startHours).padStart(2, '0') + ':' + String(startMinutes).padStart(2, '0');
    
            // Suma la duración seleccionada (en minutos) a la hora de inicio
            const durationInMinutes = parseInt(this.selectedDuration, 10); // Asegúrate de que selectedDuration sea un número
            const endDate = new Date(startDate.getTime() + durationInMinutes * 60 * 1000); // Suma la duración en milisegundos
    
            // Obtiene la hora y los minutos de finalización
            const endHours = endDate.getUTCHours();
            const endMinutes = endDate.getUTCMinutes();
    
            // Formatea la hora y los minutos de finalización en una cadena "HH:MM"
            this.selectedEndTime = String(endHours).padStart(2, '0') + ':' + String(endMinutes).padStart(2, '0');
    
        }
    }
    


    handleDurationChange(event) {
        this.selectedDuration = event.detail.value;

        this.selectedStartTime = null;
        this.selectedEndTime = null;
        this.selectedTimeSlot = null;
    }


    handleContactFirstNameChange(event) { 
        this.contactFirstName = event.target.value; 
    }
    handleContactLastNameChange(event) { 
        this.contactLastName = event.target.value; 
    }
    handleContactEmailChange(event) { 
        this.contactEmail = event.target.value; 

        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

        if (emailPattern.test(this.contactEmail)) {
            // Si el correo electrónico es válido, asignar el valor
            this.validationErrorInput = false;
        } else {
            // Si el correo electrónico no es válido, mostrar un mensaje de error y restablecer el campo
            this.validationErrorInput = true;
        }
    }
    handleContactPhoneChange(event) { 
        this.contactPhone = event.target.value; 
    }
    handleContactObservationsChange(event) { 
        this.contactObservations = event.target.value; 
    }


    handleFinish() {


        // Pasa los campos de contacto como parámetros separados
        createEvent({
            doctorId: this.selectedDoctor,
            centerId: this.selectedCenter,
            eventDate: this.selectedDate,
            startTime: this.selectedStartTime,
            endTime: this.selectedEndTime,
            contactFirstName: this.contactFirstName,
            contactLastName: this.contactLastName,
            contactEmail: this.contactEmail,
            contactPhone: this.contactPhone,
            contactObservations: this.contactObservations
        })
        .then(result => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'El proceso ha finalizado correctamente.',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Ha ocurrido un error en el proceso.',
                    variant: 'error',
                }),
            );
        })
        .finally(() => {

            
            this.selectedDate = null;
            this.selectedCenter = null;
            this.selectedSpecialty = null;
            this.selectedDoctor = null;
            this.selectedTimeSlot = null;
            this.doctors = [];
            this.timeSlots = [];
            this.selectedDuration = null;
            this.selectedDoctorName = null; 
            this.selectedCenterName = null;
            
            this.selectedStartTime = null;
            this.selectedEndTime = null;

            this.contactFirstName = null;
            this.contactLastName = null;
            this.contactEmail = null;
            this.contactPhone = null;
            this.contactObservations = null;


            this.step = 0;
        });
    }

    handleCancel() {

        this.selectedDate = null;
        this.selectedCenter = null;
        this.selectedSpecialty = null;
        this.selectedDoctor = null;
        this.selectedTimeSlot = null;
        this.doctors = [];
        this.timeSlots = [];
        this.selectedDuration = null;
        this.selectedDoctorName = null;
        this.selectedCenterName = null;
        
        this.selectedStartTime = null;
        this.selectedEndTime = null;

        this.contactFirstName = null;
        this.contactLastName = null;
        this.contactEmail = null;
        this.contactPhone = null;
        this.contactObservations = null;

        this.step = 0;
    }


    get isNextButtonDisabled() {
        
        
        switch (this.step) {
            case 1:
                return !this.selectedDate || !this.selectedCenter || !this.selectedSpecialty || this.validationErrorInput;
            case 2:
                return !this.selectedDuration || !this.selectedTimeSlot || !this.selectedDoctor || this.validationErrorInput;
            case 3:
                return !this.contactFirstName || !this.contactLastName || !this.contactEmail || !this.contactPhone || !this.contactObservations || this.validationErrorInput;
            
            default:
                return false;
        }
    }
    
    
    
    

}