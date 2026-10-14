# Findings: OwnerController

Status: unbestätigt, aus Hauptsitzung, noch nicht vom reviewer geprüft

Urteil: Änderungen nötig

F-01 [mittel] [Korrektheit] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:80`
Befund: Bei Validierungsfehlern in `processCreationForm` wird ein Flash-Attribut "error" gesetzt, die View aber direkt gerendert statt umgeleitet; Flash-Attribute werden nur bei einem Redirect übernommen, die Meldung wird daher vermutlich nie angezeigt (vermutet, nicht durch Test belegt). Gleiches Muster in `processUpdateOwnerForm` (Zeile 157).
Vorschlag: Meldung als normales Model-Attribut setzen (oder ganz auf die Feldfehler verlassen) und das Verhalten mit einem `@WebMvcTest` absichern.
Aufwand: S

F-02 [niedrig] [Wartbarkeit] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:161`
Befund: Die ID-Prüfung in `processUpdateOwnerForm` kann nie anschlagen, weil der `Owner` per `findOwner(ownerId)` geladen wird (Zeilen 64-70) und `setDisallowedFields("id", "*.id")` das Binden der ID verhindert; `owner.getId()` ist damit immer gleich `ownerId`, der Zweig ist toter Code.
Vorschlag: Toten Zweig samt `owner.setId(ownerId)` entfernen oder die Absicht dokumentieren und per Test belegen.
Aufwand: S

F-03 [niedrig] [i18n] `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java:80`
Befund: Die Flash-Meldungen stehen als feste englische Texte im Java-Code (Zeilen 80, 85, 157, 163, 169) statt als Message-Keys und sind damit nicht übersetzbar.
Vorschlag: Message-Keys in allen `messages_*.properties` anlegen und im Template per `#{...}` auflösen.
Aufwand: M

Nicht geprüft: Thymeleaf-Templates (`createOrUpdateOwnerForm.html`, `ownerDetails.html`), `db/*/schema.sql`, übrige Controller und Tests.
