CREATE TABLE customers (
    id UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT PK_Customers PRIMARY KEY 
        DEFAULT NEWSEQUENTIALID(),

    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,

    identification_number CHAR(13) NOT NULL,
    birth_date DATE NOT NULL,

    address NVARCHAR(255) NOT NULL,
    email NVARCHAR(150) NOT NULL,
    phone CHAR(8) NOT NULL,

    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_Customers_Identification UNIQUE (identification_number),
    CONSTRAINT UQ_Customers_Email UNIQUE (email)
);

CREATE TABLE loans (
    id UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_Loans PRIMARY KEY
        DEFAULT NEWSEQUENTIALID(),

    customer_id UNIQUEIDENTIFIER NOT NULL,
    loan_date DATETIME2 DEFAULT SYSDATETIME(),
    amount DECIMAL(18,2) NOT NULL,
    term_months INT NOT NULL,

    purpose NVARCHAR(200) NULL,
    annual_interest_rate DECIMAL(5,2) NULL,
    status VARCHAR(20) NOT NULL,
    total_payable DECIMAL(18,2) NULL,
    outstanding_balance DECIMAL(18,2) NULL,
    payment_status VARCHAR(20) NULL,

    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Loans_Customers
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE,

    CONSTRAINT CK_Loans_Amount CHECK (amount > 0),
    CONSTRAINT CK_Loans_Term CHECK (term_months > 0)
);

CREATE INDEX IX_Loans_Customer_Status ON loans(customer_id, status);

CREATE TABLE loan_status_history (
    id UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_LoanStatusHistory PRIMARY KEY
        DEFAULT NEWSEQUENTIALID(),

    loan_id UNIQUEIDENTIFIER NOT NULL,

    status VARCHAR(20) NOT NULL,
    notes NVARCHAR(200) NULL,

    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_LoanStatusHistory_Loans
        FOREIGN KEY (loan_id) REFERENCES loans(id)
        ON DELETE CASCADE
);

CREATE INDEX IX_LoanStatusHistory_LoanId_CreatedAt
    ON loan_status_history(loan_id, created_at DESC);

CREATE TABLE loan_payments (
    id UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_LoanPayments PRIMARY KEY
        DEFAULT NEWSEQUENTIALID(),

    loan_id UNIQUEIDENTIFIER NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    payment_date DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    notes NVARCHAR(300) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_LoanPayments_Loans
        FOREIGN KEY (loan_id) REFERENCES loans(id)
        ON DELETE CASCADE,
);

CREATE INDEX IX_LoanPayments_LoanId_PaymentDate
    ON loan_payments(loan_id, payment_date DESC);
