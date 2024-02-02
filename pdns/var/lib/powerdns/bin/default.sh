#!/usr/bin/env bash

# Set default variables
default_ipv4="${PIPE_DEFAULT_IPV4:-127.0.0.1}"
default_ipv6="${PIPE_DEFAULT_IPV6:-::1}"
default_mx="${PIPE_DEFAULT_MX:-localhost}"
default_ns="${PIPE_DEFAULT_NS:-localhost}"

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
          printf "DATA\t%s.\tIN\tNS\t60\t-1\t%s\n" "$qname" "$default_ns"
          ;;&
        CNAME)
          printf "FAIL\n"
          ;;&
        MX|ANY)
          printf "DATA\t%s.\tIN\tMX\t60\t-1\t10\t%s\n" "$qname" "$default_mx"
          ;;&
        SOA|ANY)
          printf "DATA\t%s.\tIN\tSOA\t60\t-1\t%s.\t%s.\t1\t900\t900\t1080\t60\n" "${qname#*.}" "$default_ns" "$default_ns"
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
