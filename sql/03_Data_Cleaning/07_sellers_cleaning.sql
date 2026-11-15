
-- Step 1: Profile seller records and identify missing or blank values.

SELECT
    COUNT(*) AS total_records,
    COUNT(seller_id) AS non_null_seller_ids,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_ids,
    COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS missing_zip_codes,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS missing_cities,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS missing_states,
    COUNT(*) FILTER (WHERE BTRIM(seller_city) = '') AS blank_cities,
    COUNT(*) FILTER (WHERE BTRIM(seller_state) = '') AS blank_states
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 2: Identify seller IDs appearing more than once.

SELECT
    seller_id,
    COUNT(*) AS record_count
FROM public.olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 3: Identify exact duplicate seller records across all columns.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    COUNT(*) AS duplicate_count
FROM public.olist_sellers_dataset
GROUP BY
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 4: Validate seller ZIP code prefix lengths and numeric formatting.

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix::text ~ '^[0-9]{5}$'
    ) AS valid_five_digit_prefixes,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix::text !~ '^[0-9]{5}$'
    ) AS invalid_prefix_formats,
    MIN(LENGTH(seller_zip_code_prefix::text)) AS minimum_prefix_length,
    MAX(LENGTH(seller_zip_code_prefix::text)) AS maximum_prefix_length
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 5: Examine four-digit seller ZIP prefixes and their frequencies.

SELECT
    seller_zip_code_prefix,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
WHERE LENGTH(seller_zip_code_prefix::text) = 4
GROUP BY seller_zip_code_prefix
ORDER BY seller_zip_code_prefix
LIMIT 30;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 6: Compare four-digit and five-digit seller ZIP prefixes by state.

SELECT
    seller_state,
    COUNT(*) AS total_sellers,
    COUNT(*) FILTER (
        WHERE LENGTH(seller_zip_code_prefix::text) = 4
    ) AS four_digit_prefixes,
    COUNT(*) FILTER (
        WHERE LENGTH(seller_zip_code_prefix::text) = 5
    ) AS five_digit_prefixes
FROM public.olist_sellers_dataset
GROUP BY seller_state
ORDER BY four_digit_prefixes DESC, seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 7: Verify that padding every four-digit seller ZIP prefix produces a five-digit numeric prefix.

SELECT
    COUNT(*) AS affected_records,
    COUNT(DISTINCT seller_zip_code_prefix) AS distinct_four_digit_prefixes,
    COUNT(*) FILTER (
        WHERE LPAD(seller_zip_code_prefix::text, 5, '0') ~ '^[0-9]{5}$'
    ) AS valid_after_padding,
    MIN(LPAD(seller_zip_code_prefix::text, 5, '0')) AS smallest_padded_prefix,
    MAX(LPAD(seller_zip_code_prefix::text, 5, '0')) AS largest_padded_prefix
FROM public.olist_sellers_dataset
WHERE LENGTH(seller_zip_code_prefix::text) = 4;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 8: Identify seller ZIP prefixes associated with multiple cities.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    COUNT(DISTINCT seller_city) AS distinct_cities,
    STRING_AGG(DISTINCT seller_city, ', ' ORDER BY seller_city) AS cities,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY LPAD(seller_zip_code_prefix::text, 5, '0')
HAVING COUNT(DISTINCT seller_city) > 1
ORDER BY distinct_cities DESC, seller_count DESC
LIMIT 30;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 9: Identify seller city values with suspicious numeric, email, or special-character patterns.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE
    seller_city ~ '[0-9]'
    OR seller_city ~ '@'
    OR seller_city ~ '[^a-zA-ZÀ-ÿ /''-]'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 10: Inspect sellers sharing the ZIP prefix associated with the numeric city value.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_zip_code_prefix = 22790
ORDER BY seller_city, seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 11: Inspect sellers sharing the ZIP prefix associated with the email-like city value.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_zip_code_prefix = 87025
ORDER BY seller_city, seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 12: Inspect sellers with extended city descriptions and their matching ZIP-prefix records.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city IN (
    'novo hamburgo, rio grande do sul, brasil',
    'rio de janeiro, rio de janeiro, brasil'
)
OR seller_zip_code_prefix IN (93310, 22793)
ORDER BY seller_zip_code_prefix, seller_city, seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 13: Inspect sellers with backslashes, spelling variations, and extended city labels.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_zip_code_prefix IN (
    22050, 13450, 4557, 87525, 87083, 88330,
    09230, 14085, 85802, 13720, 09190, 89900,
    05141, 07077, 09380, 09721, 14078, 14079,
    15350, 25900, 28035, 37165
)
ORDER BY seller_zip_code_prefix, seller_city, seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 14: Identify seller city names associated with multiple states.

SELECT
    seller_city,
    COUNT(DISTINCT seller_state) AS distinct_states,
    STRING_AGG(DISTINCT seller_state, ', ' ORDER BY seller_state) AS states,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY seller_city
HAVING COUNT(DISTINCT seller_state) > 1
ORDER BY distinct_states DESC, seller_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 15: Inspect ZIP prefixes and seller counts for city names associated with multiple states.

SELECT
    seller_city,
    seller_state,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
WHERE seller_city IN (
    'rio de janeiro',
    'marechal candido rondon',
    'curitiba',
    'belo horizonte',
    'porto alegre',
    'londrina',
    'blumenau',
    'florianopolis',
    'caxias do sul',
    'itajai',
    'juiz de fora',
    'sao jose dos pinhais',
    'palhoca',
    'pinhais',
    'vila velha',
    'chapeco',
    'jacutinga',
    'volta redonda',
    'guaira',
    'ipira',
    'pinhalzinho',
    'rio bonito',
    'andradas'
)
GROUP BY
    seller_city,
    seller_state,
    LPAD(seller_zip_code_prefix::text, 5, '0')
ORDER BY
    seller_city,
    seller_state,
    seller_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 16: Identify seller ZIP prefixes associated with multiple states.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    COUNT(DISTINCT seller_state) AS distinct_states,
    STRING_AGG(DISTINCT seller_state, ', ' ORDER BY seller_state) AS states,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY LPAD(seller_zip_code_prefix::text, 5, '0')
HAVING COUNT(DISTINCT seller_state) > 1
ORDER BY distinct_states DESC, seller_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 17: Inspect individual seller records with ZIP prefixes associated with multiple states.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE LPAD(seller_zip_code_prefix::text, 5, '0') IN (
    '85960', '37540', '88301', '80240', '36010',
    '81020', '81560', '83020', '83321', '88075',
    '89052', '21210', '95076', '22783', '31160',
    '37795', '44600'
)
ORDER BY normalized_zip_prefix, seller_state, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 18: Summarize seller ZIP prefix and state combinations.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_state,
    COUNT(*) AS seller_count,
    STRING_AGG(DISTINCT seller_city, ', ' ORDER BY seller_city) AS cities
FROM public.olist_sellers_dataset
GROUP BY
    LPAD(seller_zip_code_prefix::text, 5, '0'),
    seller_state
ORDER BY
    normalized_zip_prefix,
    seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 19: Identify seller city and state values containing leading or trailing whitespace.

SELECT
    seller_id,
    seller_city,
    seller_state,
    LENGTH(seller_city) AS city_length,
    LENGTH(BTRIM(seller_city)) AS trimmed_city_length,
    LENGTH(seller_state) AS state_length,
    LENGTH(BTRIM(seller_state)) AS trimmed_state_length
FROM public.olist_sellers_dataset
WHERE seller_city <> BTRIM(seller_city)
   OR seller_state <> BTRIM(seller_state)
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 20: Validate the format and distribution of seller state codes.

SELECT
    seller_state,
    LENGTH(seller_state) AS state_code_length,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY seller_state
ORDER BY seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 21: Validate the numeric format and length of seller ZIP prefixes.

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix::text ~ '^[0-9]+$'
    ) AS numeric_zip_prefixes,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix::text !~ '^[0-9]+$'
    ) AS non_numeric_zip_prefixes,
    COUNT(*) FILTER (
        WHERE LENGTH(seller_zip_code_prefix::text) NOT IN (4, 5)
    ) AS unexpected_length_prefixes,
    MIN(LENGTH(seller_zip_code_prefix::text)) AS minimum_length,
    MAX(LENGTH(seller_zip_code_prefix::text)) AS maximum_length
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 22: Identify seller city values containing likely state-code suffixes.

SELECT
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
WHERE seller_city ~* '(^|[ /,-])(sp|mg|pr|sc|rs|rj|ba|go|es|df|pe|ce|mt|ms|pa|pb|rn|ro|se|al|to|ma|pi|ac|am|ap|rr)([[:space:]]|$)'
GROUP BY
    seller_zip_code_prefix,
    seller_city,
    seller_state
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 23: Inspect sellers sharing ZIP prefixes with state-only or potentially mismatched city values.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE LPAD(seller_zip_code_prefix::text, 5, '0') IN (
    '71900', '04776', '05141', '12903', '16021',
    '03363', '71906'
)
ORDER BY normalized_zip_prefix, seller_state, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 24: Check seller city values that are not stored in lowercase.

SELECT
    seller_city,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
WHERE seller_city <> LOWER(seller_city)
GROUP BY seller_city
ORDER BY seller_count DESC, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 25: Identify seller city values containing non-standard characters.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city !~ '^[a-z0-9[:space:]''.,()/&-]+$'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 26: Test PostgreSQL Unicode normalization support.

SELECT
    VERSION() AS postgresql_version,
    NORMALIZE('são paulo', NFC) AS normalized_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 27: Identify seller city values affected by NFC Unicode normalization.

SELECT
    seller_id,
    seller_city AS original_city,
    NORMALIZE(seller_city, NFC) AS normalized_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city <> NORMALIZE(seller_city, NFC)
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 28: Identify seller city values that contain email addresses or consist only of digits.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    CASE
        WHEN seller_city ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
            THEN 'Email address'
        WHEN seller_city ~ '^[0-9]+$'
            THEN 'Numeric-only value'
    END AS issue_type
FROM public.olist_sellers_dataset
WHERE seller_city ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
   OR seller_city ~ '^[0-9]+$'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 29: Identify seller city values containing commas, slashes, or backslashes.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city LIKE '%,%'
   OR seller_city LIKE '%/%'
   OR seller_city LIKE '%\%'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 30: Inspect seller city values containing parentheses.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city LIKE '%(%'
   OR seller_city LIKE '%)%'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 31: Identify unusually short seller city values.

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    LENGTH(seller_city) AS city_length,
    seller_state
FROM public.olist_sellers_dataset
WHERE LENGTH(BTRIM(seller_city)) <= 3
ORDER BY city_length, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 32: Find ZIP/state groups containing multiple distinct seller city values.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_state,
    COUNT(DISTINCT seller_city) AS distinct_city_values,
    COUNT(*) AS seller_count,
    STRING_AGG(DISTINCT seller_city, ' | ' ORDER BY seller_city) AS city_values
FROM public.olist_sellers_dataset
GROUP BY
    LPAD(seller_zip_code_prefix::text, 5, '0'),
    seller_state
HAVING COUNT(DISTINCT seller_city) > 1
ORDER BY distinct_city_values DESC, seller_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 33: Inspect selected seller city spelling variations and their ZIP/state context.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city IN (
    'portoferreira',
    'porto ferreira',
    'mogi das cruses',
    'mogi das cruzes',
    'belo horizont',
    'belo horizonte',
    'floranopolis',
    'florianopolis',
    'santa barbara d oeste',
    'santa barbara d''oeste',
    'sao miguel d''oeste',
    'sao miguel do oeste'
)
ORDER BY normalized_zip_prefix, seller_state, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 34: Summarize the number of distinct ZIP prefixes for each seller city and state.

SELECT
    seller_city,
    seller_state,
    COUNT(DISTINCT LPAD(seller_zip_code_prefix::text, 5, '0')) AS distinct_zip_prefixes,
    COUNT(*) AS seller_count,
    STRING_AGG(
        DISTINCT LPAD(seller_zip_code_prefix::text, 5, '0'),
        ', ' ORDER BY LPAD(seller_zip_code_prefix::text, 5, '0')
    ) AS zip_prefixes
FROM public.olist_sellers_dataset
GROUP BY seller_city, seller_state
HAVING COUNT(DISTINCT LPAD(seller_zip_code_prefix::text, 5, '0')) > 1
ORDER BY distinct_zip_prefixes DESC, seller_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 35: Inspect seller records with potentially inconsistent city and state combinations.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE
    (seller_city = 'curitiba' AND seller_state = 'SP')
    OR (seller_city = 'rio de janeiro' AND seller_state = 'SP')
    OR (seller_city = 'belo horizonte' AND seller_state = 'SP')
    OR (seller_city = 'caxias do sul' AND seller_state = 'SP')
ORDER BY seller_city, normalized_zip_prefix;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 37: Cross-check ZIP prefixes associated with potentially incorrect seller states.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_state,
    seller_city,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
WHERE LPAD(seller_zip_code_prefix::text, 5, '0') IN (
    '31160', '31570',
    '95055', '95076',
    '80240', '81020', '81560',
    '21320', '22783'
)
GROUP BY
    LPAD(seller_zip_code_prefix::text, 5, '0'),
    seller_state,
    seller_city
ORDER BY normalized_zip_prefix, seller_state, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 38: Review state and ZIP-prefix distribution for the four potentially affected cities.

SELECT
    seller_city,
    seller_state,
    COUNT(*) AS seller_count,
    COUNT(DISTINCT LPAD(seller_zip_code_prefix::text, 5, '0')) AS distinct_zip_prefixes,
    STRING_AGG(
        DISTINCT LPAD(seller_zip_code_prefix::text, 5, '0'),
        ', ' ORDER BY LPAD(seller_zip_code_prefix::text, 5, '0')
    ) AS zip_prefixes
FROM public.olist_sellers_dataset
WHERE seller_city IN (
    'belo horizonte',
    'caxias do sul',
    'curitiba',
    'rio de janeiro'
)
GROUP BY seller_city, seller_state
ORDER BY seller_city, seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 39: Inspect the Rio de Janeiro city record associated with state RN.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city = 'rio de janeiro'
  AND seller_state = 'RN';

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 40: Validate normalized seller ZIP prefix format.

SELECT
    COUNT(*) AS total_sellers,
    COUNT(*) FILTER (
        WHERE LPAD(seller_zip_code_prefix::text, 5, '0') ~ '^[0-9]{5}$'
    ) AS valid_five_digit_prefixes,
    COUNT(*) FILTER (
        WHERE LPAD(seller_zip_code_prefix::text, 5, '0') !~ '^[0-9]{5}$'
    ) AS invalid_prefixes,
    MIN(LPAD(seller_zip_code_prefix::text, 5, '0')) AS minimum_prefix,
    MAX(LPAD(seller_zip_code_prefix::text, 5, '0')) AS maximum_prefix
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 41: Review distinct seller state codes and their record counts.

SELECT
    seller_state,
    LENGTH(seller_state) AS state_code_length,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY seller_state
ORDER BY seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 42: Identify seller city values with leading or trailing whitespace.

SELECT
    seller_id,
    seller_city,
    BTRIM(seller_city) AS trimmed_city,
    LENGTH(seller_city) AS original_length,
    LENGTH(BTRIM(seller_city)) AS trimmed_length
FROM public.olist_sellers_dataset
WHERE seller_city <> BTRIM(seller_city)
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 43: Identify seller city values containing consecutive spaces.

SELECT
    seller_id,
    seller_city
FROM public.olist_sellers_dataset
WHERE seller_city ~ '  +'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 44: Identify seller city values containing tabs or line-break characters.

SELECT
    seller_id,
    seller_city,
    LENGTH(seller_city) AS city_length
FROM public.olist_sellers_dataset
WHERE seller_city ~ E'[\t\n\r]'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 45: Identify seller city values containing non-ASCII characters.

SELECT
    seller_id,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city !~ '^[\x00-\x7F]+$'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 46: Inspect hexadecimal encoding of seller city values containing non-ASCII characters.

SELECT
    seller_id,
    seller_city,
    ENCODE(CONVERT_TO(seller_city, 'UTF8'), 'hex') AS city_utf8_hex
FROM public.olist_sellers_dataset
WHERE seller_city !~ '^[\x00-\x7F]+$'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 47: Identify seller city values containing characters other than letters, spaces, and accented letters.

SELECT
    seller_id,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city ~ '[^[:alpha:] ]'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 48: Inspect abbreviated and ambiguous seller city values.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city IN (
    'sbc/sp',
    'sp / sp',
    '04482255',
    'barbacena/ minas gerais',
    'carapicuiba / sao paulo',
    'cariacica / es',
    'jacarei / sao paulo',
    'andira-pr'
)
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 49: Inspect all seller records sharing the ZIP prefixes of ambiguous city values.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE LPAD(seller_zip_code_prefix::text, 5, '0') IN ('09726', '03363')
ORDER BY normalized_zip_prefix, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 50: Identify seller city values containing numeric characters.

SELECT
    seller_id,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city ~ '[0-9]'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 51: Check for seller city values that are empty or whitespace-only.

SELECT
    COUNT(*) AS total_sellers,
    COUNT(*) FILTER (
        WHERE BTRIM(seller_city) = ''
    ) AS empty_or_whitespace_cities
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 52: Identify city values that become identical after basic whitespace normalization.

SELECT
    REGEXP_REPLACE(BTRIM(seller_city), '\s+', ' ', 'g') AS normalized_city,
    COUNT(DISTINCT seller_city) AS original_variations,
    COUNT(*) AS seller_count,
    STRING_AGG(DISTINCT seller_city, ' | ' ORDER BY seller_city) AS original_city_values
FROM public.olist_sellers_dataset
GROUP BY REGEXP_REPLACE(BTRIM(seller_city), '\s+', ' ', 'g')
HAVING COUNT(DISTINCT seller_city) > 1
ORDER BY original_variations DESC, normalized_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 53: Identify seller city values with case-only variations.

SELECT
    LOWER(seller_city) AS lowercase_city,
    COUNT(DISTINCT seller_city) AS original_variations,
    COUNT(*) AS seller_count,
    STRING_AGG(DISTINCT seller_city, ' | ' ORDER BY seller_city) AS original_city_values
FROM public.olist_sellers_dataset
GROUP BY LOWER(seller_city)
HAVING COUNT(DISTINCT seller_city) > 1
ORDER BY original_variations DESC, lowercase_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 54: Identify seller locations shared by multiple sellers.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY
    LPAD(seller_zip_code_prefix::text, 5, '0'),
    seller_city,
    seller_state
HAVING COUNT(*) > 1
ORDER BY seller_count DESC, normalized_zip_prefix;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 55: Summarize seller distribution across normalized ZIP, city, and state combinations.

WITH seller_locations AS (
    SELECT
        LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
        seller_city,
        seller_state,
        COUNT(*) AS seller_count
    FROM public.olist_sellers_dataset
    GROUP BY
        LPAD(seller_zip_code_prefix::text, 5, '0'),
        seller_city,
        seller_state
)
SELECT
    COUNT(*) AS distinct_location_combinations,
    SUM(seller_count) AS total_sellers,
    COUNT(*) FILTER (WHERE seller_count = 1) AS locations_with_one_seller,
    COUNT(*) FILTER (WHERE seller_count > 1) AS locations_with_multiple_sellers,
    MAX(seller_count) AS maximum_sellers_at_one_location,
    ROUND(AVG(seller_count)::numeric, 2) AS average_sellers_per_location
FROM seller_locations;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 56: Identify normalized ZIP prefixes associated with multiple city/state combinations.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    COUNT(DISTINCT seller_city) AS distinct_cities,
    COUNT(DISTINCT seller_state) AS distinct_states,
    COUNT(DISTINCT seller_city || ' | ' || seller_state) AS distinct_city_state_combinations,
    STRING_AGG(
        DISTINCT seller_city || ' (' || seller_state || ')',
        ', ' ORDER BY seller_city || ' (' || seller_state || ')'
    ) AS city_state_combinations,
    COUNT(*) AS seller_count
FROM public.olist_sellers_dataset
GROUP BY LPAD(seller_zip_code_prefix::text, 5, '0')
HAVING COUNT(DISTINCT seller_city || ' | ' || seller_state) > 1
ORDER BY distinct_city_state_combinations DESC, seller_count DESC;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 57: Inspect seller records with repeated city names across different states.

WITH city_state_counts AS (
    SELECT
        LOWER(seller_city) AS city_name,
        COUNT(DISTINCT seller_state) AS state_count
    FROM public.olist_sellers_dataset
    GROUP BY LOWER(seller_city)
    HAVING COUNT(DISTINCT seller_state) > 1
)
SELECT
    seller_id,
    LPAD(s.seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    s.seller_city,
    s.seller_state
FROM public.olist_sellers_dataset s
JOIN city_state_counts c
    ON LOWER(s.seller_city) = c.city_name
WHERE NOT (
    (s.seller_city = 'curitiba' AND s.seller_state = 'SP')
    OR (s.seller_city = 'belo horizonte' AND s.seller_state = 'SP')
    OR (s.seller_city = 'caxias do sul' AND s.seller_state = 'SP')
    OR (s.seller_city = 'rio de janeiro' AND s.seller_state = 'SP')
)
ORDER BY s.seller_city, normalized_zip_prefix, s.seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 58: Summarize city/state combinations for cities associated with multiple states.

-- Step 58: Summarize city/state combinations for cities associated with multiple states.

WITH multi_state_cities AS (
    SELECT LOWER(seller_city) AS city_name
    FROM public.olist_sellers_dataset
    GROUP BY LOWER(seller_city)
    HAVING COUNT(DISTINCT seller_state) > 1
)
SELECT
    LOWER(s.seller_city) AS city_name,
    s.seller_state,
    COUNT(*) AS seller_count,
    COUNT(DISTINCT LPAD(s.seller_zip_code_prefix::text, 5, '0')) AS distinct_zip_prefixes,
    STRING_AGG(
        DISTINCT LPAD(s.seller_zip_code_prefix::text, 5, '0'),
        ', ' ORDER BY LPAD(s.seller_zip_code_prefix::text, 5, '0')
    ) AS zip_prefixes
FROM public.olist_sellers_dataset s
JOIN multi_state_cities m
    ON LOWER(s.seller_city) = m.city_name
GROUP BY LOWER(s.seller_city), s.seller_state
ORDER BY city_name, s.seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 59: Cross-check additional suspected city/state mismatches against all sellers sharing their ZIP prefixes.

SELECT
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state,
    COUNT(*) AS seller_count,
    STRING_AGG(seller_id, ', ' ORDER BY seller_id) AS seller_ids
FROM public.olist_sellers_dataset
WHERE LPAD(seller_zip_code_prefix::text, 5, '0') IN (
    '89052',
    '89803',
    '88075',
    '88301',
    '83321',
    '83020',
    '91520',
    '86076',
    '36010'
)
GROUP BY
    LPAD(seller_zip_code_prefix::text, 5, '0'),
    seller_city,
    seller_state
ORDER BY normalized_zip_prefix, seller_state, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 60: Inspect all seller records for unresolved city/state discrepancies.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE LPAD(seller_zip_code_prefix::text, 5, '0') IN (
    '86076',
    '88075',
    '88301',
    '89803',
    '91520',
    '21320',
    '31570',
    '95055',
    '21210',
    '37795',
    '85960',
    '44600'
)
ORDER BY normalized_zip_prefix, seller_state, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 61: Identify city values containing characters outside the expected alphabetic and locality punctuation set.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city !~ '^[a-zA-ZÀ-ÿ ''()/,-]+$'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 62: Count city values containing digits or unusual symbols.

SELECT
    COUNT(*) AS affected_records,
    COUNT(DISTINCT seller_city) AS distinct_city_values
FROM public.olist_sellers_dataset
WHERE seller_city ~ '[0-9@#$%&*+=<>!?;:{}\[\]\\|^~`]';

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 63: Retrieve city values containing digits or unusual symbols.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city ~ '[0-9@#$%&*+=<>!?;:{}\[\]\\|^~`]'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 64: Identify city values beginning or ending with punctuation.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city ~ '^[^a-zA-ZÀ-ÿ]'
   OR seller_city ~ '[^a-zA-ZÀ-ÿ]$'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 65: Identify unusually short or long seller city values.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    LENGTH(seller_city) AS city_name_length,
    seller_state
FROM public.olist_sellers_dataset
WHERE LENGTH(BTRIM(seller_city)) <= 2
   OR LENGTH(seller_city) >= 40
ORDER BY city_name_length, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 66: Identify seller city values with leading, trailing, or repeated whitespace.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE seller_city <> BTRIM(seller_city)
   OR seller_city ~ '\s{2,}'
ORDER BY seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 67: Validate city and state completeness after whitespace normalization.

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(seller_city), '') IS NULL
    ) AS blank_city_records,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(seller_state), '') IS NULL
    ) AS blank_state_records,
    COUNT(*) FILTER (
        WHERE NULLIF(REGEXP_REPLACE(BTRIM(seller_city), '\s+', ' ', 'g'), '') IS NULL
    ) AS normalized_blank_city_records,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(seller_state), '') IS NULL
    ) AS normalized_blank_state_records
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 68: Review seller records proposed for city-name corrections.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city AS original_city,
    seller_state
FROM public.olist_sellers_dataset
WHERE
    seller_city IN (
        'vendas@creditparts.com.br',
        'rio de janeiro \rio de janeiro',
        'santa barbara d´oeste',
        'são paulo',
        'pirituba',
        'novo hamburgo, rio grande do sul, brasil',
        'auriflama/sp',
        'santo andre/sao paulo',
        'maua/sao paulo',
        'ribeirao preto / sao paulo',
        'sao paulo - sp',
        'sao paulo / sao paulo',
        'lages - sc',
        'barbacena/ minas gerais',
        'carapicuiba / sao paulo',
        'cariacica / es',
        'jacarei / sao paulo',
        'andira-pr',
        'sbc/sp',
        'sp / sp'
    )
ORDER BY original_city, normalized_zip_prefix;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 69: Verify the seller records proposed for state correction.

SELECT
    seller_id,
    LPAD(seller_zip_code_prefix::text, 5, '0') AS normalized_zip_prefix,
    seller_city,
    seller_state AS original_state,
    CASE
        WHEN seller_city = 'rio de janeiro' AND seller_zip_code_prefix = 21210 AND seller_state = 'RN' THEN 'RJ'
        WHEN seller_city = 'rio de janeiro' AND seller_zip_code_prefix = 22783 AND seller_state = 'SP' THEN 'RJ'
        WHEN seller_city = 'belo horizonte' AND seller_zip_code_prefix = 31160 AND seller_state = 'SP' THEN 'MG'
        WHEN seller_city = 'curitiba' AND seller_zip_code_prefix IN (80240, 81020, 81560) AND seller_state = 'SP' THEN 'PR'
        WHEN seller_city = 'caxias do sul' AND seller_zip_code_prefix = 95076 AND seller_state = 'SP' THEN 'RS'
        WHEN seller_city = 'juiz de fora' AND seller_zip_code_prefix = 36010 AND seller_state = 'SP' THEN 'MG'
        WHEN seller_city = 'sao jose dos pinhais' AND seller_zip_code_prefix = 83020 AND seller_state = 'SP' THEN 'PR'
        WHEN seller_city = 'pinhais' AND seller_zip_code_prefix = 83321 AND seller_state = 'SP' THEN 'PR'
        WHEN seller_city = 'blumenau' AND seller_zip_code_prefix = 89052 AND seller_state = 'SP' THEN 'SC'
    END AS proposed_state
FROM public.olist_sellers_dataset
WHERE
    (seller_city = 'rio de janeiro' AND seller_zip_code_prefix IN (21210, 22783) AND seller_state IN ('RN', 'SP'))
    OR (seller_city = 'belo horizonte' AND seller_zip_code_prefix = 31160 AND seller_state = 'SP')
    OR (seller_city = 'curitiba' AND seller_zip_code_prefix IN (80240, 81020, 81560) AND seller_state = 'SP')
    OR (seller_city = 'caxias do sul' AND seller_zip_code_prefix = 95076 AND seller_state = 'SP')
    OR (seller_city = 'juiz de fora' AND seller_zip_code_prefix = 36010 AND seller_state = 'SP')
    OR (seller_city = 'sao jose dos pinhais' AND seller_zip_code_prefix = 83020 AND seller_state = 'SP')
    OR (seller_city = 'pinhais' AND seller_zip_code_prefix = 83321 AND seller_state = 'SP')
    OR (seller_city = 'blumenau' AND seller_zip_code_prefix = 89052 AND seller_state = 'SP')
ORDER BY normalized_zip_prefix, seller_city;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 70: Validate five-character numeric ZIP prefixes for all seller records.

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE LPAD(seller_zip_code_prefix::text, 5, '0') ~ '^[0-9]{5}$'
    ) AS valid_five_digit_prefixes,
    COUNT(*) FILTER (
        WHERE LPAD(seller_zip_code_prefix::text, 5, '0') !~ '^[0-9]{5}$'
    ) AS invalid_prefixes,
    MIN(LPAD(seller_zip_code_prefix::text, 5, '0')) AS minimum_prefix,
    MAX(LPAD(seller_zip_code_prefix::text, 5, '0')) AS maximum_prefix
FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 71: Summarize previously identified seller city-name variations for final cleaning decisions.

SELECT
    seller_city AS original_city,
    seller_state,
    COUNT(*) AS seller_count,
    STRING_AGG(
        DISTINCT LPAD(seller_zip_code_prefix::text, 5, '0'),
        ', ' ORDER BY LPAD(seller_zip_code_prefix::text, 5, '0')
    ) AS zip_prefixes
FROM public.olist_sellers_dataset
WHERE LOWER(seller_city) IN (
    'portoferreira',
    'mogi das cruses',
    'belo horizont',
    'riberao preto',
    'scao jose do rio pardo',
    'balenario camboriu',
    'cascavael',
    'sando andre',
    'garulhos',
    'sao bernardo do capo',
    'robeirao preto',
    'sao paulo sp',
    'floranopolis',
    'rio de janeiro, rio de janeiro, brasil',
    'santa barbara d oeste',
    'sao miguel do oeste',
    'sao miguel d''oeste',
    'pirituba',
    'maua/sao paulo',
    'auriflama/sp',
    'sao paulo - sp',
    'sao paulo / sao paulo',
    'santo andre/sao paulo',
    'ribeirao preto / sao paulo'
)
GROUP BY seller_city, seller_state
ORDER BY original_city, seller_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 72: Create the cleaned seller view with validated ZIP, city and state corrections.

CREATE OR REPLACE VIEW public.olist_sellers_cleaned AS
SELECT
    seller_id,

    LPAD(seller_zip_code_prefix::text, 5, '0') AS seller_zip_code_prefix,

    CASE
        -- Correct city values containing invalid or misplaced text.
        WHEN seller_city = 'vendas@creditparts.com.br' THEN 'maringa'
        WHEN seller_city = '04482255' THEN seller_city

        -- Normalize duplicated or extended city descriptions.
        WHEN seller_city = 'rio de janeiro \rio de janeiro' THEN 'rio de janeiro'
        WHEN seller_city = 'rio de janeiro, rio de janeiro, brasil' THEN 'rio de janeiro'
        WHEN seller_city = 'novo hamburgo, rio grande do sul, brasil' THEN 'novo hamburgo'

        -- Normalize city names containing state suffixes.
        WHEN seller_city IN (
            'andira-pr',
            'auriflama/sp',
            'barbacena/ minas gerais',
            'carapicuiba / sao paulo',
            'cariacica / es',
            'jacarei / sao paulo',
            'lages - sc',
            'maua/sao paulo',
            'ribeirao preto / sao paulo',
            'santo andre/sao paulo',
            'sao paulo - sp',
            'sao paulo / sao paulo',
            'sao paulo sp'
        )
        THEN CASE
            WHEN seller_city = 'andira-pr' THEN 'andira'
            WHEN seller_city = 'auriflama/sp' THEN 'auriflama'
            WHEN seller_city = 'barbacena/ minas gerais' THEN 'barbacena'
            WHEN seller_city = 'carapicuiba / sao paulo' THEN 'carapicuiba'
            WHEN seller_city = 'cariacica / es' THEN 'cariacica'
            WHEN seller_city = 'jacarei / sao paulo' THEN 'jacarei'
            WHEN seller_city = 'lages - sc' THEN 'lages'
            WHEN seller_city = 'maua/sao paulo' THEN 'maua'
            WHEN seller_city = 'ribeirao preto / sao paulo' THEN 'ribeirao preto'
            WHEN seller_city = 'santo andre/sao paulo' THEN 'santo andre'
            ELSE 'sao paulo'
        END

        -- Correct spelling variations supported by ZIP and state consistency.
        WHEN seller_city = 'portoferreira' THEN 'porto ferreira'
        WHEN seller_city = 'mogi das cruses' THEN 'mogi das cruzes'
        WHEN seller_city = 'belo horizont' THEN 'belo horizonte'
        WHEN seller_city = 'riberao preto' THEN 'ribeirao preto'
        WHEN seller_city = 'robeirao preto' THEN 'ribeirao preto'
        WHEN seller_city = 'scao jose do rio pardo' THEN 'sao jose do rio pardo'
        WHEN seller_city = 'balenario camboriu' THEN 'balneario camboriu'
        WHEN seller_city = 'cascavael' THEN 'cascavel'
        WHEN seller_city = 'sando andre' THEN 'santo andre'
        WHEN seller_city = 'garulhos' THEN 'guarulhos'
        WHEN seller_city = 'sao bernardo do capo' THEN 'sao bernardo do campo'
        WHEN seller_city = 'floranopolis' THEN 'florianopolis'
        WHEN seller_city = 'santa barbara d oeste' THEN 'santa barbara d''oeste'
        WHEN seller_city IN (
            'sao miguel d''oeste',
            'sao miguel do oeste'
        ) THEN 'sao miguel do oeste'

        -- Correct the city value for the corroborated ZIP prefix.
        WHEN seller_city = 'sp'
             AND seller_zip_code_prefix = 5141 THEN 'pirituba'

        -- Normalize the unusual apostrophe and Unicode spelling.
        WHEN seller_city = 'santa barbara d´oeste' THEN 'santa barbara d''oeste'
        WHEN seller_city = 'são paulo' THEN 'sao paulo'

        -- Normalize repeated internal spaces in remaining city names.
        ELSE REGEXP_REPLACE(BTRIM(seller_city), '\s+', ' ', 'g')
    END AS seller_city,

    CASE
        WHEN seller_city = 'rio de janeiro'
             AND seller_zip_code_prefix = 21210
             AND seller_state = 'RN' THEN 'RJ'

        WHEN seller_city = 'rio de janeiro'
             AND seller_zip_code_prefix = 22783
             AND seller_state = 'SP' THEN 'RJ'

        WHEN seller_city = 'belo horizonte'
             AND seller_zip_code_prefix = 31160
             AND seller_state = 'SP' THEN 'MG'

        WHEN seller_city = 'juiz de fora'
             AND seller_zip_code_prefix = 36010
             AND seller_state = 'SP' THEN 'MG'

        WHEN seller_city = 'curitiba'
             AND seller_zip_code_prefix IN (80240, 81020, 81560)
             AND seller_state = 'SP' THEN 'PR'

        WHEN seller_city = 'sao jose dos pinhais'
             AND seller_zip_code_prefix = 83020
             AND seller_state = 'SP' THEN 'PR'

        WHEN seller_city = 'pinhais'
             AND seller_zip_code_prefix = 83321
             AND seller_state = 'SP' THEN 'PR'

        WHEN seller_city = 'blumenau'
             AND seller_zip_code_prefix = 89052
             AND seller_state = 'SP' THEN 'SC'

        WHEN seller_city = 'caxias do sul'
             AND seller_zip_code_prefix = 95076
             AND seller_state = 'SP' THEN 'RS'

        ELSE seller_state
    END AS seller_state

FROM public.olist_sellers_dataset;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 73: Compare source and cleaned seller record counts.

SELECT
    (SELECT COUNT(*)
     FROM public.olist_sellers_dataset) AS source_records,

    (SELECT COUNT(*)
     FROM public.olist_sellers_cleaned) AS cleaned_records,

    (SELECT COUNT(DISTINCT seller_id)
     FROM public.olist_sellers_cleaned) AS distinct_seller_ids;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 74: Identify seller records with differences between source and cleaned view.

SELECT
    s.seller_id,
    s.seller_zip_code_prefix AS original_zip_prefix,
    c.seller_zip_code_prefix AS cleaned_zip_prefix,
    s.seller_city AS original_city,
    c.seller_city AS cleaned_city,
    s.seller_state AS original_state,
    c.seller_state AS cleaned_state
FROM public.olist_sellers_dataset s
JOIN public.olist_sellers_cleaned c
    ON s.seller_id = c.seller_id
WHERE
    s.seller_zip_code_prefix::text <> c.seller_zip_code_prefix
    OR s.seller_city IS DISTINCT FROM c.seller_city
    OR s.seller_state IS DISTINCT FROM c.seller_state
ORDER BY s.seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 75: Categorize differences between source and cleaned seller records.

SELECT
    CASE
        WHEN s.seller_zip_code_prefix::text <> c.seller_zip_code_prefix
             AND s.seller_city IS NOT DISTINCT FROM c.seller_city
             AND s.seller_state IS NOT DISTINCT FROM c.seller_state
            THEN 'ZIP only'

        WHEN s.seller_zip_code_prefix::text = c.seller_zip_code_prefix
             AND s.seller_city IS DISTINCT FROM c.seller_city
             AND s.seller_state IS NOT DISTINCT FROM c.seller_state
            THEN 'City only'

        WHEN s.seller_zip_code_prefix::text = c.seller_zip_code_prefix
             AND s.seller_city IS NOT DISTINCT FROM c.seller_city
             AND s.seller_state IS DISTINCT FROM c.seller_state
            THEN 'State only'

        WHEN s.seller_zip_code_prefix::text <> c.seller_zip_code_prefix
             AND s.seller_city IS DISTINCT FROM c.seller_city
             AND s.seller_state IS NOT DISTINCT FROM c.seller_state
            THEN 'ZIP and city'

        WHEN s.seller_zip_code_prefix::text <> c.seller_zip_code_prefix
             AND s.seller_city IS NOT DISTINCT FROM c.seller_city
             AND s.seller_state IS DISTINCT FROM c.seller_state
            THEN 'ZIP and state'

        WHEN s.seller_zip_code_prefix::text = c.seller_zip_code_prefix
             AND s.seller_city IS DISTINCT FROM c.seller_city
             AND s.seller_state IS DISTINCT FROM c.seller_state
            THEN 'City and state'

        ELSE 'ZIP, city and state'
    END AS change_category,
    COUNT(*) AS affected_records
FROM public.olist_sellers_dataset s
JOIN public.olist_sellers_cleaned c
    ON s.seller_id = c.seller_id
WHERE
    s.seller_zip_code_prefix::text <> c.seller_zip_code_prefix
    OR s.seller_city IS DISTINCT FROM c.seller_city
    OR s.seller_state IS DISTINCT FROM c.seller_state
GROUP BY change_category
ORDER BY change_category;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 76: Summarize state changes between source and cleaned seller records.

SELECT
    s.seller_state AS original_state,
    c.seller_state AS cleaned_state,
    COUNT(*) AS affected_records
FROM public.olist_sellers_dataset s
JOIN public.olist_sellers_cleaned c
    ON s.seller_id = c.seller_id
WHERE s.seller_state IS DISTINCT FROM c.seller_state
GROUP BY s.seller_state, c.seller_state
ORDER BY original_state, cleaned_state;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 77: Validate ZIP-prefix format in the cleaned seller view.

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix ~ '^[0-9]{5}$'
    ) AS valid_five_digit_prefixes,
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix !~ '^[0-9]{5}$'
    ) AS invalid_prefixes,
    MIN(seller_zip_code_prefix) AS minimum_prefix,
    MAX(seller_zip_code_prefix) AS maximum_prefix
FROM public.olist_sellers_cleaned;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Step 78: Compare all seller IDs and unchanged source attributes between source and cleaned view.

SELECT
    COUNT(*) AS matched_records,
    COUNT(*) FILTER (
        WHERE s.seller_id IS DISTINCT FROM c.seller_id
    ) AS seller_id_mismatches
FROM public.olist_sellers_dataset s
FULL OUTER JOIN public.olist_sellers_cleaned c
    ON s.seller_id = c.seller_id;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
