#!/bin/sh

# Set default variables
default_ipv4="${PIPE_DEFAULT_IPV4}"
default_ipv6="${PIPE_DEFAULT_IPV6}"
default_mx="${PIPE_DEFAULT_MX}"
default_ns="${PIPE_DEFAULT_NS}"

# Read input line by line from stdin
while IFS=$'#\t\n' read -r input; do

  echo $input >> /etc/pdns/debug.log

  # Extract the method from the input
  method=$(echo "$input" | jq -r '.method')

  # Process the input based on the command
  case "$command" in
    initialize)
      # Respond to the initialize command
      echo '{"result":true}'
      ;;

    lookup)
      # Extract parameters from the input
      qname=$(echo "$input" | jq -r '.parameters.qname')
      qtype=$(echo "$input" | jq -r '.parameters.qtype')

      if [ "$qtype" = "A" ] || [ "$qtype" = "ANY" ]; then
#        echo '{"result":[{"qtype":"A", "qname":"$qname", "content":"$default_ipv4", "ttl": 60}]}' >> /etc/pdns/debug.log
#        echo '{"result":[{"qtype":"A", "qname":"$qname", "content":"$default_ipv4", "ttl": 60}]}'
         echo '{"result":[{"qtype":"A", "qname":"example.com", "content":"127.0.0.2", "ttl": 60}]}'
      fi

#      if [ "$qtype" = "AAAA" ] || [ "$qtype" = "ANY" ]; then
#        echo $(printf "DATA\t%s.\tIN\tAAAA\t60\t-1\t%s\n" "$qname" "$default_ipv6") >> /etc/pdns/debug.log
#        printf "DATA\t%s.\tIN\tAAAA\t60\t-1\t%s\n" "$qname" "$default_ipv6"
#      fi

#      if [ "$qtype" = "NS" ] || [ "$qtype" = "ANY" ]; then
#        echo $(printf "DATA\t%s.\tIN\tNS\t60\t-1\tns1.%s.\n" "$qname" "$qname") >> /etc/pdns/debug.log
#        printf "DATA\t%s.\tIN\tNS\t60\t-1\tns1.%s.\n" "$qname" "$qname"
#      fi

#      if [ "$qtype" = "CNAME" ] || [ "$qtype" = "ANY" ]; then
#        printf "DATA\t%s.\tIN\tCNAME\t60\t-1\t%s.\n" "$qname" "$qname"
#      fi

#      if [ "$qtype" = "MX" ] || [ "$qtype" = "ANY" ]; then
#        echo $(printf "DATA\t%s.\tIN\tMX\t60\t-1\t10\t%s.\n" "$qname" "$default_mx") >> /etc/pdns/debug.log
#        printf "DATA\t%s.\tIN\tMX\t60\t-1\t10\t%s.\n" "$qname" "$default_mx"
#      fi

      if [ "$qtype" = "SOA" ] || [ "$qtype" = "ANY" ]; then
#        JSON_FMT='{"result":[{ "qtype": "SOA","qname": "%s","content": "%s. hostmaster.%s. %s 10800 3600 604800 3600","ttl": 3600,"domain_id": -1}]}\n'
#        echo $(printf "$JSON_FMT" "$qname" "$default_ns" "$qname" "2022042801") >> /etc/pdns/debug.log
        echo '{"result":[{ "qtype": "SOA","qname": "example.com","content": "dns1.icann.org. hostmaster.icann.org. 2012080849 7200 3600 1209600 3600","ttl": 3600,"domain_id": -1}]}'
#        printf "$JSON_FMT" "$qname" "$default_ns" "$qname" "2022042801"
      fi

      ;;

    *)
      # Unsupported command
      echo '{"result":true}'
      ;;
  esac

  # Send the reply to PowerDNS
  printf '{"result":true}'
done