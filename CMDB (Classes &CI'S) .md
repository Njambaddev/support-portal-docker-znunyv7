# CMDB — Creating a CI Class and Config Items
**System:** Atlancis OTRS ITSM (mysupportdev.atlancis.com)
**Date:** 2026-05-05

---

## Overview

A CI Class is a template that defines what type of asset you are tracking (e.g. Servers, Switches, Software Licences). Each class has its own schema (set of fields), and individual Config Items (CIs) are instances of that class.

Creating a new class involves four stages: registering the class, assigning permissions, defining the schema, and then adding CIs.

---

## Step 1 — Create the Class in General Catalog

1. Log in as an admin agent.
2. Navigate to **Admin → General Catalog**.
3. Click **Add Catalog Item**.
4. Fill in the following fields:

   | Field | Value |
   |---|---|
   | Class | `ITSM::ConfigItem::Class` |
   | Name | Your class name, e.g. `Servers` |
   | Validity | `valid` |
   | Comment | Optional — short description of the class |

5. Click **Save**.

---

## Step 2 — Assign a Permission Group

1. In General Catalog, click on the class you just created.
2. Set the **Permission** field to `itsm-configitem`.
   - This is the standard group on this instance. All agents in that group will be able to view and edit CIs of this class.
   - If you need restricted access (e.g. only a specific team), create a new group first under **Admin → Groups**, then assign it here.
3. Click **Save**.

---

## Step 3 — Define the Class Schema

The schema controls which fields appear when creating or editing a CI of this class. It is written in YAML format.

1. Navigate to **Admin → Configuration Management**.
2. Find your new class in the list and click **Change Definition**.
3. Enter the YAML definition. Use the template below as a starting point:

```yaml
---
- Key: Vendor
  Name: Vendor
  Searchable: 1
  Input:
    Type: Text
    Size: 50
    MaxLength: 100

- Key: Model
  Name: Model
  Searchable: 1
  Input:
    Type: Text
    Size: 50
    MaxLength: 100

- Key: SerialNumber
  Name: Serial Number
  Searchable: 1
  Input:
    Type: Text
    Size: 50
    MaxLength: 100

- Key: IPAddress
  Name: IP Address
  Searchable: 1
  Input:
    Type: Text
    Size: 50
    MaxLength: 50

- Key: Owner
  Name: Owner
  Input:
    Type: Customer

- Key: InstallDate
  Name: Install Date
  Input:
    Type: Date
    YearPeriodPast: 10
    YearPeriodFuture: 0

- Key: Note
  Name: Note
  Input:
    Type: TextArea
```

4. Click **Save**. OTRS will validate the YAML — it will show an error if the syntax is incorrect.

### Available Field Types

| Type | Description |
|---|---|
| `Text` | Single-line text input |
| `TextArea` | Multi-line text input |
| `Integer` | Whole number |
| `Date` | Date picker |
| `DateTime` | Date and time picker |
| `Customer` | Customer user lookup |
| `GeneralCatalog` | Dropdown from a General Catalog class |
| `CIClassReference` | Link to another CI |

### Useful Field Options

| Option | Description |
|---|---|
| `Searchable: 1` | Makes the field available in the CI search screen |
| `Required: 1` | Makes the field mandatory when creating/editing a CI |
| `CountMin` / `CountMax` | Minimum/maximum number of values for a field |

---

## Step 4 — Create Individual Config Items

1. Click **CMDB** in the top navigation bar.
2. Click **New Config Item**.
3. Select your class from the dropdown.
4. Fill in the form:

   | Field | Description |
   |---|---|
   | Name | Display name for this CI |
   | Deployment State | Current lifecycle stage, e.g. `Production`, `Planned`, `Retired` |
   | Incident State | Current health, e.g. `Operational`, `Warning`, `Incident` |
   | (Custom fields) | All fields you defined in the schema in Step 3 |

5. Click **Save**.
   - OTRS automatically assigns a unique number in the format `ConfigItem#XXXXXXXXXX`.
   - A version history entry is created automatically.

---

## Step 5 — Link CIs to Tickets (Optional)

From the CI detail view (zoom screen):

1. Click **Link** in the action menu.
2. Search for a ticket, service, or another CI.
3. Select the link type:
   - `RelevantTo` — the CI is relevant to the ticket/incident
   - `DependsOn` — the CI depends on another CI
4. Click **Add Links**.

> **Note:** On this instance `SetIncidentStateOnLink` is disabled, meaning linking a CI to an incident ticket will not automatically change the CI's incident state. This must be updated manually.

---

## Step 6 — Bulk Import (For Large Numbers of CIs)

For importing many CIs at once, use one of the following methods:

### Option A — OTRS Console (CSV/script based)
```bash
/opt/otrs/bin/otrs.Console.pl Maint::ITSM::Configitem::ListInvalidConfigItems
```
Use the GenericInterface REST/SOAP web service to POST CI data programmatically. This is how the PDU, Outlets, and Circuits were populated on this instance via `AI_USER`.

### Option B — Import/Export Module
1. Go to **Admin → Import/Export**.
2. Create a new import template for your CI class.
3. Map CSV columns to CI fields.
4. Upload the CSV file.

---

## Key Behaviours to Know

| Topic | Detail |
|---|---|
| **Versioning** | Every save creates a new version. Full history is preserved and viewable via the History menu on each CI. |
| **Number generator** | This instance uses AutoIncrement — numbers are sequential and cannot be manually set. |
| **Deployment State** | Must be set on each CI — CIs without a deployment state will not appear correctly in reports or on dashboards. |
| **Incident State** | Must be set to `Operational` by default for new production assets. |
| **Definition updates** | You can update a class definition at any time. Existing CI versions retain the old field structure; only new versions use the updated schema. |
| **Deleting a class** | A class can only be deactivated (set to invalid) if it has no CIs. If it has CIs, all CIs must be deleted first. |
| **Permission group** | All three active classes on this instance (PDU, Outlets, Circuits) use the `itsm-configitem` group. |

---

## Current Active Classes on This Instance

| Class | CIs | Key Fields |
|---|---|---|
| PDU | 35 | PDU IP, Name, Serial No, Model, Alive |
| Circuits | 185 | PDU IP, Circuit Index, Name, Alive, Rated Amp, Rated Volt, Amp State, Alarm |
| Outlets | 973 | PDU IP, Index, Binding Circuit, Name, Rated Volt, Rated Amp, Amp State, Relay State |

---

*Document maintained by the Atlancis OTRS administration team.*
