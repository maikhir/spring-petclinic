# spring-petclinic: Leitfaden für Agenten

## Zweck
Referenz-Anwendung: Spring Boot, Thymeleaf, Spring Data JPA.
Lernprojekt: Ziel sind Code-Review, Abbau technischer Schulden und ein neues Feature.

## Build & Test

Spring Boot app, Java 25+ (enforced by `maven-enforcer-plugin`). Maven is the primary build (CI runs `./mvnw -B verify`); 
# a Gradle build (`./gradlew build`) is kept in parallel and must keep working too.

```bash
./mvnw spring-boot:run                      # run on http://localhost:8080 (H2 in-memory)
./mvnw verify                               # full build: format check, nohttp checkstyle, tests, jacoco
./mvnw test -Dtest=OwnerControllerTests     # single test class
./mvnw test -Dtest='OwnerControllerTests#processCreationFormSuccess'   # single method
./mvnw spring-javaformat:apply              # fix formatting (validate phase fails otherwise)
./mvnw package -P css                       # recompile petclinic.css from src/main/scss (Maven only)
/scripts/verify.sh                          # and a short scrit with verify with will be used by agents

```

The `validate` phase runs `spring-javaformat` (tabs, Spring style) and a `nohttp` checkstyle that rejects plain `http://` URLs. Run `spring-javaformat:apply` before building after editing Java.

Database profiles: default is H2; `-Dspring-boot.run.profiles=mysql` or `postgres` (start DBs via `docker compose up mysql|postgres`). `MySqlIntegrationTests` (Testcontainers) and `PostgresIntegrationTests` (Docker Compose) are skipped when Docker is unavailable.

  
## Architecture

Classic layered Spring MVC + Thymeleaf server-side rendering, no service layer: controllers talk directly to Spring Data JPA repositories. Packages are organized by feature under `org.springframework.samples.petclinic`:

- `model` – `BaseEntity` (id) → `NamedEntity` / `Person` mapped superclasses.
- `owner` – **`Owner` is the aggregate root**: `Pet` and `Visit` have no repositories of their own. Pets and visits are added via `Owner.addPet` / `Owner.addVisit` and persisted by `OwnerRepository.save(owner)` (cascade). `PetController` and `VisitController` load the owner via `@ModelAttribute` methods keyed on `{ownerId}` path variables. `PetTypeFormatter` converts form strings to `PetType`; `PetValidator` handles pet validation in addition to Bean Validation.
- `vet` – read-only vet list (HTML and JSON at `/vets`), cached via JCache/Caffeine (`@Cacheable("vets")`, cache created in `system/CacheConfiguration`).
- `system` – welcome page, `CrashController` (deliberate error to demo `error.html`), locale handling (`WebConfiguration`, `?lang=` param).

Controllers use `WebDataBinder.setDisallowedFields("id", ...)` to prevent id binding from forms — keep this when adding forms.

### Schema & data

`spring.jpa.hibernate.ddl-auto=none`: schema comes from `src/main/resources/db/{h2,mysql,postgres}/schema.sql` + `data.sql` (selected via the `database` property). Any entity/column change must be applied to **all three** schema files. Column length limits in the schema are mirrored by `@Size` constraints on entities so oversized input yields validation errors instead of HTTP 500.

### i18n

All user-visible text in templates must use message keys (`th:text="#{...}"`). `I18nPropertiesSyncTest` fails the build if an HTML template contains hard-coded text or if a key is missing from any `messages_*.properties` file — add new keys to every locale file.

### Tests

- `*ControllerTests` – `@WebMvcTest` slices with mocked repositories.
- `service/ClinicServiceTests` – `@DataJpaTest` against H2, exercising the repositories.
- `PetClinicIntegrationTests` – full `@SpringBootTest`; its `main()` also serves as a dev launcher with Devtools (likewise `MysqlTestApplication`).

### Deployment
K
ein Dockerfile; Images per ./mvnw spring-boot:build-image; Manifeste in k8s/.

# No Dockerfile; images are built with `./mvnw spring-boot:build-image`. Kubernetes manifests are in `k8s/` (app + Postgres). `PetClinicRuntimeHints` supports GraalVM native builds (`native-maven-plugin`).

## Konventionen
- Neue Funktion immer mit Test (JUnit 5, bestehende Teststile übernehmen)
- Neue Texte in ALLEN messages-Dateien ergänzen
- Kleine, fokussierte Commits mit Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`)
- der Branch harness/setup ist die Basis für alle ai/... branches
- Arbeit nur auf Branches `ai/<thema>`, nie direkt auf `main`
- Änderungen minimal halten: keine Umformatierung oder Umbenennung unbeteiligter Dateien

## Verboten ohne ausdrückliche Rückfrage
- Neue Abhängigkeiten oder Versionsänderungen in der `pom.xml`
- Tests löschen, auskommentieren oder abschwächen, um Fehler zu "beheben"
- `git push --force`, History umschreiben, direkt auf `main` pushen
- Secrets, Zugangsdaten oder Dateien außerhalb des Repos anfassen

## Vorgehen bei Aufgaben
1. Erst lesen und einen kurzen Plan nennen, bei größeren Änderungen warten, bis ich ihn freigebe.
2. Bei Refactorings zuerst Tests sichern, dann ändern.
3. Nach jeder Änderung `scripts/verify.sh` ausführen.

## Definition of Done
- `scripts/verify.sh` ist grün
- Diff klein und nachvollziehbar
- Neues Verhalten ist getestet
- Kurze Zusammenfassung: was geändert, warum, wie geprüft, was offen blieb
