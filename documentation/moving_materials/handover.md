# Handover

> A **handover** records that picked material was **passed from the warehouse to the receiver**, and how much actually changed hands per picked line. It has **no stock effect**: stock already went down at [picking](picking.md). If the receiver is a warehouse (staging, return, quarantine, another warehouse), the handover lines are then [plotted](plotting.md) and [put away](put_away.md) there. For an [outbound](outbound.md) the receiver is the driver, with a delivery note.

Related: [Picking](picking.md) · [Plotting](plotting.md) · [Put away](put_away.md) · [Outbound](outbound.md) · [Delivery note](delivery_note.md)

---

## 1. Data architecture

```mermaid
erDiagram
    transaction_headers ||--o| handovers : "is a"
    requests ||--o{ handovers : "for request"
    pickings ||--o| handovers : "hands over"
    warehouses ||--o{ handovers : "from / to"
    users ||--o{ handovers : "handed_by / received_by"
    delivery_notes ||--o| handovers : "outbound only"
    handovers ||--|{ handover_details : "has lines"
    picking_details ||--o| handover_details : "handed over as"
    handover_details ||--o{ plottings : "plotted to bin"
    handovers ||--o| put_aways : "put away by"
```

---

## 2. Data structure

### `handovers`: header

| Field | Stores |
| --- | --- |
| `request_id`, `request_type` | The request. The type decides who receives. |
| `picking_id` | The picking being handed over |
| `from_warehouse_id` | Must be the picking warehouse |
| `to_warehouse_id` | Receiving warehouse. **NULL for an outbound.** |
| `handed_by` | Warehouse user giving it |
| `received_by` | User receiving it. **NULL exactly for an outbound.** |
| `receiver_name` | Driver or courier. **Required exactly for an outbound.** |
| `delivery_note_id` | Issued delivery note. **Required exactly for an outbound.** |
| `handed_over_at` | When it was handed over |

### `handover_details`: one per picked line

| Field | Stores |
| --- | --- |
| `picking_detail_id` | Picked line |
| `amount` + `unit_of_measurement_id` | Quantity **actually** handed over |
| `base_amount` | In base unit (trigger) |
| `remarks` | Notes on differences |

---

## 3. What it does & business process

**Purpose:** transfer responsibility for the material from the warehouse to the receiver, with both names on record.

1. **Picking is signed.** The material is in the staging area.
2. **Create the handover** for that picking. The system fills one line per picked line.
3. **Who receives depends on the request type:**

   | Request type | Receiver | `to_warehouse_id` |
   | --- | --- | --- |
   | Production order | Staging Staff of the production | Production **staging** warehouse |
   | Production return | Warehouse / Staging Staff | Production **return** warehouse |
   | Internal transfer | Warehouse Staff of the target | Target warehouse |
   | Production reject | Quarantine / Warehouse Staff | **Quarantine** warehouse |
   | Outbound | **Driver** (`receiver_name`) + **delivery note** | none |

4. **Count together:** the giver and receiver check each line, and record the amount actually handed over with remarks for any difference.
5. **Submit**, and the supervisor signs.
6. **After signing:**
   - **to a warehouse:** each line is [plotted](plotting.md) into the target warehouse and [put away](put_away.md), so stock rises there
   - **outbound:** the goods leave with the driver and the delivery note

### Rules

- `handed_by` and `received_by` must be different people.
- An outbound has no `received_by` or `to_warehouse_id`, but needs `receiver_name` and `delivery_note_id`.
- A non-outbound needs `received_by`, and has no receiver name or delivery note.
- One active handover per picking and per delivery note, and one active line per picked line.

---

## 4. Flowchart

```mermaid
flowchart TD
    A(["Picking signed"]) --> B["Create handover for picking<br/>one line per picked line"]
    B --> C{"Request type = outbound?"}
    C -- "Yes" --> D["Create delivery note<br/>our location → receiver"]
    D --> E["Set receiver_name = driver<br/>link delivery note"]
    C -- "No" --> F["Set received_by user<br/>to_warehouse by request type"]
    E --> G
    F --> G["Giver and receiver count lines"]
    G --> H{"Amount differs<br/>from picked?"}
    H -- "Yes" --> I["Record actual amount + remarks"]
    H -- "No" --> J
    I --> J["Submit for sign-off"]
    J --> K{"Supervisor decision"}
    K -- "Reject" --> G
    K -- "Sign" --> L{"Outbound?"}
    L -- "Yes" --> M(["Truck leaves"])
    L -- "No" --> N["Plot to target warehouse"] --> O["Put away: stock up there"] --> P(["Done"])
```

---

## 5. Swimlane

```mermaid
flowchart LR
    subgraph WA["Warehouse Admin"]
        direction TB
        a1["1 · Create handover from picking"]
        a2["2 · Outbound: issue delivery note"]
        a3["5 · Submit for sign-off"]
    end
    subgraph WS["Warehouse Staff (Giver)"]
        direction TB
        w1["3 · Hand over pallets"]
    end
    subgraph RCV["Receiver<br/>Staging Staff / Driver / Warehouse Staff"]
        direction TB
        r1["4 · Count and confirm amount"]
        r2["8 · Plot + put away at destination<br/>not for outbound"]
    end
    subgraph SUP["Logistic Supervisor"]
        direction TB
        s1{"6 · Sign or reject"}
    end
    subgraph SYS["System (WISBAR)"]
        direction TB
        y1["7 · Lock handover,<br/>open plotting for target"]
    end
    a1 --> a2 --> w1 --> r1 --> a3 --> s1
    s1 -- "Reject" --> r1
    s1 -- "Sign" --> y1 --> r2
```
