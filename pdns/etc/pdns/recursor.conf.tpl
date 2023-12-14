{% for key, value in environment('PDNS_REC_') %}{{ key|replace('_', '-') }}={{ value }}
{% endfor %}