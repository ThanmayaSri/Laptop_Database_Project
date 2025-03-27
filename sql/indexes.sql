-- Drop existing indexes
DROP INDEX IF EXISTS idx_brand_name;

-- Processor indexes
DROP INDEX IF EXISTS idx_processor_brand;
DROP INDEX IF EXISTS idx_processor_specs;
DROP INDEX IF EXISTS idx_processor_ghz;

-- RAM indexes
DROP INDEX IF EXISTS idx_ram_size;
DROP INDEX IF EXISTS idx_ram_type;
DROP INDEX IF EXISTS idx_ram_expandable;

-- GPU indexes
DROP INDEX IF EXISTS idx_gpu_brand;
DROP INDEX IF EXISTS idx_gpu_name;
DROP INDEX IF EXISTS idx_gpu_vram;

-- Storage indexes
DROP INDEX IF EXISTS idx_storage_ssd;
DROP INDEX IF EXISTS idx_storage_hdd;
DROP INDEX IF EXISTS idx_storage_combined;

-- Display indexes
DROP INDEX IF EXISTS idx_display_size;
DROP INDEX IF EXISTS idx_display_type;

-- Operating System indexes
DROP INDEX IF EXISTS idx_os_name;

-- Laptop indexes
DROP INDEX IF EXISTS idx_laptop_price;
DROP INDEX IF EXISTS idx_laptop_brand;
DROP INDEX IF EXISTS idx_laptop_model;
DROP INDEX IF EXISTS idx_laptop_battery;
DROP INDEX IF EXISTS idx_laptop_components;

-- Customer Review indexes
DROP INDEX IF EXISTS idx_review_laptop;
DROP INDEX IF EXISTS idx_review_text;

-- Create new indexes
-- Brand indexes
CREATE INDEX idx_brand_name ON Brand(brand_name);

-- Processor indexes
CREATE INDEX idx_processor_brand ON Processor(processor_brand_id);
CREATE INDEX idx_processor_specs ON Processor(processor_specifications);
CREATE INDEX idx_processor_ghz ON Processor(processor_ghz);

-- RAM indexes
CREATE INDEX idx_ram_size ON RAM(ram_gb);
CREATE INDEX idx_ram_type ON RAM(ram_type);
CREATE INDEX idx_ram_expandable ON RAM(ram_expandable_gb);

-- GPU indexes
CREATE INDEX idx_gpu_brand ON GPU(gpu_brand_id);
CREATE INDEX idx_gpu_name ON GPU(gpu_name);
CREATE INDEX idx_gpu_vram ON GPU(vram_gb);

-- Storage indexes
CREATE INDEX idx_storage_ssd ON Storage(ssd_storage_gb);
CREATE INDEX idx_storage_hdd ON Storage(hdd_storage_gb);
CREATE INDEX idx_storage_combined ON Storage(ssd_storage_gb, hdd_storage_gb);

-- Display indexes
CREATE INDEX idx_display_size ON Display(screen_size_inch);
CREATE INDEX idx_display_type ON Display(display_type);

-- Operating System indexes
CREATE INDEX idx_os_name ON Operating_System(os_name);

-- Laptop indexes
CREATE INDEX idx_laptop_price ON Laptop(price);
CREATE INDEX idx_laptop_brand ON Laptop(brand_id);
CREATE INDEX idx_laptop_model ON Laptop(model_name);
CREATE INDEX idx_laptop_battery ON Laptop(battery_life_hours);
CREATE INDEX idx_laptop_components ON Laptop(processor_id, ram_id, gpu_id);

-- Customer Review indexes
CREATE INDEX idx_review_laptop ON Customer_Review(laptop_id);
CREATE INDEX idx_review_text ON Customer_Review(laptop_id, review_text);