# Put Away (Stock In)

> A **put away** physically places plotted goods into their bins and **raises bin stock**. One put away covers the plotted lines of **one source document**: an incoming, a handover, or a production day sheet (for group returns). Each put-away line carries out exactly one [plotting](plotting.md).

Related: [Plotting](plotting.md) · [Incoming](incoming.md) · [Handover](handover.md) · [Production usage](production_usage.md) · [Stock movement](stock_movement.md)

---

## 1. Data architecture

```mermaid
erDiagram
    stock_movements ||--o| put_aways : "is a"
    transaction_headers ||--o{ put_aways : "source: incoming / handover / day sheet"
    put_aways ||--|{ put_away_details : "has lines"
    stock_movement_details ||--o| put_away_details : "is a (IN line)"
    plottings ||--o| put_away_details : "carried out by"
    warehouse_bin_inventories ||--o{ stock_movement_details : "increased"
```

---

## 2. Data structure

### `put_aways`: header

| Field | Stores |
| --- | --- |
| `source_header_id` / `source_header_type` | The document whose plotted stock is put away: `incoming`, `handover` or `production_group_usage` |
| `active_key` | 1 = draft or signed, NULL = reversed or deleted |
| `one_per_source_key` | Enforces **one active put away per incoming or handover**. A day sheet may have several. |

### `put_away_details`: one line per plotting

| Field | Stores |
| --- | --- |
| `plotting_id` | The plotting this line carries out |
| `source_header_id` | Copied from the header (must match the plotting's source) |

It inherits from `stock_movement_details`: `warehouse_bin_inventory_id`, `type = in`, `amount`, `pallet_count`, `moved_by`.

---

## 3. What it does & business process

**Purpose:** turn the plan into real stock, so the bin balance only goes up once the pallet is physically in the bin.

1. **Open a put away** for a signed source document that has planned plottings.
2. **One line per plotting.** The system creates an **IN** line on the plotted bin inventory with the plotted amount.
3. **Move:** warehouse staff (forklift) take each pallet to its bin.
   - Scan the box and the **bin barcode**. The bin must be the plotted bin.
   - Record `moved_by` and the pallet count.
4. **Differences:** if the full amount does not fit or a pallet is damaged:
   - cancel that plotting with a reason
   - plot again, and put away the new plotting
5. **Submit** for sign-off. The supervisor signs.
6. **On signing:**
   - bin stock **increases** by each line, and `filled_at` is set if the bin was empty
   - each plotting becomes `put_away`
7. **Mistakes after signing** are fixed with a [stock reversal](stock_reversal.md).

### Rules

- A put-away line must be **in**.
- It must move the bin inventory of its own plotting.
- Only one active put away per incoming or handover. A production day sheet can have several, for returns during the day.
- Bins must be active.

---

## 4. Flowchart

```mermaid
flowchart TD
    A(["Source signed and plotted"]) --> B{"Active put away already<br/>exists for incoming / handover?"}
    B -- "Yes" --> X["Continue the existing one"]
    B -- "No" --> C["Create put away for the source"]
    X --> D
    C --> D["Create IN line per planned plotting"]
    D --> E["Staff scan box and bin"]
    E --> F{"Bin = plotted bin?"}
    F -- "No" --> E
    F -- "Yes" --> G{"Full amount fits?"}
    G -- "No" --> H["Cancel plotting with reason<br/>re-plot"] --> D
    G -- "Yes" --> I{"More lines?"}
    I -- "Yes" --> E
    I -- "No" --> J["Submit for sign-off"]
    J --> K{"Supervisor decision"}
    K -- "Reject" --> E
    K -- "Sign" --> L["Bin stock + amount<br/>plotting = put_away"]
    L --> Z(["Stock available"])
```

---

## 5. Swimlane

```mermaid
flowchart LR
    subgraph WA["Warehouse Admin"]
        direction TB
        a1["1 · Create put away for source"]
        a2["7 · Submit for sign-off"]
    end
    subgraph SYS["System (WISBAR)"]
        direction TB
        y1["2 · Make IN line per plotting"]
        y2["5 · Check bin = plotted bin"]
        y3["9 · Raise bin stock,<br/>plottings = put_away"]
    end
    subgraph WS["Warehouse Staff"]
        direction TB
        w1["3 · Take pallet to bin"]
        w2["4 · Scan box and bin"]
        w3["6 · Confirm amount, pallets"]
    end
    subgraph SUP["Logistic Supervisor"]
        direction TB
        s1{"8 · Sign or reject"}
    end
    a1 --> y1 --> w1 --> w2 --> y2 --> w3 --> a2 --> s1
    s1 -- "Reject" --> w2
    s1 -- "Sign" --> y3
```
