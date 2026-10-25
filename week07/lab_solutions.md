# Lab 7 Solutions

**Student Name:** Jennifer Njogu
**Student ID:** 01256232
**Date:** 10/15/26

---

## Ticket 1: The Visual Audit (Physical ERD)
*Complete the physical architecture diagram below. Refer to `MERMAID_CHEAT_SHEET.md` and Ticket 1 in `IN_CLASS_LAB.md` for attribute details.*

```mermaid
erDiagram
    users {
        varchar email PK
        varchar first_name
        varchar last_name
        varchar phone
        date birthdate
        varchar parent_email
        %% TODO: Add last_name, phone, birthdate, parent_email
    }
    teams {
        varchar team_name PK
        varchar age_group
        %% TODO: Add age_group
    }
    registrations {
        serial registration_id PK
        varchar user_email FK
        varchar team_name FK
        varchar assigned_role
        NUMERIC fee_amount
        %% TODO: Add assigned_role, fee_amount
    }

    gear_order {
        serial order_id PK
        serial registration_id FK
        varchar gear_item
        varchar gear_size
        int gear_quantity
    }
    users ||--o{ registrations : "registers for"
    teams ||--o{ registrations : "has"
    registrations ||--o{ gear_order : "includes"

    %% TODO: Define the gear_orders entity (order_id PK, registration_id FK, gear_item, gear_size, gear_quantity)
    %% TODO: Connect registrations to gear_orders (1-to-many: ||--o{ "includes")

```
