# Architektur: Datenmodell und Ablauf "Neuen Besitzer anlegen"

Stand: 2026-10-09, Branch `harness/setup`.
Quelle: Lauf des explorer-Agenten (nur lesend) über die Pakete `model`, `owner` und `vet`;
die zentralen Stellen im `OwnerController` wurden in der Hauptsitzung nachgelesen.
Nicht geprüft: Thymeleaf-Templates und `db/*/schema.sql` (Spaltenlängen und Fremdschlüssel
sind nur aus den Annotationen abgeleitet).

## Klassendiagramm: Datenmodell (`model`, `owner`, `vet`)

Getter, Setter, Controller, `PetValidator` und `PetTypeFormatter` sind bewusst weggelassen.

```mermaid
classDiagram
namespace model {
  class BaseEntity {
    <<MappedSuperclass>>
    -Integer id
    +isNew() boolean
  }
  class NamedEntity {
    <<MappedSuperclass>>
    -String name  «NotBlank»
  }
  class Person {
    <<MappedSuperclass>>
    -String firstName  «NotBlank, Size max 30»
    -String lastName  «NotBlank, Size max 30»
  }
}
namespace owner {
  class Owner {
    <<Entity owners>>
    -String address  «NotBlank, Size max 255»
    -String city  «NotBlank, Size max 80»
    -String telephone  «NotBlank, Pattern 10 Ziffern»
    +addPet(Pet)
    +getPet(String name) Pet
    +getPet(Integer id) Pet
    +getPet(String, boolean ignoreNew) Pet
    +addVisit(Integer petId, Visit)
  }
  class Pet {
    <<Entity pets>>
    -LocalDate birthDate
    +addVisit(Visit)
  }
  class PetType {
    <<Entity types>>
  }
  class Visit {
    <<Entity visits>>
    -LocalDate date
    -String description  «NotBlank, Size max 255»
  }
  class OwnerRepository {
    <<interface>>
    +findByLastNameStartingWith(String, Pageable) Page~Owner~
    +findById(Integer) Optional~Owner~
  }
  class PetTypeRepository {
    <<interface>>
    +findPetTypes() List~PetType~
  }
}
namespace vet {
  class Vet {
    <<Entity vets>>
    +getSpecialties() List~Specialty~
    +getNrOfSpecialties() int
    +addSpecialty(Specialty)
  }
  class Specialty {
    <<Entity specialties>>
  }
  class Vets {
    <<XmlRootElement>>
    +getVetList() List~Vet~
  }
  class VetRepository {
    <<interface>>
    +findAll() Collection~Vet~  «Cacheable vets»
    +findAll(Pageable) Page~Vet~  «Cacheable vets»
  }
}
BaseEntity <|-- NamedEntity
BaseEntity <|-- Person
BaseEntity <|-- Visit
NamedEntity <|-- Pet
NamedEntity <|-- PetType
NamedEntity <|-- Specialty
Person <|-- Owner
Person <|-- Vet
Owner "1" *-- "0..*" Pet : pets (Cascade ALL, EAGER)
Pet "1" *-- "0..*" Visit : visits (Cascade ALL, EAGER)
Pet "0..*" --> "1" PetType : type
Vet "0..*" --> "0..*" Specialty : specialties (ManyToMany EAGER)
Vets "1" o-- "0..*" Vet
OwnerRepository ..> Owner
PetTypeRepository ..> PetType
VetRepository ..> Vet
```

Quellen: `model/BaseEntity.java`, `model/NamedEntity.java`, `model/Person.java`, `owner/Owner.java`, `owner/Pet.java`, `owner/PetType.java`, `owner/Visit.java`, `owner/OwnerRepository.java`, `owner/PetTypeRepository.java`, `vet/Vet.java`, `vet/Specialty.java`, `vet/Vets.java`, `vet/VetRepository.java` (alle unter `src/main/java/org/springframework/samples/petclinic/`).

## Sequenzdiagramm: Neuen Besitzer anlegen

```mermaid
sequenceDiagram
actor B as Browser
participant D as DispatcherServlet
participant C as OwnerController
participant R as OwnerRepository
participant DB as Datenbank
participant V as Thymeleaf View

B->>D: GET /owners/new
D->>C: findOwner(ownerId=null) → @ModelAttribute "owner"
C-->>D: new Owner()
D->>C: initCreationForm()
C-->>D: "owners/createOrUpdateOwnerForm"
D->>V: render (leerer Owner)
V-->>B: HTML-Formular

B->>D: POST /owners/new (Formfelder)
D->>C: findOwner(null) → new Owner()
D->>C: setAllowedFields(): setDisallowedFields("id", "*.id")
Note over D,C: Data Binding, id-Felder werden ignoriert
D->>D: Bean Validation (@Valid) → BindingResult
D->>C: processCreationForm(owner, result, redirectAttributes)
alt result.hasErrors()
  C->>C: addFlashAttribute("error", ...)
  C-->>D: "owners/createOrUpdateOwnerForm"
  D->>V: render Formular mit Feldfehlern
  V-->>B: HTML 200
else gültig
  C->>R: save(owner)
  R->>DB: INSERT owners
  DB-->>R: generierte id
  C->>C: addFlashAttribute("message", "New Owner Created")
  C-->>D: "redirect:/owners/" + id
  D-->>B: 302 → /owners/{id}
  B->>D: GET /owners/{id}
  D->>C: showOwner(ownerId)
  C->>R: findById(ownerId)
  R->>DB: SELECT owner + pets + visits
  C-->>D: ModelAndView("owners/ownerDetails")
  D->>V: render (mit Flash-"message")
  V-->>B: HTML Detailseite
end
```

Quellen: `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java` (Zeilen 59-62, 64-70, 72-75, 77-87, 178-186).
