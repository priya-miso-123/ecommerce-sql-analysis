
-- Step 1: Profile product records for missing values, blank categories, and invalid numeric values.

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_ids,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category_names,
    COUNT(*) FILTER (WHERE BTRIM(product_category_name) = '') AS blank_category_names,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_name_lengths,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_description_lengths,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_photo_quantities,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weights,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_lengths,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_heights,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_widths,
    COUNT(*) FILTER (
        WHERE product_name_lenght < 0
           OR product_description_lenght < 0
           OR product_photos_qty < 0
           OR product_weight_g < 0
           OR product_length_cm < 0
           OR product_height_cm < 0
           OR product_width_cm < 0
    ) AS records_with_negative_values
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 2: Identify whether missing product attributes occur together in the same records.

SELECT
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND product_name_lenght IS NULL
          AND product_description_lenght IS NULL
          AND product_photos_qty IS NULL
    ) AS all_four_missing,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR product_name_lenght IS NULL
           OR product_description_lenght IS NULL
           OR product_photos_qty IS NULL
    ) AS at_least_one_of_four_missing,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
          AND product_length_cm IS NULL
          AND product_height_cm IS NULL
          AND product_width_cm IS NULL
    ) AS all_four_measurements_missing,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
           OR product_length_cm IS NULL
           OR product_height_cm IS NULL
           OR product_width_cm IS NULL
    ) AS at_least_one_measurement_missing
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Inspect products with all four category-related attributes missing.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset
WHERE product_category_name IS NULL
  AND product_name_lenght IS NULL
  AND product_description_lenght IS NULL
  AND product_photos_qty IS NULL
ORDER BY product_id
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Inspect the two products with missing physical measurement attributes.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL
ORDER BY product_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Determine whether products with missing physical measurements also have missing category-related attributes.

SELECT
    product_id,
    (product_category_name IS NULL) AS category_missing,
    (product_name_lenght IS NULL) AS name_length_missing,
    (product_description_lenght IS NULL) AS description_length_missing,
    (product_photos_qty IS NULL) AS photo_quantity_missing,
    (product_weight_g IS NULL) AS weight_missing,
    (product_length_cm IS NULL) AS length_missing,
    (product_height_cm IS NULL) AS height_missing,
    (product_width_cm IS NULL) AS width_missing
FROM public.olist_products_dataset
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL
ORDER BY product_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Identify duplicate product IDs.

SELECT
    product_id,
    COUNT(*) AS record_count
FROM public.olist_products_dataset
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, product_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Identify exact duplicate product records across all columns.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    COUNT(*) AS duplicate_count
FROM public.olist_products_dataset
GROUP BY
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
HAVING COUNT(*) > 1;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Examine product counts and proportions across product categories.

SELECT
    COALESCE(product_category_name, 'Missing Category') AS product_category,
    COUNT(*) AS product_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_products
FROM public.olist_products_dataset
GROUP BY product_category_name
ORDER BY product_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Identify product categories without a matching translation record.

SELECT
    p.product_category_name,
    COUNT(*) AS affected_products
FROM public.olist_products_dataset AS p
LEFT JOIN public.product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY affected_products DESC, p.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Inspect translation records for the two product categories without matches.

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation
WHERE product_category_name IN (
    'portateis_cozinha_e_preparadores_de_alimentos',
    'pc_gamer'
)
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Identify duplicate category names in the translation reference table.

SELECT
    product_category_name,
    COUNT(*) AS record_count
FROM public.product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1
ORDER BY record_count DESC, product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Check for missing or duplicate English category names in the translation table.

SELECT
    COUNT(*) AS total_translation_records,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS null_portuguese_names,
    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
    ) AS null_english_names,
    COUNT(*) FILTER (
        WHERE BTRIM(product_category_name_english) = ''
    ) AS blank_english_names
FROM public.product_category_name_translation;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Identify English category names associated with multiple Portuguese category names.

SELECT
    product_category_name_english,
    COUNT(DISTINCT product_category_name) AS portuguese_category_count,
    STRING_AGG(product_category_name, ', ' ORDER BY product_category_name)
        AS portuguese_categories
FROM public.product_category_name_translation
GROUP BY product_category_name_english
HAVING COUNT(DISTINCT product_category_name) > 1
ORDER BY portuguese_category_count DESC, product_category_name_english;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Examine the distributions and ranges of product name and description lengths.

SELECT
    'product_name_lenght' AS attribute,
    COUNT(*) AS non_null_records,
    MIN(product_name_lenght) AS minimum_value,
    MAX(product_name_lenght) AS maximum_value,
    ROUND(AVG(product_name_lenght)::numeric, 2) AS average_value,
    COUNT(*) FILTER (WHERE product_name_lenght = 0) AS zero_values
FROM public.olist_products_dataset

UNION ALL

SELECT
    'product_description_lenght',
    COUNT(*),
    MIN(product_description_lenght),
    MAX(product_description_lenght),
    ROUND(AVG(product_description_lenght)::numeric, 2),
    COUNT(*) FILTER (WHERE product_description_lenght = 0)
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Inspect the 20 products with the longest recorded descriptions.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    LEFT(product_category_name, 40) AS category_sample
FROM public.olist_products_dataset
WHERE product_description_lenght IS NOT NULL
ORDER BY product_description_lenght DESC
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Examine the distribution and range of product photo quantities.

SELECT
    COUNT(product_photos_qty) AS non_null_records,
    MIN(product_photos_qty) AS minimum_photos,
    MAX(product_photos_qty) AS maximum_photos,
    ROUND(AVG(product_photos_qty)::numeric, 2) AS average_photos,
    COUNT(*) FILTER (WHERE product_photos_qty = 0) AS zero_photo_products,
    COUNT(*) FILTER (WHERE product_photos_qty = 1) AS one_photo_products,
    COUNT(*) FILTER (WHERE product_photos_qty > 10) AS products_with_over_10_photos
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 17: Inspect products with the highest recorded photo quantities.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty
FROM public.olist_products_dataset
WHERE product_photos_qty IS NOT NULL
ORDER BY product_photos_qty DESC, product_id
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 18: Examine the distribution and range of product weights.

SELECT
    COUNT(product_weight_g) AS non_null_records,
    MIN(product_weight_g) AS minimum_weight_g,
    MAX(product_weight_g) AS maximum_weight_g,
    ROUND(AVG(product_weight_g)::numeric, 2) AS average_weight_g,
    COUNT(*) FILTER (WHERE product_weight_g = 0) AS zero_weight_products,
    COUNT(*) FILTER (WHERE product_weight_g < 100) AS products_below_100g,
    COUNT(*) FILTER (WHERE product_weight_g >= 10000) AS products_at_least_10000g
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 19: Inspect product records with zero recorded weight.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset
WHERE product_weight_g = 0
ORDER BY product_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 20: Inspect the 20 products with the lowest positive recorded weights.

SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset
WHERE product_weight_g > 0
ORDER BY product_weight_g, product_id
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 21: Examine product metadata for the five products with a recorded weight of 2 g.

SELECT
    p.product_id,
    p.product_category_name,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM public.olist_products_dataset AS p
WHERE p.product_weight_g = 2
ORDER BY p.product_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 22: Identify repeated combinations of product weight and physical dimensions.

SELECT
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    COUNT(*) AS product_count,
    COUNT(DISTINCT product_category_name) AS category_count
FROM public.olist_products_dataset
WHERE product_weight_g IS NOT NULL
  AND product_length_cm IS NOT NULL
  AND product_height_cm IS NOT NULL
  AND product_width_cm IS NOT NULL
GROUP BY
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
HAVING COUNT(*) > 1
ORDER BY product_count DESC, product_weight_g
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 23: Examine the distribution and ranges of product dimensions.

SELECT
    'length' AS dimension,
    COUNT(product_length_cm) AS non_null_records,
    MIN(product_length_cm) AS minimum_cm,
    MAX(product_length_cm) AS maximum_cm,
    ROUND(AVG(product_length_cm)::numeric, 2) AS average_cm,
    COUNT(*) FILTER (WHERE product_length_cm = 0) AS zero_values,
    COUNT(*) FILTER (WHERE product_length_cm >= 100) AS values_at_least_100_cm
FROM public.olist_products_dataset

UNION ALL

SELECT
    'height',
    COUNT(product_height_cm),
    MIN(product_height_cm),
    MAX(product_height_cm),
    ROUND(AVG(product_height_cm)::numeric, 2),
    COUNT(*) FILTER (WHERE product_height_cm = 0),
    COUNT(*) FILTER (WHERE product_height_cm >= 100)
FROM public.olist_products_dataset

UNION ALL

SELECT
    'width',
    COUNT(product_width_cm),
    MIN(product_width_cm),
    MAX(product_width_cm),
    ROUND(AVG(product_width_cm)::numeric, 2),
    COUNT(*) FILTER (WHERE product_width_cm = 0),
    COUNT(*) FILTER (WHERE product_width_cm >= 100)
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 24: Inspect products with at least one physical dimension of 100 cm or more.

SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset
WHERE product_length_cm >= 100
   OR product_height_cm >= 100
   OR product_width_cm >= 100
ORDER BY
    GREATEST(product_length_cm, product_height_cm, product_width_cm) DESC,
    product_id
LIMIT 25;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 25: Calculate recorded product volumes and inspect their distribution.

SELECT
    COUNT(*) AS products_with_complete_dimensions,
    MIN(product_length_cm * product_height_cm * product_width_cm) AS minimum_volume_cm3,
    MAX(product_length_cm * product_height_cm * product_width_cm) AS maximum_volume_cm3,
    ROUND(
        AVG((product_length_cm * product_height_cm * product_width_cm)::numeric),
        2
    ) AS average_volume_cm3,
    COUNT(*) FILTER (
        WHERE product_length_cm * product_height_cm * product_width_cm < 100
    ) AS products_below_100_cm3,
    COUNT(*) FILTER (
        WHERE product_length_cm * product_height_cm * product_width_cm >= 100000
    ) AS products_at_least_100000_cm3
FROM public.olist_products_dataset
WHERE product_length_cm IS NOT NULL
  AND product_height_cm IS NOT NULL
  AND product_width_cm IS NOT NULL;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 26: Inspect the 20 products with the largest calculated physical volumes.

SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_length_cm * product_height_cm * product_width_cm
        AS calculated_volume_cm3
FROM public.olist_products_dataset
WHERE product_length_cm IS NOT NULL
  AND product_height_cm IS NOT NULL
  AND product_width_cm IS NOT NULL
ORDER BY calculated_volume_cm3 DESC, product_id
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 27: Identify products with large calculated volumes but unusually low recorded weights.

SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_length_cm * product_height_cm * product_width_cm
        AS calculated_volume_cm3,
    ROUND(
        (
            product_weight_g::numeric /
            NULLIF(
                (product_length_cm * product_height_cm * product_width_cm)::numeric,
                0
            )
        ),
        5
    ) AS weight_per_cm3
FROM public.olist_products_dataset
WHERE product_weight_g > 0
  AND product_length_cm IS NOT NULL
  AND product_height_cm IS NOT NULL
  AND product_width_cm IS NOT NULL
  AND product_length_cm * product_height_cm * product_width_cm >= 10000
ORDER BY weight_per_cm3, product_id
LIMIT 20;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 28: Review metadata for the 20 products with the lowest weight-to-volume ratios.

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset
WHERE product_id IN (
    '0d94e21c8156ffa3dcb77cb1d456ef80',
    '5adec774989986e22714470345c20469',
    '61d980017b9f55ac2451dbf0bdb849f2',
    'cdad30e46a6fc84785a525ad6b5cf748',
    '984a3b9f9bb4c8feb319da951212696e',
    'c2a241928535e097a96aa157dfaa86b5',
    '632921e8d6c6b23ae47ff20950a56854',
    '2cfec57b3d2ea171bceca7aef38d044a',
    'b8fd372c103037c02e9898f76ba0ab4c',
    '437ae72c066abf24996b52549bbb6432',
    '8daf2f80c6d552efdb1012683beb10cf',
    '3ada827a3b82590816ffa9741fa4bd03',
    'f128effc5b8e4d1f23069c06f855643a',
    'ad53b74739180a632354ce9cb16bbdde',
    'f1aa9d01a0ddad2937f722cb61abc03f',
    '15151e8a937f6a4d1a4f0c03c765c6f2',
    '4941b2c06706332ebfd9072d7b1fb23c',
    '0d146484c69d613fe015c0229056b065',
    '5aad359a63cbb4fc35ead44346a3eeb4',
    'af35be35db4ad0dc288b571453337376'
)
ORDER BY product_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 29: Compare missing-value patterns across product weight and dimension fields.

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weight,
    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS missing_length,
    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS missing_height,
    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS missing_width,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
          AND product_length_cm IS NULL
          AND product_height_cm IS NULL
          AND product_width_cm IS NULL
    ) AS all_four_missing,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NOT NULL
          AND product_length_cm IS NOT NULL
          AND product_height_cm IS NOT NULL
          AND product_width_cm IS NOT NULL
    ) AS all_four_populated
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 30: Validate that product weights and dimensions contain no negative values.

SELECT
    COUNT(*) FILTER (WHERE product_weight_g < 0) AS negative_weights,
    COUNT(*) FILTER (WHERE product_length_cm < 0) AS negative_lengths,
    COUNT(*) FILTER (WHERE product_height_cm < 0) AS negative_heights,
    COUNT(*) FILTER (WHERE product_width_cm < 0) AS negative_widths
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 31: Create a cleaned products view while preserving all source records and values.

CREATE OR REPLACE VIEW public.olist_products_cleaned AS
SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM public.olist_products_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 32: Compare the source and cleaned-view record counts.

SELECT
    (SELECT COUNT(*) FROM public.olist_products_dataset) AS source_records,
    (SELECT COUNT(*) FROM public.olist_products_cleaned) AS cleaned_records;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 33: Compare source and cleaned-view records in both directions.

(
    SELECT * FROM public.olist_products_dataset
    EXCEPT ALL
    SELECT * FROM public.olist_products_cleaned
)
UNION ALL
(
    SELECT * FROM public.olist_products_cleaned
    EXCEPT ALL
    SELECT * FROM public.olist_products_dataset
);

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
