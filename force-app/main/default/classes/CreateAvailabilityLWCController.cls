/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
public with sharing class CreateAvailabilityLWCController {

    @AuraEnabled(cacheable=true)
    public static List<Medico__c> getDoctors(String searchTerm) {
        // Si el término de búsqueda tiene menos de 3 caracteres, retornar una lista vacía
        if (searchTerm == null || searchTerm.length() < 3) {
            return new List<Medico__c>();
        }

        String query = 'SELECT Id, Name FROM Medico__c WHERE Name LIKE :searchTerm ORDER BY Name LIMIT 5';
        searchTerm = '%' + searchTerm + '%'; // Agregar comodines para la búsqueda parcial

        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Centro_Estetico__c> getCenters() {
        return [SELECT Id, Name FROM Centro_Estetico__c ORDER BY Name];
    }


    @AuraEnabled
    public static void createAvailabilities(String selectedCenter, String selectedCenterName, String startDate, String endDate, String selectedStartHour, String selectedEndHour, List<Id> selectedDoctorIds) {
        // Convertir las fechas de inicio y fin en objetos de fecha
        Date startDateObj = Date.valueOf(startDate);
        Date endDateObj = Date.valueOf(endDate);

            // Convertir las horas de inicio y fin en objetos Time
            Integer startHour = Integer.valueOf(selectedStartHour.split(':')[0]);
            Integer endHour = Integer.valueOf(selectedEndHour.split(':')[0]);
            Time startTime = Time.newInstance(startHour, 0, 0, 0);
            Time endTime = Time.newInstance(endHour, 0, 0, 0);

        // Crear una lista de objetos que representan las disponibilidades a crear
        List<Disponibilidad_Medica__c> availabilities = new List<Disponibilidad_Medica__c>();
        
        // Recorrer cada médico seleccionado
        for (Id doctorId : selectedDoctorIds) {
            // Recorrer cada franja de fechas seleccionada
            Date currentDate = startDateObj;
            while (currentDate <= endDateObj) {
                // Obtener el nombre del médico (puede ser optimizado con una consulta previa)
                Medico__c doctor = [SELECT Name FROM Medico__c WHERE Id = :doctorId LIMIT 1];

                // Crear un objeto que representa la disponibilidad
                Disponibilidad_Medica__c availability = new Disponibilidad_Medica__c(
                    Name = doctor.Name + ' + ' + selectedCenterName + ' + ' + currentDate,
                    Centro_Estetico_Asociado__c = selectedCenter,
                    Medico_Asociado__c = doctorId,
                    Fecha_hora_de_Inicio__c = DateTime.newInstance(currentDate, startTime),
                    Fecha_hora_de_Fin__c = DateTime.newInstance(currentDate, endTime)
            
                );
                availabilities.add(availability);

                // Avanzar al siguiente día
                currentDate = currentDate.addDays(1);
            }
        }

        // Insertar los registros
        insert availabilities;
    }
}