
```mermaid
flowchart TD
    subgraph Search
        filter((filter)) -->|New Value| results((results))
        results -->|New Items| filterResults((filteredResults))
        filterResults((filteredResults))
        filterResults -->|batch| availableResults((availableResults))-->loadAvailability((loadAvailability)) --> sort
    end
```