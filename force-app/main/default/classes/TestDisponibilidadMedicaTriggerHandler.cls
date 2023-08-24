/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
@isTest
private class TestDisponibilidadMedicaTriggerHandler {
    @isTest static void testHandleBeforeInsert() {
        // Preparar datos de prueba
        Centro_Estetico__c centro = new Centro_Estetico__c();
        insert centro;

        Medico__c medico = new Medico__c();
        insert medico;

        DateTime inicio = DateTime.newInstance(2023, 8, 26, 8, 0, 54);
        DateTime fin = DateTime.newInstance(2023, 8, 26, 15, 0, 54);

        Disponibilidad_Medica__c disponibilidad = new Disponibilidad_Medica__c(
            Medico_Asociado__c = medico.Id,
            Centro_Estetico_Asociado__c = centro.Id,
            Fecha_hora_de_Inicio__c = inicio,
            Fecha_hora_de_Fin__c = fin
        );
        insert disponibilidad;

        // Intentar insertar una disponibilidad duplicada
        Disponibilidad_Medica__c disponibilidadDuplicada = new Disponibilidad_Medica__c(
            Medico_Asociado__c = medico.Id,
            Centro_Estetico_Asociado__c = centro.Id,
            Fecha_hora_de_Inicio__c = inicio,
            Fecha_hora_de_Fin__c = fin
        );
        List<Disponibilidad_Medica__c> newAvailabilities = new List<Disponibilidad_Medica__c>{disponibilidadDuplicada};

        Test.startTest();
        // Llamar al método handleBeforeInsert
        DisponibilidadMedicaTriggerHandler.handleBeforeInsert(newAvailabilities);
        Test.stopTest();

        // Aserción para verificar que no se haya creado una disponibilidad duplicada
        List<Disponibilidad_Medica__c> disponibilidadesDelMedico = [SELECT Id FROM Disponibilidad_Medica__c WHERE Medico_Asociado__c = :medico.Id];
        System.assertEquals(1, disponibilidadesDelMedico.size(), 'No debería haber disponibilidades duplicadas para el mismo médico.');
    }
}