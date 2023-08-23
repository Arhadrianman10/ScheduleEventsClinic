/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
public class DisponibilidadMedicaTriggerHandler {
    public static void handleBeforeInsert(List<Disponibilidad_Medica__c> newAvailabilities) {
        // Recopilar los IDs de los médicos de los nuevos registros
        Set<Id> doctorIds = new Set<Id>();
        for (Disponibilidad_Medica__c availability : newAvailabilities) {
            doctorIds.add(availability.Medico_Asociado__c);
        }

        // Consultar las disponibilidades existentes para los médicos
        Map<Id, List<Disponibilidad_Medica__c>> existingAvailabilitiesByDoctor = new Map<Id, List<Disponibilidad_Medica__c>>();
        for (Disponibilidad_Medica__c existingAvailability : [SELECT Id, Medico_Asociado__c,Medico_Asociado__r.Name, Fecha_hora_de_Inicio__c, Fecha_hora_de_Fin__c FROM Disponibilidad_Medica__c WHERE Medico_Asociado__c IN :doctorIds]) {
            if (!existingAvailabilitiesByDoctor.containsKey(existingAvailability.Medico_Asociado__c)) {
                existingAvailabilitiesByDoctor.put(existingAvailability.Medico_Asociado__c, new List<Disponibilidad_Medica__c>());
            }
            existingAvailabilitiesByDoctor.get(existingAvailability.Medico_Asociado__c).add(existingAvailability);
        }

        // Verificar las superposiciones
        for (Disponibilidad_Medica__c newAvailability : newAvailabilities) {
            List<Disponibilidad_Medica__c> existingAvailabilities = existingAvailabilitiesByDoctor.get(newAvailability.Medico_Asociado__c);
            if (existingAvailabilities != null) {
                for (Disponibilidad_Medica__c existingAvailability : existingAvailabilities) {
                    if (newAvailability.Fecha_hora_de_Inicio__c < existingAvailability.Fecha_hora_de_Fin__c && newAvailability.Fecha_hora_de_Fin__c > existingAvailability.Fecha_hora_de_Inicio__c) {
                        // Superposición encontrada; agregar un mensaje de error
                        DateTime inicio = existingAvailability.Fecha_hora_de_Inicio__c;
                        DateTime fin = existingAvailability.Fecha_hora_de_Fin__c;
                        String inicioStr = inicio.format('yyyy-MM-dd\' \'HH:mm:ss\' \'');
                        String finStr = fin.format('yyyy-MM-dd\' \'HH:mm:ss\' \'');

                        
                        newAvailability.addError('El médico ' + existingAvailability.Medico_Asociado__r.Name + ' ya tiene una disponibilidad en este horario: ' + inicioStr + ' - ' + finStr);
                                            }
                }
            }
        }
    }
}
