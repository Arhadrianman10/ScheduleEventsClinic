/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
trigger DisponibilidadMedicaTrigger on Disponibilidad_Medica__c (before insert) {
    DisponibilidadMedicaTriggerHandler.handleBeforeInsert(trigger.new);
}