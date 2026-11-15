
-- Step 1: Inspect all product category translation mappings

SELECT
    product_category_name,
    product_category_name_english,
    LENGTH(product_category_name) AS source_name_length,
    LENGTH(product_category_name_english) AS english_name_length
FROM public.product_category_name_translation
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 2: Identify whitespace and capitalization inconsistencies

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation
WHERE product_category_name IS DISTINCT FROM LOWER(BTRIM(product_category_name))
   OR product_category_name_english IS DISTINCT FROM LOWER(BTRIM(product_category_name_english))
   OR product_category_name ~ '[[:space:]]{2,}'
   OR product_category_name_english ~ '[[:space:]]{2,}'
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Check duplicate source and English category mappings

SELECT
    product_category_name,
    COUNT(*) AS mapping_count
FROM public.product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1

UNION ALL

SELECT
    product_category_name_english,
    COUNT(*) AS mapping_count
FROM public.product_category_name_translation
GROUP BY product_category_name_english
HAVING COUNT(*) > 1;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Inspect suspected English translation spelling errors

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation
WHERE product_category_name_english IN (
    'costruction_tools_tools',
    'costruction_tools_garden',
    'fashio_female_clothing'
)
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Count products belonging to the three categories with suspected translation errors

SELECT
    p.product_category_name,
    t.product_category_name_english,
    COUNT(*) AS product_count
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IN (
    'construcao_ferramentas_ferramentas',
    'construcao_ferramentas_jardim',
    'fashion_roupa_feminina'
)
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY p.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Inspect additional suspected English translation spelling errors

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation
WHERE product_category_name_english IN (
    'home_confort',
    'arts_and_craftmanship'
)
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Count products belonging to the two additional categories with suspected translation errors

SELECT
    p.product_category_name,
    t.product_category_name_english,
    COUNT(*) AS product_count
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IN (
    'artes_e_artesanato',
    'casa_conforto'
)
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY p.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Verify product categories missing from the translation table

SELECT
    p.product_category_name,
    COUNT(*) AS product_count,
    COUNT(t.product_category_name) AS translation_matches
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IN (
    'portateis_cozinha_e_preparadores_de_alimentos',
    'pc_gamer'
)
GROUP BY p.product_category_name
ORDER BY p.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Identify all product categories without an English translation

SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY p.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Check proposed English translations for existing name conflicts

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation
WHERE product_category_name_english IN (
    'pc_gamer',
    'small_kitchen_appliances_and_food_processors'
)
ORDER BY product_category_name_english;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Investigate categories with numeric suffixes

SELECT
    p.product_category_name,
    t.product_category_name_english,
    COUNT(*) AS product_count
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IN (
    'casa_conforto',
    'casa_conforto_2',
    'eletrodomesticos',
    'eletrodomesticos_2'
)
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY p.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Identify translation categories without matching products

SELECT
    t.product_category_name,
    t.product_category_name_english
FROM public.product_category_name_translation t
LEFT JOIN public.olist_products_dataset p
    ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL
ORDER BY t.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Summarize product category translation coverage

SELECT
    COUNT(DISTINCT p.product_category_name) AS total_product_categories,
    COUNT(DISTINCT t.product_category_name) AS translated_categories,
    COUNT(DISTINCT p.product_category_name)
        FILTER (WHERE t.product_category_name IS NULL) AS untranslated_categories,
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE t.product_category_name IS NOT NULL) AS products_with_translation,
    COUNT(*) FILTER (WHERE t.product_category_name IS NULL) AS products_without_translation
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Distinguish products with NULL categories from products with missing translations

SELECT
    COUNT(*) FILTER (
        WHERE p.product_category_name IS NULL
    ) AS products_with_null_category,

    COUNT(*) FILTER (
        WHERE p.product_category_name IS NOT NULL
          AND t.product_category_name IS NULL
    ) AS products_with_untranslated_category,

    COUNT(DISTINCT p.product_category_name) FILTER (
        WHERE p.product_category_name IS NOT NULL
          AND t.product_category_name IS NULL
    ) AS distinct_untranslated_categories
FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Validate the five English translation corrections

SELECT
    product_category_name,
    product_category_name_english AS current_english_name,
    CASE product_category_name
        WHEN 'construcao_ferramentas_ferramentas'
            THEN 'construction_tools_tools'
        WHEN 'construcao_ferramentas_jardim'
            THEN 'construction_tools_garden'
        WHEN 'fashion_roupa_feminina'
            THEN 'fashion_female_clothing'
        WHEN 'artes_e_artesanato'
            THEN 'arts_and_craftsmanship'
        WHEN 'casa_conforto'
            THEN 'home_comfort'
    END AS proposed_english_name
FROM public.product_category_name_translation
WHERE product_category_name IN (
    'construcao_ferramentas_ferramentas',
    'construcao_ferramentas_jardim',
    'fashion_roupa_feminina',
    'artes_e_artesanato',
    'casa_conforto'
)
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Create the cleaned product category translation view

CREATE OR REPLACE VIEW public.product_category_name_translation_cleaned AS

SELECT
    product_category_name,
    CASE product_category_name
        WHEN 'construcao_ferramentas_ferramentas'
            THEN 'construction_tools_tools'
        WHEN 'construcao_ferramentas_jardim'
            THEN 'construction_tools_garden'
        WHEN 'fashion_roupa_feminina'
            THEN 'fashion_female_clothing'
        WHEN 'artes_e_artesanato'
            THEN 'arts_and_craftsmanship'
        WHEN 'casa_conforto'
            THEN 'home_comfort'
        ELSE product_category_name_english
    END AS product_category_name_english
FROM public.product_category_name_translation

UNION ALL

SELECT
    'pc_gamer' AS product_category_name,
    'pc_gamer' AS product_category_name_english

UNION ALL

SELECT
    'portateis_cozinha_e_preparadores_de_alimentos',
    'small_kitchen_appliances_and_food_processors';

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 17: Validate cleaned translation record count and uniqueness

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_category_name) AS distinct_source_categories,
    COUNT(DISTINCT product_category_name_english) AS distinct_english_categories,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR product_category_name_english IS NULL
    ) AS null_records
FROM public.product_category_name_translation_cleaned;
-- Step 17: Validate cleaned translation record count and uniqueness
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_category_name) AS distinct_source_categories,
    COUNT(DISTINCT product_category_name_english) AS distinct_english_categories,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR product_category_name_english IS NULL
    ) AS null_records
FROM public.product_category_name_translation_cleaned;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 18: Validate corrected English category translations

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation_cleaned
WHERE product_category_name IN (
    'construcao_ferramentas_ferramentas',
    'construcao_ferramentas_jardim',
    'fashion_roupa_feminina',
    'artes_e_artesanato',
    'casa_conforto'
)
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 19: Validate newly added English category translations

SELECT
    product_category_name,
    product_category_name_english
FROM public.product_category_name_translation_cleaned
WHERE product_category_name IN (
    'pc_gamer',
    'portateis_cozinha_e_preparadores_de_alimentos'
)
ORDER BY product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 20: Validate product translation coverage using the cleaned view

SELECT
    COUNT(DISTINCT p.product_category_name) AS total_product_categories,

    COUNT(DISTINCT t.product_category_name) AS translated_categories,

    COUNT(DISTINCT p.product_category_name)
        FILTER (
            WHERE p.product_category_name IS NOT NULL
              AND t.product_category_name IS NULL
        ) AS untranslated_categories,

    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE p.product_category_name IS NOT NULL
          AND t.product_category_name IS NOT NULL
    ) AS products_with_translation,

    COUNT(*) FILTER (
        WHERE p.product_category_name IS NULL
    ) AS products_with_null_category

FROM public.olist_products_dataset p
LEFT JOIN public.product_category_name_translation_cleaned t
    ON p.product_category_name = t.product_category_name;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 21: Compare original and cleaned mappings for unexpected differences

(
    SELECT product_category_name, product_category_name_english
    FROM public.product_category_name_translation

    EXCEPT ALL

    SELECT product_category_name, product_category_name_english
    FROM public.product_category_name_translation_cleaned
)
UNION ALL
(
    SELECT product_category_name, product_category_name_english
    FROM public.product_category_name_translation_cleaned

    EXCEPT ALL

    SELECT product_category_name, product_category_name_english
    FROM public.product_category_name_translation
);

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 22: Validate original and cleaned translation table record counts

SELECT
    (SELECT COUNT(*)
     FROM public.product_category_name_translation) AS source_records,

    (SELECT COUNT(*)
     FROM public.product_category_name_translation_cleaned) AS cleaned_records;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
