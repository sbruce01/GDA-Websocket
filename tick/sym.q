order: ([]`s#time:"p"$();`g#sym:`$();orderID:();side:`$();price:"f"$();size:"f"$();action:`$();orderType:`$();exchange:`$());
trade: ([]`s#time:"p"$();`g#sym:`$();orderID:();price:"f"$();tradeID:();side:`$();size:"f"$();exchange:`$());
ethereum:([]block_num:`long$();block_hash:();block_timestamp:`long$();miner:();parent_hash:();num_transactions:`long$();timestamp:"p"$();tx_hash:();sender:();to:();gas:`long$();gas_price:`long$();val:`long$());
active_accounts:([]time:`timestamp$();sym:`$();activeAccountSenderCount:`long$(); activeAccountRecvCount:`long$());
vwap:([]sym:`$();exchange:`$();time:`minute$();vwap:`float$();accVol:`float$());
ohlcv:([]sym:`$();exchange:`$();time:`minute$();open:`float$();high:`float$();low:`float$();close:`float$();volume:`float$());
rawbinance:([]time:"p"$;sym:`$();raw:());
rawbybit:([]time:"p"$();sym:`$();raw:());
rawcoinbase:([]time:"p"$();sym:`$();raw:());