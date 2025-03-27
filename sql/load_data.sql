-- Drop existing tables if they exist
DROP TABLE IF EXISTS raw_laptop_data;
DROP TABLE IF EXISTS fixed_augmented_laptop_data;

-- Create a table for the raw CSV data
CREATE TABLE raw_laptop_data (
    unnamed INTEGER,
    Brand VARCHAR(255),
    Name VARCHAR(255),
    Price NUMERIC(10,2),
    Processor_Specifications VARCHAR(255),
    Processor_Brand VARCHAR(255),
    RAM_Expandable VARCHAR(50),
    RAM VARCHAR(50),
    RAM_TYPE VARCHAR(50),
    Processor_GHz VARCHAR(50),
    Display_type VARCHAR(50),
    Display VARCHAR(50),
    GPU VARCHAR(255),
    GPU_Brand VARCHAR(255),
    SSD VARCHAR(50),
    HDD VARCHAR(50),
    Adapter VARCHAR(50),
    Battery_Life VARCHAR(50),
    model_name VARCHAR(255),
    screen_size VARCHAR(50),
    ram_duplicate VARCHAR(50),
    os VARCHAR(50),
    customer_review TEXT
);

-- Load raw data
COPY raw_laptop_data FROM 'C:\Studies\Projects\DMQL\Project_continued\fixed_augmented_laptop_data.csv' 
WITH (FORMAT CSV, HEADER true, ENCODING 'UTF8', NULL '');

-- Create the preprocessed table
CREATE TABLE fixed_augmented_laptop_data AS
SELECT 
    Brand,
    Name AS Model_Name,
    NULLIF(Price, 0) * 0.012 AS Price,
    Processor_Specifications,
    Processor_Brand,
    CASE 
        WHEN RAM_Expandable IS NULL OR RAM_Expandable = '' OR RAM_Expandable = 'Not Expandable' THEN 0
        ELSE CAST(NULLIF(REGEXP_REPLACE(RAM_Expandable, '[^0-9]', '', 'g'), '') AS INTEGER)
    END AS "Ram_Expandable (GB)",
    CASE 
        WHEN RAM IS NULL OR RAM = '' THEN 0
        ELSE CAST(NULLIF(REGEXP_REPLACE(RAM, '[^0-9]', '', 'g'), '') AS INTEGER)
    END AS "RAM(in GB)",
    CASE 
        WHEN RAM_TYPE IS NULL OR TRIM(RAM_TYPE) = '' THEN 'DDR4'
        ELSE TRIM(REGEXP_REPLACE(RAM_TYPE, ' RAM', ''))
    END AS RAM_TYPE,
    CASE 
        WHEN Processor_GHz IS NULL OR Processor_GHz = '' OR REGEXP_REPLACE(Processor_GHz, '[^0-9.]', '', 'g') = '' THEN NULL
        ELSE CAST(REGEXP_REPLACE(Processor_GHz, '[^0-9.]', '', 'g') AS FLOAT)
    END AS "Processor(GHz)",
    NULLIF(Display_type, '') AS Display_type,
    NULLIF(GPU, '') AS GPU,
    NULLIF(GPU_Brand, '') AS GPU_Brand,
    CASE 
        WHEN SSD IS NULL OR SSD = '' OR SSD = 'NO SSD' THEN 0
        ELSE CAST(NULLIF(REGEXP_REPLACE(SSD, '[^0-9]', '', 'g'), '') AS FLOAT)
    END AS "SSD Storage (GB)",
    CASE 
        WHEN HDD IS NULL OR HDD = '' OR HDD = 'No HDD' THEN 0
        ELSE CAST(NULLIF(REGEXP_REPLACE(HDD, '[^0-9]', '', 'g'), '') AS FLOAT)
    END AS "HDD Storage (GB)",
    CASE 
        WHEN Adapter IS NULL OR Adapter = '' OR Adapter = 'no' THEN 0
        WHEN REGEXP_REPLACE(Adapter, '[^0-9.]', '', 'g') = '' THEN 0
        ELSE CAST(REGEXP_REPLACE(Adapter, '[^0-9.]', '', 'g') AS FLOAT)
    END AS Adapter_Watt,
    CASE
        WHEN Battery_Life IS NULL OR Battery_Life = '' OR Battery_Life = 'Not Specified' THEN NULL
        WHEN Battery_Life LIKE '%Hrs%' AND REGEXP_REPLACE(Battery_Life, '[^0-9.]', '', 'g') <> ''
        THEN CAST(REGEXP_REPLACE(Battery_Life, '[^0-9.]', '', 'g') AS FLOAT)
        WHEN REGEXP_REPLACE(Battery_Life, '[^0-9.]', '', 'g') <> ''
        THEN CAST(REGEXP_REPLACE(Battery_Life, '[^0-9.]', '', 'g') AS FLOAT) / 60.0
        ELSE NULL
    END AS Battery_Life_Hours,
    CASE 
        WHEN screen_size IS NULL OR screen_size = '' OR screen_size = 'Not Specified' THEN NULL
        ELSE CAST(NULLIF(screen_size, '') AS NUMERIC(4,1))
    END AS screen_size,
    NULLIF(os, '') AS os,
    INITCAP(LOWER(COALESCE(NULLIF(customer_review, ''), 'No review'))) AS customer_review
FROM raw_laptop_data;

-- Drop the raw data table as it's no longer needed
DROP TABLE raw_laptop_data;

-- Now load the processed data into the normalized tables

-- Load Brand data
INSERT INTO Brand (brand_name)
SELECT DISTINCT Brand 
FROM fixed_augmented_laptop_data
WHERE Brand IS NOT NULL
ORDER BY Brand;

-- Load Processor_Brand data
INSERT INTO Processor_Brand (processor_brand_name)
SELECT DISTINCT Processor_Brand 
FROM fixed_augmented_laptop_data
WHERE Processor_Brand IS NOT NULL
ORDER BY Processor_Brand;

-- Load Operating_System data
INSERT INTO Operating_System (os_name)
SELECT DISTINCT os 
FROM fixed_augmented_laptop_data
WHERE os IS NOT NULL
ORDER BY os;

-- Load GPU_Brand data
INSERT INTO GPU_Brand (gpu_brand_name)
SELECT DISTINCT GPU_Brand 
FROM fixed_augmented_laptop_data
WHERE GPU_Brand IS NOT NULL
ORDER BY GPU_Brand;

-- Load RAM data
INSERT INTO RAM (ram_gb, ram_type, ram_expandable_gb)
SELECT DISTINCT 
    "RAM(in GB)",
    COALESCE(NULLIF(TRIM(RAM_TYPE), ''), 'DDR4') as ram_type,
    "Ram_Expandable (GB)"
FROM fixed_augmented_laptop_data
WHERE "RAM(in GB)" IS NOT NULL;

-- Load Storage data
INSERT INTO Storage (ssd_storage_gb, hdd_storage_gb)
SELECT DISTINCT
    "SSD Storage (GB)",
    "HDD Storage (GB)"
FROM fixed_augmented_laptop_data;

-- Load Display data
INSERT INTO Display (display_type, screen_size_inch)
SELECT DISTINCT 
    Display_type,
    screen_size
FROM fixed_augmented_laptop_data
WHERE Display_type IS NOT NULL AND screen_size IS NOT NULL;

-- Load Processor data
INSERT INTO Processor (processor_specifications, processor_brand_id, processor_ghz)
SELECT DISTINCT 
    p.Processor_Specifications,
    pb.processor_brand_id,
    p."Processor(GHz)"
FROM fixed_augmented_laptop_data p
JOIN Processor_Brand pb ON p.Processor_Brand = pb.processor_brand_name
WHERE p.Processor_Specifications IS NOT NULL;

-- Load GPU data
INSERT INTO GPU (gpu_name, gpu_brand_id)
SELECT DISTINCT 
    g.GPU,
    gb.gpu_brand_id
FROM fixed_augmented_laptop_data g
JOIN GPU_Brand gb ON g.GPU_Brand = gb.gpu_brand_name
WHERE g.GPU IS NOT NULL;

-- Load Laptop data
INSERT INTO Laptop (
    brand_id, processor_id, ram_id, gpu_id, storage_id, 
    display_id, os_id, model_name, price, 
    battery_life_hours, adapter_watt
)
SELECT 
    b.brand_id,
    p.processor_id,
    r.ram_id,
    g.gpu_id,
    s.storage_id,
    d.display_id,
    os.os_id,
    l.Model_Name,
    l.Price,
    l.Battery_Life_Hours,
    l.Adapter_Watt
FROM fixed_augmented_laptop_data l
JOIN Brand b ON l.Brand = b.brand_name
JOIN Processor p ON l.Processor_Specifications = p.processor_specifications
JOIN RAM r ON l."RAM(in GB)" = r.ram_gb AND COALESCE(NULLIF(TRIM(l.RAM_TYPE), ''), 'DDR4') = r.ram_type
JOIN GPU g ON l.GPU = g.gpu_name
JOIN Storage s ON l."SSD Storage (GB)" = s.ssd_storage_gb 
    AND l."HDD Storage (GB)" = s.hdd_storage_gb
JOIN Display d ON l.Display_type = d.display_type 
    AND l.screen_size = d.screen_size_inch
JOIN Operating_System os ON l.os = os.os_name;

-- Load Customer_Review data
INSERT INTO Customer_Review (laptop_id, review_text)
SELECT 
    l.laptop_id,
    fd.customer_review
FROM fixed_augmented_laptop_data fd
JOIN Laptop l ON l.model_name = fd.Model_Name
WHERE fd.customer_review IS NOT NULL;

-- Clean up
DROP TABLE fixed_augmented_laptop_data; 