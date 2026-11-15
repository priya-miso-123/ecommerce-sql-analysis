/*
--------------------------------------------
What review scores are available?

How many records exist for each review score?

What is the minimum and maximum review creation date?

How many reviews have missing comments?

How many reviews have missing titles?

How many reviews have missing response timestamps?

Are there duplicate review_id values?

How many orders have multiple review records?

Are there reviews with response timestamps earlier than creation timestamps?

What is the distribution of review records across weekdays?
--------------------------------------------
*/

--What review scores are available?

select
	distinct review_score
from olist_order_reviews_dataset;

--How many records exist for each review score?

select
	review_score,
	count(*) as review_record
from olist_order_reviews_dataset
group by
	review_score
order by
	review_score;

--What is the minimum and maximum review creation date?

select
	max(review_creation_date) as earliest,
	min(review_creation_date) as oldest
from olist_order_reviews_dataset;

--How many reviews have missing comments?

select
	count(*) filter(where review_comment_message is null) as missing_comment_count
from olist_order_reviews_dataset;

--How many reviews have missing titles?

select 
	count(*) filter (where review_comment_title is null and review_comment_message is not null) as missing_comment_title_count
from olist_order_reviews_dataset;

--How many reviews have missing response timestamps?

select
	count(*) filter(where review_answer_timestamp is null) as missing_timestamp 
from olist_order_reviews_dataset;

--Are there duplicate review_id values?

select 
	count(*) as duplicate_review_id
from(
		select
			review_id,
			count(*) as count_r
		from olist_order_reviews_dataset
		group by 
			review_id
		having count(*) > 1
) as duplicate_record;

--How many orders have multiple review records?

select
	count(*) as repeat_review
from(
	select
		order_id,
		count(review_score) as count_r
	from olist_order_reviews_dataset
	group by
		order_id
	having count(review_score) > 1		
) as repeat_review;

--Are there reviews with response timestamps earlier than creation timestamps?

select
	count(*) filter(where review_answer_timestamp < review_creation_date) as timestamp_overlap_check
from olist_order_reviews_dataset;

--What is the distribution of review records across weekdays?

select
	review_score,
	count(*) as weekday_review_score_count,
	round(
		count(*) * 100.0 / sum(count(*)) over ()
	,3) as weekday_review_percentage
from olist_order_reviews_dataset
where to_char(review_answer_timestamp,'D') in ('2','3','4','5','6')
group by
	review_score
order by
	weekday_review_score_count DESC;