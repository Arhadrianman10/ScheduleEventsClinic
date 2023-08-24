/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
@isTest
private class TestCreateAvailabilityLWCController {
    @isTest static void testGetDoctors() {
        // Preparar datos de prueba
        Medico__c medico = new Medico__c(Name='Dr. Test');
        insert medico;

        // Probar con un término de búsqueda válido
        List<Medico__c> doctors = CreateAvailabilityLWCController.getDoctors('Dr.');
        System.assertEquals(1, doctors.size(), 'Debería encontrar un médico');

        // Probar con un término de búsqueda no válido (menos de 3 caracteres)
        doctors = CreateAvailabilityLWCController.getDoctors('D');
        System.assertEquals(0, doctors.size(), 'No debería encontrar médicos con términos de búsqueda cortos');
    }

    @isTest static void testGetCenters() {
        // Preparar datos de prueba
        Centro_Estetico__c centro = new Centro_Estetico__c(Name='Centro Test');
        insert centro;

        // Probar la recuperación de centros
        List<Centro_Estetico__c> centers = CreateAvailabilityLWCController.getCenters();
        System.assertEquals(1, centers.size(), 'Debería encontrar un centro estético');
    }


    @isTest static void testCreateAvailabilities() {
        // Preparar datos de prueba
        Centro_Estetico__c centro = new Centro_Estetico__c(Name='Centro Test');
        insert centro;
        
        Medico__c medico = new Medico__c(Name='Dr. Test');
        insert medico;
        
        String selectedCenter = centro.Id;
        String selectedCenterName = centro.Name;
        String startDate = '2023-08-26';
        String endDate = '2023-08-27';
        String selectedStartHour = '08:00';
        String selectedEndHour = '15:00';
        List<Id> selectedDoctorIds = new List<Id>{medico.Id};
        
        Test.startTest();
        // Llamar al método createAvailabilities
        CreateAvailabilityLWCController.createAvailabilities(selectedCenter, selectedCenterName, startDate, endDate, selectedStartHour, selectedEndHour, selectedDoctorIds);
        Test.stopTest();

        // Aserción para verificar que se hayan creado las disponibilidades correctamente
        List<Disponibilidad_Medica__c> disponibilidades = [SELECT Id FROM Disponibilidad_Medica__c];
        System.assertEquals(2, disponibilidades.size(), 'Deberían haberse creado 2 disponibilidades, una para cada día en el rango de fechas');
    }
    

}