# Findings: Paket owner

Status: F-01 bis F-03 vom reviewer-Agenten geprüft und bestätigt (2026-10-14, Stand `e4555cd`).
F-04 bis F-14 stammen aus dem reviewer-Lauf über das Paket `owner`; F-04, F-05, F-06, F-08, F-09,
F-10 und F-12 wurden in der Hauptsitzung am Code nachgelesen. Mit "vermutet" markierte Findings
sind nicht durch Test oder Laufzeit belegt.

Urteil: Änderungen nötig

F-01 [niedrig] [Korrektheit] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:80`
Befund: Bei Validierungsfehlern in `processCreationForm` wird ein Flash-Attribut "error" gesetzt, die View aber direkt gerendert statt umgeleitet; Flash-Attribute werden nur bei einem Redirect übernommen, die Meldung wird daher nie angezeigt. Gleiches Muster in `processUpdateOwnerForm` (Zeile 157).
Prüfung: bestätigt. Z. 81/158 geben `VIEWS_OWNER_CREATE_OR_UPDATE_FORM` ohne `redirect:` zurück; `createOrUpdateOwnerForm.html` und `fragments/layout.html` geben `${error}` gar nicht aus (nur `ownerDetails.html:13-15`). `processCreationFormHasErrors` und `processUpdateOwnerFormHasErrors` prüfen kein Flash-Attribut. Schwere von mittel auf niedrig gesenkt: Die Feldfehler werden weiterhin angezeigt, der Code ist faktisch wirkungslos.
Vorschlag: Meldung als normales Model-Attribut setzen (oder ganz auf die Feldfehler verlassen) und das Verhalten mit einem `@WebMvcTest` absichern.
Aufwand: S

F-02 [niedrig] [Wartbarkeit] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:161`
Befund: Die ID-Prüfung in `processUpdateOwnerForm` kann im Betrieb nie anschlagen, weil der `Owner` per `findOwner(ownerId)` geladen wird (Zeilen 64-70) und `setDisallowedFields("id", "*.id")` das Binden der ID verhindert; `owner.getId()` ist damit immer gleich `ownerId`, der Zweig und `owner.setId(ownerId)` (Z. 167) sind toter Code.
Prüfung: bestätigt mit Einschränkung. `OwnerControllerTests.processUpdateOwnerFormWithIdMismatch` (Z. 299-316) erreicht den Zweig künstlich, indem der Mock für `findById(1)` einen Owner mit id 2 liefert, ein Zustand, den JPA nicht erzeugt. Zusätzlich ist `result.rejectValue("id", ...)` (Z. 162) vor dem Redirect wirkungslos.
Vorschlag: Toten Zweig samt `owner.setId(ownerId)` entfernen; der genannte Test müsste dann angepasst oder entfernt werden (laut CLAUDE.md nur nach Rückfrage).
Aufwand: S

F-03 [niedrig] [i18n] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:80`
Befund: Die Flash-Meldungen stehen als feste englische Texte im Java-Code (Zeilen 80, 85, 157, 163, 169) statt als Message-Keys und sind damit nicht übersetzbar.
Prüfung: bestätigt und weiter verbreitet als angegeben: ebenso `PetController.java:135` und `:177` sowie `VisitController.java:110`; ausgegeben unübersetzt per `th:text="${message}"` in `ownerDetails.html:10`.
Vorschlag: Message-Keys in allen `messages_*.properties` anlegen und im Template per `#{...}` auflösen.
Aufwand: M

F-04 [mittel] [Korrektheit] `src/main/resources/templates/owners/ownersList.html:35`
Befund: Die Pagination-Links (`@{'/owners?page=' + ${i}}`, ebenso Z. 40, 44, 49, 54) lassen `lastName` weg, und `OwnerController.addPaginationModel` (Z. 132-139) legt den Suchbegriff nicht ins Model. Ab Seite 2 einer gefilterten Suche erscheinen daher alle Owner statt der Treffer.
Vorschlag: `lastName` ins Model legen, per `@{/owners(page=${i},lastName=${lastName})}` mitgeben und mit einem Test absichern.
Aufwand: S

F-05 [mittel] [Sicherheit] `src/main/java/org/springframework/samples/petclinic/owner/PetController.java:108`
Befund: Der Parameter `Owner owner` ist ein implizites Model-Attribut und wird an Request-Parameter gebunden; der Binder sperrt nur `id` und `*.id` (Z. 91). Ein POST auf `/owners/{id}/pets/new` mit z. B. `address=...` ändert den Owner ohne Bean Validation, `saveAndFlush(owner)` (Z. 126) persistiert das. Gleiches in Z. 145 und `VisitController.java:98` (gespeichert in Z. 109). Vermutet: Über `pets[0].name` lässt sich auch der `PetValidator` umgehen.
Vorschlag: Im Owner-Binder von Pet- und VisitController alle Felder sperren oder den Owner per `@ModelAttribute(binding = false)` laden; per Test absichern.
Aufwand: S

F-06 [mittel] [Korrektheit] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:68`
Befund: Ein unbekannter Owner führt zu `IllegalArgumentException` (ebenso Z. 182, `PetController.java:70/84`, `VisitController.java:67/72`); im Projekt gibt es weder `@ExceptionHandler`, `@ControllerAdvice` noch `@ResponseStatus`, daher HTTP 500 statt 404.
Vorschlag: Eigene NotFound-Exception mit `@ResponseStatus(NOT_FOUND)` werfen und per Test absichern.
Aufwand: S

F-07 [mittel] [Korrektheit] `src/main/java/org/springframework/samples/petclinic/owner/PetController.java:86`
Befund (vermutet): Bei unbekannter `petId` liefert `findPet` über `owner.getPet(petId)` `null`; auf GET scheitert das Template an `${pet['new']}` (`createOrUpdatePetForm.html:8`), auf POST `Assert.state(id != null, ...)` (Z. 188), jeweils HTTP 500. `VisitController` (Z. 71-74) behandelt den Fall explizit.
Vorschlag: Fehlendes Pet wie in `VisitController` behandeln (bzw. zusammen mit F-06 als 404) und testen.
Aufwand: S

F-08 [mittel] [i18n] `src/main/resources/templates/pets/createOrUpdatePetForm.html:20`
Befund: Feste Labels in Template-Ausdrücken: `'Name'`, `'Birth Date'`, `'Type'` (Z. 20-22), `'Add Pet' : 'Update Pet'` (Z. 26), in `createOrUpdateVisitForm.html` Z. 9 sowie `'Date'`, `'Description'` (Z. 32-33); `fragments/inputField.html:10` gibt sie per `th:text="${label}"` unübersetzt aus. `I18nPropertiesSyncTest` erkennt das nicht, weil die Prüfung (`HTML_TEXT_LITERAL`) nur Text zwischen Tags erfasst.
Vorschlag: Vorhandene Keys (`name`, `birthDate`, `type`, `date`) per `#{...}` nutzen, fehlende Keys in allen messages-Dateien ergänzen.
Aufwand: S

F-09 [niedrig] [i18n] `src/main/java/org/springframework/samples/petclinic/owner/PetValidator.java:47`
Befund: `errors.rejectValue("name", "size", "Name must be no more than 30 characters")` nutzt den Key `size`, der in `messages.properties` fehlt; in allen Sprachen erscheint der englische Default-Text.
Vorschlag: Key `size` in allen messages-Dateien ergänzen.
Aufwand: S

F-10 [niedrig] [Korrektheit] `src/main/resources/db/postgres/schema.sql:26`
Befund: In Postgres sind die Spalten von owners, pets und visits `TEXT`; die durch `@Size` gespiegelten Längen werden dort nicht erzwungen (H2/MySQL: passende `VARCHAR(n)`). Zudem ist `last_name` in H2 `VARCHAR_IGNORECASE(30)` (`h2/schema.sql:39`), in Postgres case-sensitiv, sodass `findByLastNameStartingWith` je Datenbank andere Treffer liefert.
Vorschlag: Postgres-Spalten auf `VARCHAR(n)` angleichen und die Groß-/Kleinschreibung der Suche vereinheitlichen.
Aufwand: S

F-11 [niedrig] [Tests] `src/test/java/org/springframework/samples/petclinic/owner/OwnerControllerTests.java:115`
Befund: Die Erfolgs-Tests (ebenso Z. 251-267 und die Erfolgsfälle in `PetControllerTests`/`VisitControllerTests`) prüfen nur `is3xxRedirection()`, nicht ob und mit welchen Werten `save` aufgerufen wurde oder ob `message` gesetzt ist. Für F-04 und F-05 gibt es keine Tests.
Vorschlag: `verify(owners).save(argThat(...))` und `flash().attribute("message", ...)` ergänzen.
Aufwand: S

F-12 [niedrig] [Korrektheit] `src/main/resources/templates/owners/ownerDetails.html:84`
Befund: `document.getElementById("success-message").style.display` wirft einen TypeError, wenn das Element fehlt (bei jedem Aufruf ohne `message`); `error-message` fehlt praktisch immer, sodass Z. 85 stets scheitert.
Vorschlag: Vor dem Zugriff auf `null` prüfen.
Aufwand: S

F-13 [niedrig] [Performance] `src/main/java/org/springframework/samples/petclinic/owner/Owner.java:67`
Befund (vermutet): `pets` und `Pet.visits` (`Pet.java:56`) sind `FetchType.EAGER`; bei der paginierten Suche lädt Hibernate Pets und Visits per Folgeabfragen nach (N+1). `PetController.findPet` (Z. 83) lädt den Owner zudem ein zweites Mal.
Vorschlag: Für die Liste `@EntityGraph` oder LAZY mit Fetch-Join nutzen; in `findPet` den Owner aus dem Model wiederverwenden.
Aufwand: M

F-14 [niedrig] [Wartbarkeit] `src/main/java/org/springframework/samples/petclinic/owner/PetController.java:115`
Befund: Geburtsdatum-Prüfung (Z. 115-118 und 158-161) und Duplikat-Fallback per `DataIntegrityViolationException` (Z. 128-134 und 170-176) sind dupliziert; `isDuplicatePetNameViolation` erkennt den Fall über den Magic String `"unique_owner_pet_name"` in der Exception-Message (Z. 204), abhängig von Datenbank und Treiber.
Vorschlag: Gemeinsame Prüfungen in eine private Methode auslagern, Constraint-Namen als Konstante führen.
Aufwand: S

Ohne Befund geprüft: keine Repositories für Pet/Visit; `setDisallowedFields("id", ...)` in allen drei Controllern; kein `th:utext`; `@Size` passt in H2/MySQL zu den Spaltenlängen (Pet.name über `PetValidator.MAX_NAME_LENGTH = 30`).

Nicht geprüft: Pakete `vet` und `system` (außer grep nach Exception-Handlern), `data.sql`, Inhalt der `messages_*.properties` außer der Basisdatei, `PetTypeFormatterTests`, `PetValidatorTests`, `OwnerTests`, `ClinicServiceTests`, Integrationstests; kein Build, keine Laufzeit- oder SQL-Analyse (F-07, F-13 daher vermutet).
