{% for key, value in environment('PDNS_AUTH_') %}{{ key|replace('_', '-') }}={{ value }}
{% endfor %}