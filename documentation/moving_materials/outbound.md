# Outbound (Shipping to Another Organization)

> An **outbound** is a [request](request.md) to send stock **out of our location to another organization**, such as a vendor return, another plant, or a partner. It follows request → allocation → picking → handover. At the [handover](handover.md), the goods go to the **driver** together with a **delivery note issued by us**. There is no put away, because the stock leaves the site.

Related: [Request](request.md) · [Allocation](allocation.md) · [Picking](picking.md) · [Handover](handover.md) · [Delivery note](delivery_note.md)

---

## 1. Data architecture

```mermaid
erDiagram
    requests ||--o| outbounds : "is a"
    warehouses ||--o{ outbounds : "from"
    organizations ||--o{ outbounds : "to"
    outbounds ||--|{ request_details : "lines (batch)"
    request_details ||--o{ allocations : "reserved by"
    outbounds ||--o{ pickings : "picked by"
    pickings ||--o| handovers : "handed to driver"
    delivery_notes ||--o| handovers : "issued for"
    delivery_notes ||--|{ delivery_note_details : "lines"
```

---

## 2. Data structure

### `outbounds`

| Field | Stores |
| --- | --- |
| `from_warehouse_id` | Warehouse the goods leave from |
| `to_organization_id` | Receiving organization |

The request status, document number and creator come from `requests` and `transaction_headers`.

### `request_details` (outbound lines)

`item_id`, `batch_id` (**required**), `amount`, `unit_of_measurement_id`, `base_amount`.

### At handover

| Table | Fields used for outbound |
| --- | --- |
| `handovers` | `receiver_name` = driver, `delivery_note_id` = our delivery note. `received_by` and `to_warehouse_id` are NULL. |
| `delivery_notes` | `from_organization_id` = our location, `to_organization_id` = receiver, `vehicle_plate_number`, `estimated_arrival_date`, `service_name` |
| `delivery_note_details` | Item, batch and amount shipped |

---

## 3. What it does & business process

**Purpose:** control everything that leaves the site, with a signed request, scanned picking and a delivery note for the receiver.

1. **Request:** the Warehouse Admin creates an **outbound** with the from warehouse, the receiving organization, and the **batches** and amounts.
2. **Sign:** the Logistic Supervisor signs. Status is `open`.
3. **Allocate** the requested batches in their bins ([allocation](allocation.md)).
4. **Pick:** staff scan and take the pallets out ([picking](picking.md)). Stock goes **down** when the picking is signed.
5. **Delivery note:** the admin creates a delivery note from our location to the receiver, with the truck plate, ETA, service, and the shipped lines.
6. **Handover to the driver:** load the truck and record the **driver name** and the **delivery note** on the handover. Both sign the paper copy, which is attached.
7. **Sign the handover.** The truck leaves and the request is `completed`.

### Rules

- Every outbound line needs a batch.
- The handover has no `received_by` or `to_warehouse_id`, but must have `receiver_name` and `delivery_note_id`.
- One delivery note serves one active handover.
- Stock leaves at picking. If the shipment is cancelled after picking is signed, use a [stock reversal](stock_reversal.md) on the picking.

---

## 4. Flowchart

```mermaid
flowchart TD
    A(["Need to ship to another organization"]) --> B["Create outbound<br/>from warehouse, to organization"]
    B --> C["Add batch lines"]
    C --> D{"Supervisor signs?"}
    D -- "Reject" --> C
    D -- "Sign" --> E["Allocate batches in bins"]
    E --> F["Pick and scan<br/>sign picking: stock down"]
    F --> G["Create delivery note<br/>our location → receiver"]
    G --> H["Load truck"]
    H --> I["Handover: driver name + delivery note"]
    I --> J{"Supervisor signs handover?"}
    J -- "Reject" --> I
    J -- "Sign" --> K["Truck leaves<br/>request completed"]
    K --> Z(["Done"])
```

---

## 5. Swimlane

```mermaid
flowchart LR
    subgraph WA["Warehouse Admin"]
        direction TB
        a1["1 · Create outbound request"]
        a2["4 · Allocate + create picking"]
        a3["6 · Create delivery note"]
        a4["8 · Create handover"]
    end
    subgraph SUP["Logistic Supervisor"]
        direction TB
        s1["2 · Sign request"]
        s2["9 · Sign picking + handover"]
    end
    subgraph WS["Warehouse Staff"]
        direction TB
        w1["5 · Pick and scan"]
        w2["7 · Load truck"]
    end
    subgraph DRV["Driver / Receiver organization"]
        direction TB
        d1["10 · Sign paper note,<br/>leave with goods"]
    end
    subgraph SYS["System (WISBAR)"]
        direction TB
        y1["3 · status open"]
        y2["11 · Stock down, request completed"]
    end
    a1 --> s1 --> y1 --> a2 --> w1 --> a3 --> w2 --> a4 --> s2 --> d1 --> y2
```
