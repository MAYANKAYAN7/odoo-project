# Expense Management System - Database

PostgreSQL database layer for expense management system with multi-level approval workflows.

## 🚀 Quick Setup

### Prerequisites
- PostgreSQL 15+
- pgAdmin 4 or psql

### Installation
1. Create database:
   ```sql
   CREATE DATABASE expense_demo;
   ```

2. Run setup script:
   - Connect to `expense_demo` database in pgAdmin
   - Execute `database_setup.sql`

3. Verify installation:
   ```sql
   SELECT * FROM expense_dashboard;
   ```

## 📊 Database Structure

| Table | Description |
|-------|-------------|
| `companies` | Multi-tenant company data |
| `users` | Role-based user management (Admin/Manager/Employee) |
| `expense_categories` | Expense categories with color coding |
| `expenses` | Core expense records with approval status |
| `expense_approvals` | Approval workflow tracking |

## 🔧 API Functions

### Submit Expense
```sql
SELECT submit_expense(
    user_id,        -- INTEGER
    category_id,    -- INTEGER
    title,          -- VARCHAR(255)
    amount,         -- DECIMAL(10,2)
    expense_date    -- DATE
);
-- Returns: expense_id (INTEGER)
```

### Process Approval
```sql
SELECT approve_expense(
    approval_id,    -- INTEGER
    approver_id,    -- INTEGER
    action,         -- 'APPROVE' or 'REJECT'
    comments        -- TEXT (optional)
);
-- Returns: BOOLEAN
```

## 📈 Views

### Expense Dashboard
```sql
SELECT * FROM expense_dashboard;
```
Returns: All expenses with employee names, categories, and status

### Pending Approvals
```sql
SELECT * FROM pending_approvals;
```
Returns: Expenses awaiting manager approval

### User Statistics
```sql
SELECT * FROM user_stats;
```
Returns: Spending analytics per user

## 🎯 Demo Data

### Company
- **TechCorp Demo** (USD)

### Users
| ID | Name | Email | Role |
|----|------|-------|------|
| 1 | Mayank Singh | admin@techcorp.com | ADMIN |
| 2 | Gorav Sharma | manager@techcorp.com | MANAGER |
| 3 | Sahil Kumar | sahil@techcorp.com | EMPLOYEE |
| 4 | Lavish Gupta | lavish@techcorp.com | EMPLOYEE |

### Sample Expenses
- Flight to Client Meeting ($450 - Pending)
- Team Lunch ($285.50 - Approved)  
- Office Chair ($299.99 - Pending)
- Software Subscription ($89 - Rejected)
- Conference Ticket ($650 - Approved)

## 🔌 Integration Examples

### Node.js Connection
```javascript
const { Pool } = require('pg');

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'expense_demo',
    password: 'your_password',
    port: 5432,
});

// Submit expense
const result = await pool.query(
    'SELECT submit_expense($1, $2, $3, $4, $5)',
    [userId, categoryId, title, amount, date]
);

// Get dashboard data
const expenses = await pool.query('SELECT * FROM expense_dashboard');
```

### REST API Endpoints
```javascript
// Suggested endpoint structure for UI integration
GET    /api/expenses          // expense_dashboard view
POST   /api/expenses          // submit_expense() function
GET    /api/approvals         // pending_approvals view  
POST   /api/approvals/:id     // approve_expense() function
GET    /api/stats             // user_stats view
```

## 🗄️ Connection Details

- **Database**: expense_demo
- **Host**: localhost
- **Port**: 5432
- **User**: postgres

## ✅ Status

**Database Development**: Complete  
**Tables**: 5 tables with proper relationships  
**Functions**: 2 core business logic functions  
**Views**: 3 optimized dashboard views  
**Demo Data**: Realistic test scenarios  
**Performance**: Indexed for common queries  

## 🔍 Testing Queries

```sql
-- View all expenses
SELECT * FROM expense_dashboard ORDER BY created_at DESC;

-- Check pending approvals
SELECT * FROM pending_approvals;

-- Submit test expense
SELECT submit_expense(3, 1, 'Test Expense', 100.00, CURRENT_DATE);

-- Approve expense (Manager Gorav approving)
SELECT approve_expense(1, 2, 'APPROVE', 'Approved for demo');

-- Get user statistics
SELECT * FROM user_stats;

-- Category breakdown
SELECT category_name, COUNT(*) as count, SUM(amount) as total
FROM expense_dashboard GROUP BY category_name;
```

## 📝 Notes

- All monetary values in USD
- Timestamps in UTC
- Employee approval requires manager_id relationship
- Status transitions: PENDING → APPROVED/REJECTED
- Optimized indexes for common query patterns

---
**Database Layer**: Ready for production  
**Integration**: API-friendly structure  
**Demo Ready**: Sample data included
