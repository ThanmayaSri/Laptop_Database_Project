-- Drop existing tables in correct order (respecting foreign keys)
DROP TABLE IF EXISTS Customer_Review;
DROP TABLE IF EXISTS Laptop;
DROP TABLE IF EXISTS Brand;
DROP TABLE IF EXISTS Processor;
DROP TABLE IF EXISTS Processor_Brand;
DROP TABLE IF EXISTS RAM;
DROP TABLE IF EXISTS GPU;
DROP TABLE IF EXISTS GPU_Brand;
DROP TABLE IF EXISTS Storage;
DROP TABLE IF EXISTS Display;
DROP TABLE IF EXISTS Operating_System;

-- Create tables
-- Brand table
CREATE TABLE Brand (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(255) NOT NULL UNIQUE
);

-- Processor_Brand table
CREATE TABLE Processor_Brand (
    processor_brand_id SERIAL PRIMARY KEY,
    processor_brand_name VARCHAR(255) NOT NULL UNIQUE
);

-- Processor table
CREATE TABLE Processor (
    processor_id SERIAL PRIMARY KEY,
    processor_specifications VARCHAR(255) NOT NULL,
    processor_brand_id INTEGER REFERENCES Processor_Brand(processor_brand_id),
    processor_ghz NUMERIC(3,1)
);

-- RAM table
CREATE TABLE RAM (
    ram_id SERIAL PRIMARY KEY,
    ram_gb INTEGER NOT NULL,
    ram_type VARCHAR(50),
    ram_expandable_gb INTEGER,
    CONSTRAINT chk_ram_size CHECK (ram_gb > 0),
    CONSTRAINT chk_ram_expandable CHECK (ram_expandable_gb >= 0)
);

-- GPU_Brand table
CREATE TABLE GPU_Brand (
    gpu_brand_id SERIAL PRIMARY KEY,
    gpu_brand_name VARCHAR(255) NOT NULL UNIQUE
);

-- GPU table
CREATE TABLE GPU (
    gpu_id SERIAL PRIMARY KEY,
    gpu_name VARCHAR(255) NOT NULL,
    gpu_brand_id INTEGER REFERENCES GPU_Brand(gpu_brand_id),
    vram_gb INTEGER
);

-- Storage table
CREATE TABLE Storage (
    storage_id SERIAL PRIMARY KEY,
    ssd_storage_gb INTEGER DEFAULT 0,
    hdd_storage_gb INTEGER DEFAULT 0,
    CONSTRAINT chk_storage CHECK (ssd_storage_gb >= 0 AND hdd_storage_gb >= 0)
);

-- Display table
CREATE TABLE Display (
    display_id SERIAL PRIMARY KEY,
    display_type VARCHAR(50),
    screen_size_inch NUMERIC(4,1) NOT NULL,
    CONSTRAINT chk_screen_size CHECK (screen_size_inch > 0)
);

-- Operating_System table
CREATE TABLE Operating_System (
    os_id SERIAL PRIMARY KEY,
    os_name VARCHAR(255) NOT NULL UNIQUE
);

-- Laptop table
CREATE TABLE Laptop (
    laptop_id SERIAL PRIMARY KEY,
    brand_id INTEGER REFERENCES Brand(brand_id),
    processor_id INTEGER REFERENCES Processor(processor_id),
    ram_id INTEGER REFERENCES RAM(ram_id),
    gpu_id INTEGER REFERENCES GPU(gpu_id),
    storage_id INTEGER REFERENCES Storage(storage_id),
    display_id INTEGER REFERENCES Display(display_id),
    os_id INTEGER REFERENCES Operating_System(os_id),
    model_name VARCHAR(255) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    battery_life_hours NUMERIC(4,1),
    adapter_watt INTEGER,
    CONSTRAINT chk_price CHECK (price >= 0)
);

-- Customer_Review table
CREATE TABLE Customer_Review (
    review_id SERIAL PRIMARY KEY,
    laptop_id INTEGER REFERENCES Laptop(laptop_id),
    review_text TEXT NOT NULL
);

-- Create indexes for frequently queried columns
CREATE INDEX idx_laptop_price ON Laptop(price);
CREATE INDEX idx_laptop_brand ON Laptop(brand_id);
CREATE INDEX idx_laptop_ram ON Laptop(ram_id);
CREATE INDEX idx_laptop_processor ON Laptop(processor_id);
 