/**
 * @description       : 
 * @author            : Adrian Romero
 * @group             : 
 * @last modified on  : 08-23-2023
 * @last modified by  : Adrian Romero
**/
@isTest
private class TestCreateEventsLWCController {
    @isTest static void testGetCenters() {
        // Insertar algunos registros de centros estéticos para la prueba
        Centro_Estetico__c centro1 = new Centro_Estetico__c(Name='Centro Test 1');
        Centro_Estetico__c centro2 = new Centro_Estetico__c(Name='Centro Test 2');
        insert new List<Centro_Estetico__c>{centro1, centro2};

        // Llamar al método getCenters
        Test.startTest();
        List<Centro_Estetico__c> centers = createEventsLWCController.getCenters();
        Test.stopTest();

        // Aserciones para verificar que los centros correctos son devueltos
        System.assertEquals(2, centers.size(), 'Deberían haberse devuelto 2 centros estéticos');
        System.assertEquals(centro1.Id, centers[0].Id, 'El primer centro devuelto debería ser el Centro Test 1');
        System.assertEquals(centro2.Id, centers[1].Id, 'El segundo centro devuelto debería ser el Centro Test 2');
    }

    @isTest static void testGetSpecialties() {
        // Insertar un registro de centro estético con algunas especialidades disponibles
        Centro_Estetico__c centro = new Centro_Estetico__c(Name='Centro Test', Especialidades_Disponibles__c='Aumento de labios;Botox');
        insert centro;

        // Llamar al método getSpecialties con el ID del centro insertado
        Test.startTest();
        List<String> specialties = createEventsLWCController.getSpecialties(centro.Id);
        Test.stopTest();

        // Aserciones para verificar que las especialidades correctas son devueltas
        System.assertEquals(2, specialties.size(), 'Deberían haberse devuelto 2 especialidades');
        System.assertEquals('Aumento de labios', specialties[0], 'La primera especialidad devuelta debería ser Aumento de labios');
        System.assertEquals('Botox', specialties[1], 'La segunda especialidad devuelta debería ser Botox');
    }

    @isTest static void testGetAvailableDoctors() {
        // Insertar registros de médicos con especialidades
        Medico__c medico1 = new Medico__c(Name='Dr. Test 1', Especialidades__c='Aumento de labios');
        Medico__c medico2 = new Medico__c(Name='Dr. Test 2', Especialidades__c='Botox');
        insert new List<Medico__c>{medico1, medico2};

        // Insertar un registro de centro estético
        Centro_Estetico__c centro = new Centro_Estetico__c(Name='Centro Test');
        insert centro;

        // Insertar disponibilidades para los médicos
        Date appointmentDate = Date.newInstance(2023, 8, 26);
        Disponibilidad_Medica__c disponibilidad1 = new Disponibilidad_Medica__c(
            Medico_Asociado__c = medico1.Id,
            Centro_Estetico_Asociado__c = centro.Id,
            Fecha_hora_de_Inicio__c = DateTime.newInstance(appointmentDate, Time.newInstance(8, 0, 0, 0)),
            Fecha_hora_de_Fin__c = DateTime.newInstance(appointmentDate, Time.newInstance(15, 0, 0, 0))
        );
        insert disponibilidad1;

        // Llamar al método getAvailableDoctors con el centro, especialidad y fecha de la cita
        Test.startTest();
        List<Medico__c> doctors = createEventsLWCController.getAvailableDoctors(centro.Id, 'Aumento de labios', appointmentDate);
        Test.stopTest();

        // Aserciones para verificar que los médicos correctos son devueltos
        System.assertEquals(1, doctors.size(), 'Debería haberse devuelto 1 médico');
        System.assertEquals(medico1.Id, doctors[0].Id, 'El médico devuelto debería ser el Dr. Test 1');
    }

    @isTest static void testGetAvailableTimeSlots() {
        // Insertar un registro de médico
        Medico__c medico = new Medico__c(Name='Dr. Test');
        insert medico;

        // Insertar un registro de centro estético
        Centro_Estetico__c centro = new Centro_Estetico__c(Name='Centro Test');
        insert centro;

        // Insertar disponibilidad para el médico en el centro
        Date targetDate = Date.newInstance(2023, 8, 26);
        DateTime startTime = DateTime.newInstance(targetDate, Time.newInstance(8, 0, 0, 0));
        DateTime endTime = DateTime.newInstance(targetDate, Time.newInstance(15, 0, 0, 0));
        Disponibilidad_Medica__c disponibilidad = new Disponibilidad_Medica__c(
            Medico_Asociado__c = medico.Id,
            Centro_Estetico_Asociado__c = centro.Id,
            Fecha_hora_de_Inicio__c = startTime,
            Fecha_hora_de_Fin__c = endTime
        );
        insert disponibilidad;

        // Insertar un evento existente que se superpone con la disponibilidad
        DateTime existingEventStart = DateTime.newInstance(targetDate, Time.newInstance(10, 0, 0, 0));
        DateTime existingEventEnd = DateTime.newInstance(targetDate, Time.newInstance(10, 30, 0, 0));
        Event existingEvent = new Event(
            StartDateTime = existingEventStart,
            EndDateTime = existingEventEnd,
            Medico_Asociado__c = medico.Id
        );
        insert existingEvent;

        // Llamar al método getAvailableTimeSlots con el médico, centro, duración y fecha objetivo
        Integer duration = 30; // Duración en minutos
        Test.startTest();
        List<createEventsLWCController.TimeSlotWrapper> timeSlots = createEventsLWCController.getAvailableTimeSlots(medico.Id, centro.Id, duration, targetDate);
        Test.stopTest();

        // Aserciones para verificar que los horarios correctos son devueltos
        System.assertEquals(13, timeSlots.size(), 'Deberían haberse devuelto 13 horarios disponibles');
        System.assertNotEquals('10:00 AM', timeSlots[4].label, 'El horario de 10:00 AM a 10:30 AM debería estar bloqueado por el evento existente');
        System.assertEquals('08:00 AM', timeSlots[0].label, 'El primer horario disponible debería ser a las 08:00 AM');
        System.assertEquals('02:30 PM', timeSlots[13].label, 'El último horario disponible debería ser a las 02:30 PM');
    }


    @isTest static void testCreateEvent() {
        // Insertar un registro de médico y un centro estético
        Medico__c medico = new Medico__c(Name='Dr. Test');
        Centro_Estetico__c centro = new Centro_Estetico__c(Name='Centro Test');
        insert new List<SObject>{medico, centro};

        // Definir los parámetros del evento
        String doctorId = medico.Id;
        String centerId = centro.Id;
        String eventDate = '2023-08-26';
        String startTime = '08:00';
        String endTime = '09:00';
        String contactFirstName = 'John';
        String contactLastName = 'Doe';
        String contactEmail = 'john.doe@example.com';
        String contactPhone = '1234567890';
        String contactObservations = 'Observaciones de prueba';

        // Llamar al método createEvent
        Test.startTest();
        String result = createEventsLWCController.createEvent(doctorId, centerId, eventDate, startTime, endTime, contactFirstName, contactLastName, contactEmail, contactPhone, contactObservations);
        Test.stopTest();

        // Aserciones para verificar que el evento fue creado correctamente
        System.assert(result.startsWith('Evento creado exitosamente. Id:'), 'El evento debería haber sido creado exitosamente');

        // Verificar que el evento fue insertado en la base de datos con los valores correctos
        Event createdEvent = [SELECT Subject, StartDateTime, EndDateTime, Medico_Asociado__c, Centro_Estetico_Asociado__c, WhoId FROM Event LIMIT 1];
        System.assertEquals(contactFirstName + ' ' + contactLastName + ' - ' + eventDate + ' ' + startTime, createdEvent.Subject, 'El asunto del evento no coincide');
        System.assertEquals(doctorId, createdEvent.Medico_Asociado__c, 'El médico asociado no coincide');
        System.assertEquals(centerId, createdEvent.Centro_Estetico_Asociado__c, 'El centro estético asociado no coincide');
    }
}