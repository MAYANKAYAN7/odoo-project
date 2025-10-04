-- EXPENSE MANAGEMENT SYSTEM DATABASE
-- Complete setup for PostgreSQL
-- Generated: 2025-10-04

DROP VIEW IF EXISTS pending_approvals CASCADE;
DROP VIEW IF EXISTS expense_dashboard CASCADE;
DROP FUNCTION IF EXISTS approve_expense CASCADE;
DROP FUNCTION IF EXISTS submit_expense CASCADE;
DROP TABLE IF EXISTS expense_approvals CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS expense_categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- Create Tables
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    base_currency VARCHAR(3) DEFAULT 'USD'
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) CHECK (role IN ('ADMIN', 'MANAGER', 'EMPLOYEE')),
    manager_id INTEGER REFERENCES users(id)
);

CREATE TABLE expense_categories (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#3498db'
);

CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(id),
    user_id INTEGER REFERENCES users(id),
    category_id INTEGER REFERENCES expense_categories(id),
    title VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    expense_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE expense_approvals (
    id SERIAL PRIMARY KEY,
    expense_id INTEGER REFERENCES expenses(id),
    approver_id INTEGER REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Demo Data
INSERT INTO companies (name, base_currency) VALUES ('TechCorp Demo', 'USD');

INSERT INTO users (company_id, email, first_name, last_name, role) VALUES
(1, 'admin@techcorp.com', 'Mayank', 'Singh', 'ADMIN'),
(1, 'manager@techcorp.com', 'Gorav', 'Sharma', 'MANAGER'),
(1, 'sahil@techcorp.com', 'Sahil', 'Kumar', 'EMPLOYEE'),
(1, 'lavish@techcorp.com', 'Lavish', 'Gupta', 'EMPLOYEE');

UPDATE users SET manager_id = 2 WHERE id IN (3, 4);

INSERT INTO expense_categories (company_id, name, color) VALUES
(1, 'Travel', '#e74c3c'),
(1, 'Food & Entertainment', '#f39c12'),
(1, 'Office Supplies', '#2ecc71'),
(1, 'Software & Tools', '#9b59b6'),
(1, 'Training', '#3498db'),
(1, 'Marketing', '#1abc9c');

INSERT INTO expenses (company_id, user_id, category_id, title, amount, expense_date, status) VALUES
(1, 3, 1, 'Flight to Client Meeting', 450.00, '2024-10-01', 'PENDING'),
(1, 3, 2, 'Team Lunch with Clients', 285.50, '2024-10-02', 'APPROVED'),
(1, 4, 3, 'Ergonomic Office Chair', 299.99, '2024-10-03', 'PENDING'),
(1, 4, 4, 'Slack Pro Subscription', 89.00, '2024-10-04', 'REJECTED'),
(1, 3, 5, 'React Conference Ticket', 650.00, '2024-09-28', 'APPROVED'),
(1, 4, 1, 'Uber for Client Visit', 45.75, '2024-10-03', 'PENDING');

INSERT INTO expense_approvals (expense_id, approver_id, status) VALUES
(1, 2, 'PENDING'),
(3, 2, 'PENDING'),
(6, 2, 'PENDING');

-- Create Functions
CREATE OR REPLACE FUNCTION submit_expense(
    p_user_id INTEGER,
    p_category_id INTEGER,
    p_title VARCHAR(255),
    p_amount DECIMAL(10,2),
    p_expense_date DATE
) RETURNS INTEGER AS $$
DECLARE
    v_expense_id INTEGER;
    v_company_id INTEGER;
    v_manager_id INTEGER;
BEGIN
    SELECT company_id, manager_id INTO v_company_id, v_manager_id
    FROM users WHERE id = p_user_id;
    
    INSERT INTO expenses (company_id, user_id, category_id, title, amount, expense_date, status)
    VALUES (v_company_id, p_user_id, p_category_id, p_title, p_amount, p_expense_date, 'PENDING')
    RETURNING id INTO v_expense_id;
    
    IF v_manager_id IS NOT NULL THEN
        INSERT INTO expense_approvals (expense_id, approver_id, status)
        VALUES (v_expense_id, v_manager_id, 'PENDING');
    END IF;
    
    RETURN v_expense_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION approve_expense(
    p_approval_id INTEGER,
    p_approver_id INTEGER,
    p_action VARCHAR(10),
    p_comments TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_expense_id INTEGER;
BEGIN
    UPDATE expense_approvals 
    SET status = p_action, comments = p_comments
    WHERE id = p_approval_id AND approver_id = p_approver_id;
    
    SELECT expense_id INTO v_expense_id 
    FROM expense_approvals WHERE id = p_approval_id;
    
    UPDATE expenses 
    SET status = CASE WHEN p_action = 'APPROVE' THEN 'APPROVED' ELSE 'REJECTED' END
    WHERE id = v_expense_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create Views
CREATE VIEW expense_dashboard AS
SELECT 
    e.id,
    e.title,
    e.amount,
    e.currency,
    e.status,
    e.expense_date,
    u.first_name || ' ' || u.last_name as employee_name,
    u.email as employee_email,
    c.name as category_name,
    c.color as category_color,
    e.created_at
FROM expenses e
JOIN users u ON e.user_id = u.id
JOIN expense_categories c ON e.category_id = c.id
ORDER BY e.created_at DESC;

CREATE VIEW pending_approvals AS
SELECT 
    ea.id as approval_id,
    e.id as expense_id,
    e.title,
    e.amount,
    e.currency,
    u.first_name || ' ' || u.last_name as employee_name,
    u.email as employee_email,
    approver.first_name || ' ' || approver.last_name as approver_name,
    ea.created_at as pending_since
FROM expense_approvals ea
JOIN expenses e ON ea.expense_id = e.id
JOIN users u ON e.user_id = u.id
JOIN users approver ON ea.approver_id = approver.id
WHERE ea.status = 'PENDING'
ORDER BY ea.created_at ASC;

CREATE VIEW user_stats AS
SELECT 
    u.id,
    u.first_name || ' ' || u.last_name as name,
    u.role,
    COUNT(e.id) as total_expenses,
    COALESCE(SUM(CASE WHEN e.status = 'APPROVED' THEN e.amount END), 0) as approved_amount,
    COALESCE(SUM(CASE WHEN e.status = 'PENDING' THEN e.amount END), 0) as pending_amount,
    COALESCE(SUM(CASE WHEN e.status = 'REJECTED' THEN e.amount END), 0) as rejected_amount
FROM users u
LEFT JOIN expenses e ON u.id = e.user_id
WHERE u.company_id = 1
GROUP BY u.id, u.first_name, u.last_name, u.role
ORDER BY approved_amount DESC;

-- Create Indexes for Performance
CREATE INDEX idx_expenses_user_status ON expenses(user_id, status);
CREATE INDEX idx_expenses_company_date ON expenses(company_id, expense_date);
CREATE INDEX idx_expense_approvals_approver ON expense_approvals(approver_id, status);
CREATE INDEX idx_users_company_role ON users(company_id, role);

-- Verification Queries
SELECT 'Database setup completed successfully!' as status;
SELECT 'Run: SELECT * FROM expense_dashboard;' as next_step;

-- Quick Stats
SELECT 
    'Companies' as entity, COUNT(*) as count FROM companies
UNION ALL
SELECT 'Users', COUNT(*) FROM users
UNION ALL
SELECT 'Categories', COUNT(*) FROM expense_categories
UNION ALL
SELECT 'Expenses', COUNT(*) FROM expenses
UNION ALL
SELECT 'Approvals', COUNT(*) FROM expense_approvals;
