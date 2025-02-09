CREATE FUNCTION grest.script_redeemers (_script_hash text) 
  RETURNS TABLE (
    script_hash text,
    redeemers jsonb
  ) 
LANGUAGE PLPGSQL AS
$$
DECLARE _script_hash_bytea bytea;
BEGIN
SELECT INTO _script_hash_bytea DECODE(_script_hash, 'hex');
RETURN QUERY
select _script_hash,
    JSONB_AGG(
        JSONB_BUILD_OBJECT(
            'tx_hash',
            ENCODE(tx.hash, 'hex'),
            'tx_index',
            redeemer.index,
            'unit_mem',
            redeemer.unit_mem,
            'unit_steps',
            redeemer.unit_steps,
            'fee',
            redeemer.fee::text,
            'purpose',
            redeemer.purpose,
            'datum_hash',
            ENCODE(rd.hash, 'hex'),
            'datum_value',
            rd.value
            -- extra bytes field available in rd. table here
        )
    ) as redeemers
FROM redeemer
    INNER JOIN TX ON tx.id = redeemer.tx_id
    INNER JOIN REDEEMER_DATA rd on rd.id = redeemer.redeemer_data_id
WHERE redeemer.script_hash = _script_hash_bytea
GROUP BY redeemer.script_hash;
END;
$$;

COMMENT ON FUNCTION grest.script_redeemers IS 'Get all redeemers for a given script hash.';
