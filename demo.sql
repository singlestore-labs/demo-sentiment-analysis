create database demo;
use demo;
create link gcs_wasm as gcs credentials '{}' description 'wasm and wit examples';

CREATE TABLE `comments` (
    `id` int,
    `text` text,
    `creation_date` timestamp,
    `score` int,
    score_bucket as (score - (score % 10)) persisted int,
    KEY (score) USING CLUSTERED COLUMNSTORE,
    SHARD KEY ()
);

CREATE PIPELINE `sowasm` AS LOAD DATA LINK gcs_wasm 'stackoverflow-wasm'
INTO TABLE `comments`
FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\\' LINES TERMINATED BY '\n' STARTING BY '';

start pipeline sowasm;

select pipeline_name, batch_state, batch_time, rows_per_sec, mb_per_sec from information_schema.pipelines_batches_summary;
select pipeline_name, file_state, count(*) from information_schema.pipelines_files group by 1,2;

optimize table comments full;

create function sentimentable returns table as wasm
    from link gcs_wasm 'wasm-modules/sentimentable.wasm'
    with wit from link gcs_wasm 'wasm-modules/sentimentable.wit';

select
    score_bucket,
    count(*) as num_comments,
    abs(min(sentiment.compound)) as "negative",
    max(sentiment.compound) as "positive"
from (
    select score_bucket, text
    from comments
    where score >= 10
) as c
join sentimentable(c.text) as sentiment
group by 1
having positive > 0 and negative > 0 and num_comments > 20
order by 1 asc;
