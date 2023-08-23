/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
public with sharing class createEventsLWCController {
    @AuraEnabled(cacheable=true)
    public static List<Centro_Estetico__c> getCenters() {
        return [SELECT Id, Name FROM Centro_Estetico__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getSpecialties(Id centerId) {
        // List<String> specialties = new List<String>();
        // Schema.DescribeSObjectResult objectDescribe = Centro_Estetico__c.sObjectType.getDescribe();
        // Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get('Especialidades_Disponibles__c').getDescribe();
        // List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        
        // for (Schema.PicklistEntry picklistValue : picklistValues) {
        //     specialties.add(picklistValue.getValue());
        // }

        // return specialties;


        List<String> specialties = new List<String>();
    
        // Consulta el centro médico seleccionado por su ID
        Centro_Estetico__c selectedCenter = [SELECT Especialidades_Disponibles__c FROM Centro_Estetico__c WHERE Id = :centerId LIMIT 1];
    
        // Si hay especialidades disponibles, las divide en una lista
        if (selectedCenter.Especialidades_Disponibles__c != null) {
            specialties = selectedCenter.Especialidades_Disponibles__c.split(';');
        }
    
        return specialties;
    }

    @AuraEnabled(cacheable=true)
    public static List<Medico__c> getAvailableDoctors(Id centerId, String speciality, Date appointmentDate) {

        List<Medico__c> doctors = new List<Medico__c>(); // Obtener la disponibilidad de los médicos basada en el centro y la fecha
    
        for (Disponibilidad_Medica__c availability : [
            SELECT Medico_Asociado__r.Id, Medico_Asociado__r.Name, Medico_Asociado__r.Especialidades__c 
            FROM Disponibilidad_Medica__c 
            WHERE Centro_Estetico_Asociado__c = :centerId 
            AND CALENDAR_YEAR(Fecha_hora_de_Inicio__c) = :appointmentDate.year() 
            AND CALENDAR_MONTH(Fecha_hora_de_Inicio__c) = :appointmentDate.month() 
            AND DAY_IN_MONTH(Fecha_hora_de_Inicio__c) <= :appointmentDate.day() 
            AND CALENDAR_YEAR(Fecha_hora_de_Fin__c) = :appointmentDate.year() 
            AND CALENDAR_MONTH(Fecha_hora_de_Fin__c) = :appointmentDate.month() 
            AND DAY_IN_MONTH(Fecha_hora_de_Fin__c) >= :appointmentDate.day() ORDER BY Medico_Asociado__r.Name 
        ]) {
            // Verificar si la especialidad requerida está en la lista de especialidades del médico
            Medico__c doctor = availability.Medico_Asociado__r;
            if (doctor.Especialidades__c != null && doctor.Especialidades__c.contains(speciality)) {
                doctors.add(doctor);
            }
        }
        return doctors;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<TimeSlotWrapper> getAvailableTimeSlots(Id doctorId, Id centerId, Integer duration, Date targetDate) {
        // Consultar la disponibilidad del médico en el centro específico para la fecha dada
        // Convertir la fecha objetivo a DateTime para compararla con el campo de fecha y hora
        DateTime targetDateTimeStart = DateTime.newInstance(targetDate, Time.newInstance(0, 0, 0, 0));
        DateTime targetDateTimeEnd = targetDateTimeStart.addDays(1);

        // Consultar la disponibilidad del médico en el centro específico para la fecha dada
        List<Disponibilidad_Medica__c> disponibilidadList = [
            SELECT Fecha_hora_de_Inicio__c, Fecha_hora_de_Fin__c 
            FROM Disponibilidad_Medica__c 
            WHERE Medico_Asociado__c = :doctorId 
            AND Centro_Estetico_Asociado__c = :centerId
            AND Fecha_hora_de_Inicio__c >= :targetDateTimeStart
            AND Fecha_hora_de_Inicio__c < :targetDateTimeEnd
        ];

        List<Event> existingEvents = [
            SELECT StartDateTime, EndDateTime
            FROM Event
            WHERE Medico_Asociado__c = :doctorId
            AND StartDateTime >= :targetDateTimeStart
            AND EndDateTime < :targetDateTimeEnd
        ];
           
        // Lista para almacenar los horarios disponibles
        List<TimeSlotWrapper> timeSlots = new List<TimeSlotWrapper>();

        // Iterar a través de la disponibilidad y encontrar horarios que se ajusten a la duración
        for (Disponibilidad_Medica__c disponibilidad : disponibilidadList) {
            DateTime startTime = disponibilidad.Fecha_hora_de_Inicio__c;
            DateTime endTime = disponibilidad.Fecha_hora_de_Fin__c;
        
            // Iterar a través de los horarios posibles de 15 en 15 minutos
            while (startTime.addMinutes(duration) <= endTime) {
                // Comprobar si este horario se superpone con algún evento existente
                Boolean isOverlapping = false;
                for (Event existingEvent : existingEvents) {
                    if (startTime < existingEvent.EndDateTime && startTime.addMinutes(duration) > existingEvent.StartDateTime) {
                        isOverlapping = true;
                        break;
                    }
                }
                
                // Si no se superpone con eventos existentes, añadirlo a la lista
                if (!isOverlapping) {
                    timeSlots.add(new TimeSlotWrapper(startTime.format('hh:mm a'), startTime));
                }
        
                startTime = startTime.addMinutes(15);
            }
        }
        

        return timeSlots;
    }

    public class TimeSlotWrapper {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public DateTime value { get; set; }

        public TimeSlotWrapper(String label, DateTime value) {
            this.label = label;
            this.value = value;
        }
    }


    @AuraEnabled
    public static String createEvent(String doctorId, String centerId, String eventDate, String startTime, String endTime, String contactFirstName, String contactLastName, String contactEmail, String contactPhone, String contactObservations) {


        // Divide la cadena de fecha en sus componentes
        String[] dateParts = eventDate.split('-');
        Integer eventYear = Integer.valueOf(dateParts[0]);
        Integer eventMonth = Integer.valueOf(dateParts[1]);
        Integer eventDay = Integer.valueOf(dateParts[2]);

        // Crea la fecha utilizando los componentes separados
        Date parsedDate = Date.newInstance(eventYear, eventMonth, eventDay);

        // Divide las cadenas de hora en horas y minutos
        String[] startTimeParts = startTime.split(':');
        Integer startHour = Integer.valueOf(startTimeParts[0]);
        Integer startMinute = Integer.valueOf(startTimeParts[1]);
        
        String[] endTimeParts = endTime.split(':');
        Integer endHour = Integer.valueOf(endTimeParts[0]);
        Integer endMinute = Integer.valueOf(endTimeParts[1]);

        // Combina la fecha con las horas y minutos
        DateTime startDateTime = DateTime.newInstance(parsedDate.year(), parsedDate.month(), parsedDate.day(), startHour, startMinute, 0);
        DateTime endDateTime = DateTime.newInstance(parsedDate.year(), parsedDate.month(), parsedDate.day(), endHour, endMinute, 0);



        // Busca un Contacto o Lead existente por correo electrónico
        List<List<SObject>> searchResults = [FIND :contactEmail IN EMAIL FIELDS RETURNING Contact(Id), Lead(Id)];
        List<Contact> contacts = (List<Contact>)searchResults[0];
        List<Lead> leads = (List<Lead>)searchResults[1];
        Id contactId;

        if (!contacts.isEmpty()) {
            // Utiliza el ID del Contacto existente
            contactId = contacts[0].Id;
            // Actualiza el campo de observaciones del Contacto existente

            Contact existingContact = new Contact(Id = contactId, Description = contactObservations); 
            update existingContact;
        } else if (!leads.isEmpty()) {
            // Convierte el Lead en un Contacto
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leads[0].Id);
            // Actualiza el campo de observaciones del Lead existente antes de la conversión si es necesario
            Lead existingLead = new Lead(Id = leads[0].Id, Description = contactObservations);
            update existingLead;
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            contactId = lcr.getContactId();

                    
        } else {
            Contact newContact = new Contact(
            FirstName = contactFirstName,
            LastName = contactLastName,
            Email = contactEmail,
            Phone = contactPhone,
            Description = contactObservations 
            );

            // Valida los permisos CRUD antes de insertar el contacto
            if (Schema.sObjectType.Contact.isCreateable()) {
                insert newContact;
            } else {
                return 'No tienes permiso para crear contactos.';
            }
            contactId = newContact.Id;
        }


        // Crea el registro de evento
        Event newEvent = new Event(
            Subject = contactFirstName + ' ' + contactLastName + ' - ' + eventDate + ' ' + startTime,
            StartDateTime = startDateTime,
            EndDateTime = endDateTime,
            Medico_Asociado__c = doctorId,
            Centro_Estetico_Asociado__c = centerId,
            WhoId = contactId
        );
    
        // Valida los permisos CRUD antes de insertar el evento
        if (Schema.sObjectType.Event.isCreateable()) {
            insert newEvent;
            return 'Evento creado exitosamente. Id: ' + newEvent.Id;
        } else {
            return 'No tienes permiso para crear eventos.';
        }
    
    }
    

}