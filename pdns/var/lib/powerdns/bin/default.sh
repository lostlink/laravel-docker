#!/usr/bin/env bash

# Set default variables
default_ipv4="${PIPE_DEFAULT_IPV4}"
default_ipv6="${PIPE_DEFAULT_IPV6}"
default_mx="${PIPE_DEFAULT_MX}"
default_ns="${PIPE_DEFAULT_NS:-ns1.example.com}"

# Read input line by line from stdin
while IFS=$'#\t\n' read -r input; do
  # Extract command, qname, and qtype from the input in one awk call
  read -r command qname _ qtype _ <<< $(echo "$input" | awk '{print $1, $2, $3, $4, $5}')

  if [ "$qname" = "." ]; then
    qname=""
  fi

  # Process the input based on the command
  case "$command" in
    HELO)
      # Respond to the HELO command
      printf "OK\n"
      ;;

    Q)
      # Handle DNS query types
      case "$qtype" in
        A|ANY)
          printf "DATA\t%s.\tIN\tA\t60\t-1\t%s\n" "$qname" "$default_ipv4"
          ;;&
        AAAA|ANY)
          printf "DATA\t%s.\tIN\tAAAA\t60\t-1\t%s\n" "$qname" "$default_ipv6"
          ;;&
        NS|ANY)
          printf "DATA\t%s.\tIN\tNS\t60\t-1\tns1.%s\n" "$qname" "$qname"
          ;;&
        CNAME)
          printf "FAIL\n"
          ;;&
        MX|ANY)
          printf "DATA\t%s.\tIN\tMX\t60\t-1\t10\t%s\n" "$qname" "$default_mx"
          ;;&
        SOA|ANY)
          printf "DATA\t%s.\tIN\tSOA\t60\t-1\t%s.\thostmaster.%s\t2022042801\t10800\t3600\t604800\t3600\n" "$qname" "$default_ns" "$qname"
          ;;
      esac
      ;;

    *)
      # Unsupported command
      printf "FAIL\n"
      ;;
  esac

  # Send the reply to PowerDNS
  printf "END\n"
done
