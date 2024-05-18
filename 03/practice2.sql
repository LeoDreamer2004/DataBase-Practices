drop table if exists stock;
create table stock(
    ts_code varchar(15),
    trade_date date,
    open float,
    high float,
    low float,
    close float,
    pre_close float,
    pct_chg float,
    vol float,
    amount float
);