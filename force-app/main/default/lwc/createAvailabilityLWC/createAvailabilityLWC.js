import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDoctors from '@salesforce/apex/CreateAvailabilityLWCController.getDoctors';
import getCenters from '@salesforce/apex/CreateAvailabilityLWCController.getCenters';
import createAvailabilities from '@salesforce/apex/CreateAvailabilityLWCController.createAvailabilities';



export default class CreateAvailabilityLWC extends LightningElement {
    @track step = 0; // Inicialmente mostramos la página inicial
    availability;

    @track searchTerm = '';
    @track searchResults = [];
    @track selectedDoctors = [];

    @track startDate = null; // Fecha de inicio seleccionada
    @track endDate = null;   // Fecha de fin seleccionada  

    @track centers = [];
    @track selectedCenter;
    @track selectedCenterName;

    @track selectedStartHour; // Hora de inicio seleccionada
    @track selectedEndHour;   // Hora de fin seleccionada

    // Opciones para las horas de inicio y fin (de 6 a. m. a 12 p. m.)
    startHourOptions = Array.from({ length: 18 }, (_, i) => ({ label: `${6 + i}:00`, value: `${6 + i}:00` }));
    endHourOptions = Array.from({ length: 18 }, (_, i) => ({ label: `${7 + i}:00`, value: `${7 + i}:00` }));


    // Propiedad computada para determinar si se muestra la página inicial
    get isInitialPage() {
        return this.step === 0;
    }
    // Estas propiedades computadas determinan cuál de los pasos se muestra
    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }


    nextStep() {
        if (this.step < 2) this.step++;
    }

    prevStep() {
        if (this.step > 1) this.step--;
    }

    startSearch() {
        this.step = 1; // Avanzar a la primera etapa de la búsqueda de la cita
    }

     handleCancel() {

        this.searchTerm = '';
        this.searchResults = [];
        this.selectedDoctors = [];
    
        this.startDate = null; // Fecha de inicio seleccionada
        this.endDate = null;   // Fecha de fin seleccionada  
    
        this.selectedCenter = null;
        this.selectedCenterName = null;
    
        this.selectedStartHour = null; // Hora de inicio seleccionada
        this.selectedEndHour = null;  // Hora de fin seleccionada
    
        this.step = 0;
    }

    connectedCallback() {
        // Obtener los centros médicos cuando el componente se conecta
        getCenters()
            .then(result => {
                this.centers = result.map(center => ({ label: center.Name, value: center.Id }));
            })
            .catch(error => {
            });
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        // Si el término de búsqueda tiene menos de 3 caracteres, limpiar los resultados de la búsqueda
        if (this.searchTerm.length < 3) {
            this.searchResults = [];
            return;
        }
        
        // Llamar al método Apex con el término de búsqueda
        getDoctors({ searchTerm: this.searchTerm })
        .then(result => {
            // Filtrar los resultados para excluir los médicos que ya han sido seleccionados
            this.searchResults = result.filter(doctor => !this.selectedDoctors.some(selected => selected.Id === doctor.Id));
        })
        .catch(error => {
    });
    
    }

    handleCenterChange(event) {
        this.selectedCenter = event.detail.value;
        const selectedCenter = this.centers.find(center => center.value === this.selectedCenter);
        if (selectedCenter) {
            // Asigna el label del centro seleccionado a selectedCenterName
            this.selectedCenterName = selectedCenter.label;
        }
    }

    handleDoctorSelect(event) {
        const doctorId = event.target.name;
        const doctor = this.searchResults.find(doc => doc.Id === doctorId);
        this.selectedDoctors.push(doctor);

        // Eliminar el médico seleccionado de los resultados de búsqueda
        this.searchResults = this.searchResults.filter(doc => doc.Id !== doctorId);

    }

    handleDoctorDeselect(event) {
        const doctorId = event.detail.name;
    
        // Encontrar el médico que fue deseleccionado
        const deselectedDoctor = this.selectedDoctors.find(doc => doc.Id === doctorId);
    
        // Eliminar el médico deseleccionado de los médicos seleccionados
        this.selectedDoctors = this.selectedDoctors.filter(doc => doc.Id !== doctorId);
    
        // Volver a agregar el médico deseleccionado a los resultados de búsqueda
        this.searchResults.push(deselectedDoctor);

    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }
    
    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleStartHourChange(event) {
        this.selectedStartHour = event.detail.value;
    }
    
    handleEndHourChange(event) {
        this.selectedEndHour = event.detail.value;
    }

    handleFinish() {
        // Llamar al método Apex con los datos seleccionados
        createAvailabilities({
            selectedCenter: this.selectedCenter,
            selectedCenterName: this.selectedCenterName,
            startDate: this.startDate,
            endDate: this.endDate,
            selectedStartHour: this.selectedStartHour,
            selectedEndHour: this.selectedEndHour,
            selectedDoctorIds: this.selectedDoctors.map(doctor => doctor.Id)
        })
        .then(() => {
            // Mostrar un mensaje de éxito y realizar otras acciones si es necesario
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'El proceso ha finalizado correctamente.',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
                // Intentar extraer el mensaje de error de diferentes ubicaciones posibles
            let errorMessage = 'Ocurrió un error al crear las disponibilidades';
            if (error.body) {
                if (error.body.message) {
                    errorMessage = error.body.message;
                } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                    errorMessage = error.body.pageErrors[0].message;
                } else if (error.body.fieldErrors && Object.keys(error.body.fieldErrors).length > 0) {
                    errorMessage = error.body.fieldErrors[Object.keys(error.body.fieldErrors)[0]][0].message;
                }
            }

            // Mostrar un toast con el mensaje de error
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error',
                })
            );
        })
        .finally(() => {

            this.searchTerm = '';
            this.searchResults = [];
            this.selectedDoctors = [];
        
            this.startDate = null; // Fecha de inicio seleccionada
            this.endDate = null;   // Fecha de fin seleccionada  
        
            this.selectedCenter = null;
            this.selectedCenterName = null;
        
            this.selectedStartHour = null; // Hora de inicio seleccionada
            this.selectedEndHour = null;  // Hora de fin seleccionada
        

            this.step = 0;
        });
    }

    get isNextButtonDisabled() {

        switch (this.step) {
            case 1:
                return this.selectedDoctors.length === 0  || !this.selectedCenter || !this.selectedStartHour || !this.selectedEndHour || !this.startDate || !this.endDate;
           
            default:
                return false;
        }
    }

}