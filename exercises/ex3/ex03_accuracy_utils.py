_config = {}


def setup_accuracy(myconn, all_targets, data_schema, test_table):
    _config['myconn'] = myconn
    _config['all_targets'] = all_targets
    _config['data_schema'] = data_schema
    _config['test_table'] = test_table


def make_truth_union(all_targets, data_schema, test_table):
    return "\n    UNION ALL ".join(
        f'SELECT "ID", \'{col}\' AS TARGET, CAST("{col}" AS NVARCHAR(1000)) AS TRUE_VAL'
        f' FROM "{data_schema}"."{test_table}"'
        for col in all_targets
    )


def compute_accuracy(result_table):
    """Compute Top-1 %, Top-3 %, and MRR for each predicted field.

    Parameters
    ----------
    result_table : str
        HANA table name — must have columns: ID, TARGET, SCORE, CONFIDENCE.

    Returns
    -------
    pd.DataFrame  columns: Field | Top-1 | Top-3 | MRR
    """
    myconn      = _config['myconn']
    all_targets = _config['all_targets']
    data_schema = _config['data_schema']
    test_table  = _config['test_table']

    truth_union = make_truth_union(all_targets, data_schema, test_table)

    field_order = " ".join(
        f"WHEN '{col}' THEN {i + 1}"
        for i, col in enumerate(all_targets)
    )

    sql = f"""
WITH
RANKED AS (
    SELECT "ID", "TARGET", "SCORE",
           ROW_NUMBER() OVER (PARTITION BY "ID", "TARGET" ORDER BY "CONFIDENCE" DESC) AS RNK
    FROM "{result_table}"
),
TRUTH AS (
    {truth_union}
),
TRUE_RANKS AS (
    SELECT t.ID, t.TARGET,
           MIN(CASE WHEN r."SCORE" = t.TRUE_VAL THEN r.RNK END) AS TRUE_RANK
    FROM TRUTH t
    LEFT JOIN RANKED r ON r."ID" = t.ID AND r."TARGET" = t.TARGET
    GROUP BY t.ID, t.TARGET
)
SELECT TARGET AS "Field",
    ROUND(SUM(CASE WHEN TRUE_RANK = 1  THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS "Top-1",
    ROUND(SUM(CASE WHEN TRUE_RANK <= 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS "Top-3",
    ROUND(SUM(CASE WHEN TRUE_RANK IS NOT NULL THEN 1.0 / TRUE_RANK ELSE 0.0 END) / COUNT(*), 3) AS "MRR"
FROM TRUE_RANKS
GROUP BY TARGET
ORDER BY CASE TARGET {field_order} END
"""
    return myconn.sql(sql).collect()
