-- Triggers and Functions for Website Operations

-- 1. Audit Trail Trigger
-- Track all changes to the Laptop table
CREATE TABLE IF NOT EXISTS laptop_audit_log (
    audit_id SERIAL PRIMARY KEY,
    action_type VARCHAR(10),
    laptop_id INTEGER,
    model_name VARCHAR(255),
    old_price NUMERIC(10,2),
    new_price NUMERIC(10,2),
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_laptop_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO laptop_audit_log (action_type, laptop_id, model_name, new_price, changed_by)
        VALUES ('INSERT', NEW.laptop_id, NEW.model_name, NEW.price, current_user);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO laptop_audit_log (action_type, laptop_id, model_name, old_price, new_price, changed_by)
        VALUES ('UPDATE', NEW.laptop_id, NEW.model_name, OLD.price, NEW.price, current_user);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO laptop_audit_log (action_type, laptop_id, model_name, old_price, changed_by)
        VALUES ('DELETE', OLD.laptop_id, OLD.model_name, OLD.price, current_user);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER laptop_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON Laptop
FOR EACH ROW EXECUTE FUNCTION audit_laptop_changes();

-- 2. Price History Tracking
CREATE TABLE IF NOT EXISTS price_history (
    history_id SERIAL PRIMARY KEY,
    laptop_id INTEGER REFERENCES Laptop(laptop_id),
    old_price NUMERIC(10,2),
    new_price NUMERIC(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION track_price_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.price != NEW.price THEN
        INSERT INTO price_history (laptop_id, old_price, new_price)
        VALUES (NEW.laptop_id, OLD.price, NEW.price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER price_history_trigger
AFTER UPDATE ON Laptop
FOR EACH ROW
WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION track_price_changes();

-- 3. Stored Procedure: Search Laptops
CREATE OR REPLACE FUNCTION search_laptops(
    search_term VARCHAR,
    min_price NUMERIC = 0,
    max_price NUMERIC = 999999,
    brand_name VARCHAR = NULL,
    ram_size INTEGER = NULL
)
RETURNS TABLE (
    laptop_id INTEGER,
    model_name VARCHAR,
    brand_name VARCHAR,
    price NUMERIC,
    ram_gb INTEGER,
    processor_specs VARCHAR,
    gpu_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.laptop_id,
        l.model_name,
        b.brand_name,
        l.price,
        r.ram_gb,
        p.processor_specifications,
        g.gpu_name
    FROM Laptop l
    JOIN Brand b ON l.brand_id = b.brand_id
    JOIN RAM r ON l.ram_id = r.ram_id
    JOIN Processor p ON l.processor_id = p.processor_id
    JOIN GPU g ON l.gpu_id = g.gpu_id
    WHERE 
        (l.model_name ILIKE '%' || search_term || '%' OR
         b.brand_name ILIKE '%' || search_term || '%' OR
         p.processor_specifications ILIKE '%' || search_term || '%')
        AND l.price BETWEEN min_price AND max_price
        AND (brand_name IS NULL OR b.brand_name = brand_name)
        AND (ram_size IS NULL OR r.ram_gb = ram_size);
END;
$$ LANGUAGE plpgsql;

-- 4. Stored Procedure: Get Laptop Details
CREATE OR REPLACE FUNCTION get_laptop_details(p_laptop_id INTEGER)
RETURNS TABLE (
    laptop_id INTEGER,
    model_name VARCHAR,
    brand_name VARCHAR,
    price NUMERIC,
    ram_gb INTEGER,
    ram_type VARCHAR,
    processor_specs VARCHAR,
    processor_brand VARCHAR,
    gpu_name VARCHAR,
    gpu_brand VARCHAR,
    storage_ssd INTEGER,
    storage_hdd INTEGER,
    display_type VARCHAR,
    screen_size NUMERIC,
    os_name VARCHAR,
    battery_life NUMERIC,
    adapter_watt INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.laptop_id,
        l.model_name,
        b.brand_name,
        l.price,
        r.ram_gb,
        r.ram_type,
        p.processor_specifications,
        pb.processor_brand_name,
        g.gpu_name,
        gb.gpu_brand_name,
        s.ssd_storage_gb,
        s.hdd_storage_gb,
        d.display_type,
        d.screen_size_inch,
        os.os_name,
        l.battery_life_hours,
        l.adapter_watt
    FROM Laptop l
    JOIN Brand b ON l.brand_id = b.brand_id
    JOIN RAM r ON l.ram_id = r.ram_id
    JOIN Processor p ON l.processor_id = p.processor_id
    JOIN Processor_Brand pb ON p.processor_brand_id = pb.processor_brand_id
    JOIN GPU g ON l.gpu_id = g.gpu_id
    JOIN GPU_Brand gb ON g.gpu_brand_id = gb.gpu_brand_id
    JOIN Storage s ON l.storage_id = s.storage_id
    JOIN Display d ON l.display_id = d.display_id
    JOIN Operating_System os ON l.os_id = os.os_id
    WHERE l.laptop_id = p_laptop_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Function: Get Popular Laptops
CREATE OR REPLACE FUNCTION get_popular_laptops(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    laptop_id INTEGER,
    model_name VARCHAR,
    brand_name VARCHAR,
    price NUMERIC,
    review_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.laptop_id,
        l.model_name,
        b.brand_name,
        l.price,
        COUNT(cr.review_id) as review_count
    FROM Laptop l
    JOIN Brand b ON l.brand_id = b.brand_id
    LEFT JOIN Customer_Review cr ON l.laptop_id = cr.laptop_id
    GROUP BY l.laptop_id, l.model_name, b.brand_name, l.price
    ORDER BY review_count DESC, l.price
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 6. Function: Get Price Statistics
CREATE OR REPLACE FUNCTION get_price_statistics(brand_name VARCHAR = NULL)
RETURNS TABLE (
    avg_price NUMERIC,
    min_price NUMERIC,
    max_price NUMERIC,
    price_range_count JSON
) AS $$
BEGIN
    RETURN QUERY
    WITH price_ranges AS (
        SELECT 
            CASE 
                WHEN price < 500 THEN 'Under $500'
                WHEN price < 1000 THEN '$500-$999'
                WHEN price < 1500 THEN '$1000-$1499'
                ELSE '$1500+'
            END as range,
            COUNT(*) as count
        FROM Laptop l
        JOIN Brand b ON l.brand_id = b.brand_id
        WHERE brand_name IS NULL OR b.brand_name = brand_name
        GROUP BY range
    )
    SELECT 
        ROUND(AVG(l.price)::numeric, 2),
        MIN(l.price),
        MAX(l.price),
        json_object_agg(pr.range, pr.count)
    FROM Laptop l
    JOIN Brand b ON l.brand_id = b.brand_id
    CROSS JOIN price_ranges pr
    WHERE brand_name IS NULL OR b.brand_name = brand_name
    GROUP BY pr.range, pr.count;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger: Validate Price Updates
CREATE OR REPLACE FUNCTION validate_price_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Don't allow price to be reduced by more than 50%
    IF NEW.price < (OLD.price * 0.5) THEN
        RAISE EXCEPTION 'Price cannot be reduced by more than 50%';
    END IF;
    
    -- Don't allow price to increase by more than 100%
    IF NEW.price > (OLD.price * 2) THEN
        RAISE EXCEPTION 'Price cannot be increased by more than 100%';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER price_validation_trigger
BEFORE UPDATE OF price ON Laptop
FOR EACH ROW
EXECUTE FUNCTION validate_price_update();

-- 8. Function: Get Related Laptops
CREATE OR REPLACE FUNCTION get_related_laptops(
    p_laptop_id INTEGER,
    limit_count INTEGER DEFAULT 5
)
RETURNS TABLE (
    laptop_id INTEGER,
    model_name VARCHAR,
    brand_name VARCHAR,
    price NUMERIC,
    similarity_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH laptop_specs AS (
        SELECT 
            l.laptop_id,
            l.model_name,
            b.brand_name,
            l.price,
            r.ram_gb,
            p.processor_specifications,
            g.gpu_name
        FROM Laptop l
        JOIN Brand b ON l.brand_id = b.brand_id
        JOIN RAM r ON l.ram_id = r.ram_id
        JOIN Processor p ON l.processor_id = p.processor_id
        JOIN GPU g ON l.gpu_id = g.gpu_id
    ),
    target_specs AS (
        SELECT * FROM laptop_specs WHERE laptop_id = p_laptop_id
    )
    SELECT 
        ls.laptop_id,
        ls.model_name,
        ls.brand_name,
        ls.price,
        (CASE WHEN ls.ram_gb = ts.ram_gb THEN 1 ELSE 0 END +
         CASE WHEN ls.processor_specifications = ts.processor_specifications THEN 1 ELSE 0 END +
         CASE WHEN ls.gpu_name = ts.gpu_name THEN 1 ELSE 0 END)::INTEGER as similarity_score
    FROM laptop_specs ls
    CROSS JOIN target_specs ts
    WHERE ls.laptop_id != p_laptop_id
    ORDER BY similarity_score DESC, ABS(ls.price - ts.price)
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql; 