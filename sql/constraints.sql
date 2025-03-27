-- Add constraints to existing tables

-- Brand constraints
ALTER TABLE Brand
ADD CONSTRAINT unique_brand_name UNIQUE (brand_name);

-- Processor constraints
ALTER TABLE Processor
ADD CONSTRAINT chk_processor_ghz CHECK (processor_ghz >= 0);

-- RAM constraints
ALTER TABLE RAM
ADD CONSTRAINT chk_ram_type CHECK (TRIM(ram_type) IN (
    'DDR2', 'DDR3', 'DDR4', 'DDR5', 
    'LPDDR4', 'LPDDR4X', 'LPDDR5', 'LPDDR5X',
    'DDR4X', 'DDR5X', 'LPDDR3'
));

-- GPU constraints
ALTER TABLE GPU
ADD CONSTRAINT chk_vram CHECK (vram_gb >= 0);

-- Storage constraints
ALTER TABLE Storage
ADD CONSTRAINT chk_total_storage CHECK (ssd_storage_gb + hdd_storage_gb > 0);

-- Display constraints
ALTER TABLE Display
ADD CONSTRAINT chk_display_type CHECK (display_type IN ('LCD', 'LED', 'OLED', 'IPS'));

-- Laptop constraints
ALTER TABLE Laptop
ADD CONSTRAINT chk_battery_life CHECK (battery_life_hours > 0),
ADD CONSTRAINT chk_adapter CHECK (adapter_watt >= 0); 