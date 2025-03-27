-- Drop existing function first
DROP FUNCTION IF EXISTS get_popular_laptops(INTEGER);

-- Recreate the function
CREATE OR REPLACE FUNCTION get_popular_laptops(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    laptop_id INTEGER,
    model_name VARCHAR,
    brand_name VARCHAR,
    price NUMERIC,
    review_count BIGINT,
    avg_rating NUMERIC,
    specs_summary TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH laptop_stats AS (
        SELECT DISTINCT ON (l.model_name)  -- Remove duplicates based on model name
            l.laptop_id,
            l.model_name,
            b.brand_name,
            l.price,
            COUNT(cr.review_id) AS review_count,
            COALESCE(AVG(CASE 
                WHEN cr.review_text ILIKE ANY(ARRAY['%excellent%', '%perfect%', '%awesome%', '%amazing%']) THEN 5
                WHEN cr.review_text ILIKE ANY(ARRAY['%great%', '%good%', '%nice%']) THEN 4
                WHEN cr.review_text ILIKE ANY(ARRAY['%okay%', '%ok%', '%decent%']) THEN 3
                WHEN cr.review_text ILIKE ANY(ARRAY['%poor%', '%bad%']) THEN 2
                WHEN cr.review_text ILIKE ANY(ARRAY['%terrible%', '%worst%']) THEN 1
                ELSE 3  -- Default to neutral rating
            END), 3) AS avg_rating,
            CONCAT(
                r.ram_gb::TEXT, 'GB RAM | ',
                CASE 
                    WHEN s.ssd_storage_gb > 0 AND s.hdd_storage_gb > 0 
                        THEN s.ssd_storage_gb::TEXT || 'GB SSD + ' || s.hdd_storage_gb::TEXT || 'GB HDD'
                    WHEN s.ssd_storage_gb > 0 
                        THEN s.ssd_storage_gb::TEXT || 'GB SSD'
                    ELSE s.hdd_storage_gb::TEXT || 'GB HDD'
                END,
                ' | ',
                CASE 
                    WHEN p.processor_specifications ILIKE '%Core%' 
                        THEN SUBSTRING(p.processor_specifications FROM 'Core[^,]+')
                    ELSE p.processor_specifications
                END
            ) AS specs_summary
        FROM Laptop l
        JOIN Brand b ON l.brand_id = b.brand_id
        LEFT JOIN Customer_Review cr ON l.laptop_id = cr.laptop_id
        JOIN RAM r ON l.ram_id = r.ram_id
        JOIN Storage s ON l.storage_id = s.storage_id
        JOIN Processor p ON l.processor_id = p.processor_id
        GROUP BY 
            l.laptop_id, l.model_name, b.brand_name, l.price,
            r.ram_gb, s.ssd_storage_gb, s.hdd_storage_gb, p.processor_specifications
        HAVING COUNT(cr.review_id) >= 5  -- Only include laptops with at least 5 reviews
    )
    SELECT 
        ls.laptop_id,
        ls.model_name,
        ls.brand_name,
        ls.price,
        ls.review_count,
        ls.avg_rating,
        ls.specs_summary
    FROM laptop_stats ls
    ORDER BY ls.review_count DESC, ls.avg_rating DESC, ls.price ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function: Search Laptops
CREATE OR REPLACE FUNCTION search_laptops(
    search_term VARCHAR,
    min_price NUMERIC = 0,
    max_price NUMERIC = 999999,
    p_brand_name VARCHAR = NULL,
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
        AND (p_brand_name IS NULL OR b.brand_name = p_brand_name)
        AND (ram_size IS NULL OR r.ram_gb = ram_size);
END;
$$ LANGUAGE plpgsql;

-- Function: Get Laptop Details
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