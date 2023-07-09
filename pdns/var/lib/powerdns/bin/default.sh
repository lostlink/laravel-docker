#!/bin/sh

# Set default variables
default_ipv4="44.213.108.239"
default_ipv6="2600:1f18:65b8:7a02:b45a:a290:c7d7:67af"
default_mx="mxa.srvxx.dev"

# Read input line by line from stdin
while IFS=$'#\t\n' read -r input; do
  # Extract the command from the input
  command=$(echo "$input" | awk '{print $1}')

  # Process the input based on the command
  case "$command" in
    HELO)
      # Respond to the HELO command
      printf "OK\n"
      ;;

    Q)
      # Extract parameters from the input
      qname=$(echo "$input" | awk '{print $2}')
      qtype=$(echo "$input" | awk '{print $4}')

      if [ "$qtype" = "A" ] || [ "$qtype" = "ANY" ]; then
        printf "DATA\t%s.\tIN\tA\t60\t-1\t%s\n" "$qname" "$default_ipv4"
      fi

      if [ "$qtype" = "AAAA" ] || [ "$qtype" = "ANY" ]; then
        printf "DATA\t%s.\tIN\tAAAA\t60\t-1\t%s\n" "$qname" "$default_ipv6"
      fi

      if [ "$qtype" = "NS" ] || [ "$qtype" = "ANY" ]; then
        printf "DATA\t%s.\tIN\tNS\t60\t-1\tns1.%s.\n" "$qname" "$qname"
      fi

#      if [ "$qtype" = "CNAME" ] || [ "$qtype" = "ANY" ]; then
#        printf "DATA\t%s.\tIN\tCNAME\t60\t-1\t%s.\n" "$qname" "$qname"
#      fi

      if [ "$qtype" = "MX" ] || [ "$qtype" = "ANY" ]; then
        printf "DATA\t%s.\tIN\tMX\t60\t-1\t10\t%s.\n" "$qname" "$default_mx"
      fi

      if [ "$qtype" = "SOA" ] || [ "$qtype" = "ANY" ]; then
        printf "DATA\t%s.\tIN\tSOA\t60\t-1\tns1.%s.\thostmaster.%s.\t2022042801\t10800\t3600\t604800\t3600\n" "$qname" "$qname" "$qname"
      fi

      ;;

    *)
      # Unsupported command
      printf "FAIL\n"
      ;;
  esac

  # Send the reply to PowerDNS
  printf "END\n"
done