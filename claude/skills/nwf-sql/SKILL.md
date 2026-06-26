---
name: nwf-sql
description: "NWFTH-MSSQL database schema expert for BME projects. Triggers: nwfthsql, bme database, what's the schema."
---

# /nwf-sql - NWFTH-MSSQL Database Expert

Comprehensive knowledge of BME882024 (formerly TFCPILOT3) database structure for warehouse management, picking systems, and inventory operations.

## Database Connection Info

### Local Dev (this machine — primary)
- **Database**: NWFDB
- **Server**: localhost:1433
- **Username**: SA
- **Container**: `nwfth-mssql` (Azure SQL Edge via Colima)
- **MCP**: `nwfth-sql` in `~/.claude.json`
- **Start**: `colima start && docker start nwfth-mssql`

### Remote (NWFTH office — read-only reference)
- **Database**: BME882024
- **Server**: 192.168.0.86:49381
- **Username**: NSW
- **Driver**: Tiberius (Rust) / ODBC (Node)

---

## Core Table Reference

### Picking Run Headers

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `Cust_PartialRun` | Partial picking runs | RunNo (PK), FormulaId, Status, RecDate |
| `Cust_BulkRun` | Bulk picking runs | RunNo (PK), FormulaId, Status, BatchNo |

### Picking Transactions

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `cust_PartialPicked` ⚠️ | Partial pick lines | RunNo+RowNum+LineId (PK), ItemKey, ToPickedPartialQty, PickedPartialQty |
| `cust_BulkPicked` ⚠️ | Bulk pick lines | RunNo+RowNum+LineId (PK), ItemKey, ToPickedBulkQty, PickedBulkQty |

⚠️ **CRITICAL**: These tables have lowercase 'c' in 'cust' - case sensitive!

### Lot Allocations

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `Cust_PartialLotPicked` | Partial lot allocations | LotTranNo, RunNo, RowNum, LineId, LotNo, AllocLotQty |
| `Cust_BulkLotPicked` | Bulk lot allocations | LotTranNo, RunNo, RowNum, LineId, LotNo, AllocLotQty |
| `Cust_PartialPalletLotPicked` | Partial pallet tracking | RunNo, RowNum, LineId, PalletID |
| `Cust_BulkPalletLotPicked` | Bulk pallet tracking | RunNo, RowNum, LineId, PalletID |

### Inventory Core

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `LotMaster` | Inventory master | ItemKey+Location+LotNo (PK), QtyOnHand, QtyCommitSales, DateExpiry, BinNo |
| `LotTransaction` | Audit trail | LotTranNo (PK), TransactionType, QtyIssued, QtyReceived |
| `BINMaster` | Bin locations | Location+BinNo (PK), Nettable, User1, User4 |
| `INMAST` | Item master | ItemKey (PK), Description, User9 (tolerance) |

### Production & Formula

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `PNMAST` | Production batch master | BatchNo (PK), Status (R/A/C), RecDate |
| `PNITEM` | Production batch items | BatchNo+Lineid (PK), ItemKey, User11 (picked qty) |
| `PNBOM` | Bill of materials | FormulaId+LineSeq (PK), ItemKey, Qty, LocationKey |
| `FMItem` | Formula items | FormulaID+SequenceNum (PK), ItemKey, LineType |

### Inventory Location

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `INLOC` | Item location assignments | Itemkey+Location (PK), QtyOnHand, QtyCommitSales |
| `QCLotTransaction` | Quality control transactions | QCKey (PK), LotNo, ItemKey, Status |
| `putawaylist` | Putaway list view | Various location/lot fields |

### Supporting

| Table | Purpose | Key Fields |
|-------|---------|------------|
| `TFC_WS_AgControl` | Allergen workstation mapping | ComputerName (PK), IsAllergen |
| `TFC_Weighup_WorkStations2` | Workstation scale config | WorkStationName (PK), ScaleID, LocationKey |
| `Seqnum` | Sequence generator | SeqId (PT=Pallect, BT=BinTransfer) |
| `BinTransfer` | Bin transfers | BinTranID (PK), BinNoFrom, BinNoTo, QtyOnHand |
| `Mintxdh` | Financial transactions | InTransId, ItemKey, Amount |
| `tbl_user` | User authentication | userid (PK), password, groupid, location |

---

## Common Query Patterns

### FEFO Lot Selection (Zone Priority: A > I > K)
```sql
SELECT TOP 1 LotNo, BinNo, DateExpiry, QtyOnHand, QtyCommitSales,
       (QtyOnHand - QtyCommitSales) AS AvailableQty
FROM LotMaster
WHERE ItemKey = @itemKey
  AND Location = 'TFC1'
  AND (QtyOnHand - QtyCommitSales) >= @targetQty
  AND LotStatus IN ('P', 'C', '', NULL)
ORDER BY DateExpiry ASC,
         CASE LEFT(BinNo, 1)
           WHEN 'A' THEN 1
           WHEN 'I' THEN 2
           WHEN 'K' THEN 3
           ELSE 4
         END ASC
```

### Get Picking Run with Lines
```sql
SELECT r.RunNo, r.FormulaId, r.FormulaDesc, r.Status,
       p.RowNum, p.LineId, p.ItemKey,
       p.ToPickedPartialQty, p.PickedPartialQty,
       p.LotNo, p.BinNo, p.ItemBatchStatus
FROM Cust_PartialRun r
LEFT JOIN cust_PartialPicked p ON r.RunNo = p.RunNo
WHERE r.RunNo = @runNo
ORDER BY p.RowNum, p.LineId
```

### Get Lot Allocations for a Pick
```sql
SELECT LotNo, BinNo, PickedPartialQty, AllocLotQty, PalletId
FROM Cust_PartialLotPicked
WHERE RunNo = @runNo AND RowNum = @rowNum AND LineId = @lineId
```

### Check Workstation Allergen Status
```sql
SELECT IsAllergen FROM TFC_WS_AgControl WHERE ComputerName = @computerName
```

### Get Next Sequence Number
```sql
-- For Pallet IDs
SELECT SeqNo FROM Seqnum WHERE SeqId = 'PT'

-- For Bin Transfer docs
SELECT SeqNo FROM Seqnum WHERE SeqId = 'BT'
```

---

## Critical Field Rules

### Weight Fields - USE THESE:
- `ToPickedPartialQty` / `PickedPartialQty` (without "KG" suffix)
- `ToPickedBulkQty` / `PickedBulkQty` (without "KG" suffix)

### Weight Fields - IGNORE (Always NULL):
- `ToPickedPartialQtyKG` / `PickedPartialQtyKG`
- `ToPickedBulkQtyKG` / `PickedBulkQtyKG`

### User ID Fields:
- 8-char fields (`RecUserId`): Truncated usernames
- 16-char fields (`ModifiedBy`): Full usernames

### Date Format:
- **Always use DD/MM/YYYY** (e.g., "10/10/2025")

---

## Transaction Workflows

### 5-Table Partial Pick Transaction (Atomic)
1. Insert `Cust_PartialLotPicked` (lot allocation)
2. Update `cust_PartialPicked` (weight)
3. Insert `LotTransaction` (audit)
4. Update `LotMaster.QtyCommitSales` (inventory)
5. Update `PNITEM.User11` (picked qty tracking)

### 6-Table Bulk Pick + Completion
1. Update `cust_BulkPicked`
2. Insert `Cust_BulkLotPicked`
3. Update `LotMaster.QtyCommitSales`
4. Insert `LotTransaction`
5. Insert `Cust_BulkPalletLotPicked`
6. Update `Cust_BulkRun.Status` (NEW → PRINT)

### PNITEM.User11 Update Pattern
```sql
-- Update picked quantity for a batch line
UPDATE PNITEM
SET User11 = @pickedQty
WHERE BatchNo = @batchNo
  AND Lineid = @lineId
  AND ItemKey = @itemKey
```

### 6-Step Putaway
1. Generate doc (Seqnum BT)
2. Financial record (Mintxdh)
3. Issue transaction (LotTransaction Type 9)
4. Receipt transaction (LotTransaction Type 8)
5. BinTransfer record
6. LotMaster consolidation

---

## Bin Transfer Flow (Legacy BME System)

> Documented from SQL trace of legacy BME Putaway system
> Source: `Docs/Putaway-Bme-Transaction.md` in BME-Putaway repo

### ⚠️ PERFORMANCE WARNING

Legacy system has **severe performance problems** — slow transfers, UI freezing, deadlocks. New implementations should use direct updates, not the batch job pattern.

### Two Transfer Patterns Identified

| Pattern | Container | UOM | Connection Reset | Validation Rounds | Performance |
|---------|-----------|-----|------------------|-------------------|-------------|
| **Simple** | ❌ | ❌ | ❌ | 1 | ✅ Fast |
| **Complex** | ✅ | ✅ | ✅ | 3 | ⚠️ Slow/Freezing |

### Phase 1: Validation Queries

#### Available Bins Lookup
```sql
SELECT BinNo, Location, Description
FROM (
    SELECT DISTINCT b.BinNo, b.Locationkey Location, Description
    FROM BinMaster a
    RIGHT OUTER JOIN LotMaster b ON a.binNo=b.binNo AND a.location=b.locationkey
    WHERE b.binNo <> @sourceBin AND b.Locationkey = @locationKey
        AND RTRIM(LTRIM(b.binNo)) <> ''
    UNION
    SELECT BinNo, Location, Description
    FROM BinMaster
    WHERE location=@locationKey AND Binno <> @sourceBin
) c
ORDER BY c.BinNo
```

#### Commitment Calculation (CRITICAL)
```sql
SELECT SUM(QtyIssued) AS Commitment
FROM (
    SELECT QtyIssued FROM LotTransaction
    WHERE Processed IN ('N','P')
        AND TransactionType IN (2,3,5,7,9,10,12,16,17,20,21)
        AND Itemkey = @itemKey AND LocationKey = @locationKey
        AND LotNo = @lotNo AND BinNo = @sourceBin
    UNION ALL
    SELECT QtyIssued FROM QCLotTransaction
    WHERE Processed IN ('N','P')
        AND TransactionType IN (2,3,5,7,9,10,12,16,17,20,21)
        AND Itemkey = @itemKey AND LocationKey = @locationKey
        AND LotNo = @lotNo AND BinNo = @sourceBin
) AS X
```

**TransactionType Values**:
| Type | Description |
|------|-------------|
| 2 | Purchase Return |
| 3 | Sales Issue |
| 5 | Mfg. Issue |
| 7 | Inventory Transfer |
| 9 | Inventory Adj. Negative |
| 10 | Damaged |
| 12 | Warehouse Move Out |
| 16 | Transfer Out |
| 17 | Move |
| 20 | Transfer Out |
| 21 | Sales Provisional |

### Phase 2: Transfer Commit (ATOMIC)

#### Step 1: Reserve Quantity (CRITICAL)
```sql
UPDATE LotMaster
SET Qtycommitsales = Qtycommitsales + @transferQty
WHERE ItemKey=@itemKey
    AND LocationKey=@locationKey
    AND LotNo=@lotNo
    AND BinNo = @sourceBin
```
**Effect**: Increases commitment on source bin by transfer quantity

#### Step 2: INSERT Source Transaction (OUT)
```sql
INSERT INTO LotTransaction (
    LotNo, ItemKey, LocationKey, DateReceived, DateExpiry,
    TransactionType, VendorlotNo, IssueDocNo, IssueDocLineNo,
    IssueDate, QtyIssued, RecUserid, RecDate, Processed, BinNo
) VALUES (
    @lotNo, @itemKey, @locationKey, @dateReceived, @dateExpiry,
    9, -- TransactionType = Inventory Adj. Negative
    @vendorLotNo, @docNo, @lineNo,
    @issueDate, @qty, @userId, @recDate, 'N', @sourceBin
)
```

#### Step 3: INSERT Destination Transaction (IN)
```sql
INSERT INTO LotTransaction (
    LotNo, ItemKey, LocationKey, DateReceived, DateExpiry,
    TransactionType, ReceiptDocNo, ReceiptDocLineNo, QtyReceived,
    Vendorkey, VendorlotNo, RecUserid, RecDate, Processed, BinNo
) VALUES (
    @lotNo, @itemKey, @locationKey, @dateReceived, @dateExpiry,
    8, -- TransactionType = Inventory Adj. Positive
    @docNo, @lineNo, @qty,
    @vendorKey, @vendorLotNo, @userId, @recDate, 'N', @destBin
)
```

### Key Business Logic

#### Available Quantity Calculation
```
Available Qty = QtyOnHand - Qtycommitsales
```

#### Transfer Commit Pattern
1. **Reserve**: UPDATE LotMaster.Qtycommitsales += transfer_qty (source bin)
2. **Audit Out**: INSERT LotTransaction with TransactionType=9 (negative adjustment)
3. **Audit In**: INSERT LotTransaction with TransactionType=8 (positive adjustment)
4. Both transactions share the same DocNo (BT-XXXXXXX)

### Complex Transfer Queries (Container/UOM)

#### Container-Aware Lot Query
```sql
SELECT
    A.LotNo, A.BinNo,
    ISNULL(C.ContainerNo, 0) AS ContainerNo,
    A.ItemKey, B.Desc1 AS Description,
    A.LocationKey AS Location,
    CASE ISNULL(C.ContainerNo, 0)
        WHEN 0 THEN CAST(ROUND(a.QtyOnHand, 4) AS DECIMAL(22,4))
        ELSE CAST(ROUND(c.QtyOnHand, 4) AS DECIMAL(22,4))
    END AS QtyOnHand,
    A.QtyCommitSales AS QtyCommited
FROM ContainerMaster C
RIGHT OUTER JOIN LotMaster A ON A.LotNo = C.LotNo
    AND A.BinNo = C.BinNo
    AND A.LocationKey = C.LocationKey
    AND A.ItemKey = C.ItemKey
INNER JOIN InMast B ON A.ItemKey = B.ItemKey
WHERE B.MultipleBinsReq = 'Y'
ORDER BY a.LotNo, a.itemkey, a.locationKey, a.binno, c.containerno
```

#### Unit of Measure Conversion
```sql
-- Get conversion factors
SELECT ToKey
FROM INQTYCNV
WHERE FROMKEY = @fromUOM
  AND (UMScope = 0
       OR UMItemClassKey IN (SELECT InClassKey FROM Inloc WHERE ItemKey = @itemKey)
       OR UMItemKey = @itemKey)
```

### Implementation Recommendations

| Legacy Pattern | Problem | New Approach |
|----------------|---------|--------------|
| Triple validation | Wastes resources | Single validation, cache results |
| Container query always | Not all items use containers | Conditional query based on item type |
| UOM check per transfer | No-op when same UOM | Skip conversion when From=To |
| Synchronous batch job | Blocking/Freezing | Direct UPDATE with transaction wrapper |
| Table locking | Deadlocks | Row-level locking (`WITH (ROWLOCK, UPDLOCK)`) |

### Decision Matrix

```
IF item.HasContainerTracking THEN
    Include ContainerMaster join
ELSE
    Skip container query

IF sourceUOM != destUOM THEN
    Perform INQTYCNV lookup
ELSE
    Skip conversion (use 1.0 factor)

IF firstValidationPassed THEN
    Cache results for commit phase
ELSE
    Fail fast (don't proceed)
```

---

## Related Table Patterns

Specialized picking for different product types (same structure):
- `Cust_CrumbPartial*` / `Cust_CrumbBulk*` - Crumb products
- `Cust_Nitrate*` - Nitrate products
- `Cust_NitriteCrumb*` - Nitrite crumb products

---

## Usage

```
/nwf-sql [query|table|help]
/nwf-sql table Cust_PartialRun    # Show table schema
/nwf-sql query fefo               # Show FEFO query pattern
/nwf-sql workflow partial         # Show partial pick workflow
```

---

## ⚠️ DATABASE COMPATIBILITY CONSTRAINTS

**Compatibility Level: 100 (SQL Server 2008)**
- `STRING_SPLIT` is NOT available (requires level 130+)
- The `mssql-list-tables` MCP tool FAILS because it uses `STRING_SPLIT` internally
- **DO NOT** alter the database compatibility level — this is a production database
- **Workaround**: Use `mssql-execute-sql` with direct queries instead:

```sql
-- List all tables (replaces mssql-list-tables)
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME

-- Describe a table's columns (replaces mssql-list-tables with table_names)
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'your_table' ORDER BY ORDINAL_POSITION

-- Get primary keys
SELECT c.COLUMN_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE c ON tc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
WHERE tc.TABLE_NAME = 'your_table' AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
```

---

## ⚠️ DATABASE SAFETY RULES

**NEVER execute without explicit user approval:**
- `ALTER TABLE` (any kind - add, modify, drop columns)
- `DROP TABLE`, `DROP COLUMN`, `DROP INDEX`
- `DELETE` without `WHERE` clause
- `UPDATE` without `WHERE` clause
- `TRUNCATE TABLE`
- `CREATE INDEX` (without performance justification)
- Any schema modification

**Safe operations (proceed with confidence):**
- `SELECT` (any query - read-only)
- `INSERT` with explicit values (after validation)
- `UPDATE` with `WHERE` clause (after confirmation)
- `DELETE` with `WHERE` clause (after confirmation)

**When using MCP BME-MSSQL:**
- Always confirm before executing data modifications
- Review `WHERE` clauses carefully
- Use transactions for multi-table operations
- Prefer read-only queries for exploration

---

## Full Schema Reference

See: `ψ/memory/learn/nwf-sql-database-schema.md`

---

## NWFTH Operational Notes (salvaged from the retired /sop-nwfth)

- **App test login** (all NWFTH projects): user `deachawat`, password from `$NWFTH_TEST_PASSWORD` (export locally — never commit the literal) at `http://localhost:<port>`. You ARE on the host — use `localhost`, never SSH to self.
- **Deploy** (Docker NWFTH projects): `bash ~/ghq/github.com/deachawatss/gale-oracle/scripts/deploy-project.sh <project-path> <project-name>` — does `git pull` + `docker compose up --build` + health check + auto-rollback. Run from the main/home session after merge, not from a worktree.
- **Merge gate**: NWFTH is production — direct push to `main` is hook-blocked, so open a PR. The owning oracle runs `/scrutinize` → self-merges (high risk = scrutinize harder, same merger; L1 is the only reviewer). Stack is MSSQL+Docker *for current projects* — still detect from the repo, never assume.

---

*Logged via /skill-creator - NWFTH-MSSQL Database Expert*
