#!/usr/bin/env bash

#if [ yes != "$STDBUF" ]; then
#    STDBUF=yes /usr/bin/stdbuf -i0 -o0 -e0 "$0"
#    exit $?
#fi

# Set default variables
default_ipv4="${PIPE_DEFAULT_IPV4:-127.0.0.1}"
default_ipv6="${PIPE_DEFAULT_IPV6:-::1}"
default_mx="${PIPE_DEFAULT_MX:-localhost}"
default_ns="${PIPE_DEFAULT_NS:-localhost}"

echoerr() { echo "$@" 1>&2; }

# Read input line by line from stdin
while IFS=$'#\t\n' read -r input; do

  echoerr $$; echoerr $BASHPID
  echoerr $input;

  # Extract command, qname, and qtype from the input in one awk call
  read -r command qname _ qtype _ <<< $(echo "$input" | awk '{print $1, $2, $3, $4, $5}')

  # Process the input based on the command
  case "$command" in
    HELO)
      # Respond to the HELO command
      printf "OK\tStarting Bash Backend\n"
      ;;

    Q)
      root_domain=$(/var/lib/powerdns/bin/powerdns domain:root "$qname")

      echoerr "$qname"

      # Handle DNS query types
      if [ "$qname" = "." ]; then
        printf "\n"
      elif [ "$root_domain" == '' ]; then
        printf "\n"
      else
        case "$qtype" in
          A|ANY)
            printf "DATA\t%s.\tIN\tA\t60\t-1\t%s\n" "$qname" "$default_ipv4"
            echoerr "DATA\t$qname.\tIN\tA\t60\t-1\t$default_ipv4\n"
            ;;&
          AAAA|ANY)
            printf "DATA\t%s.\tIN\tAAAA\t60\t-1\t%s\n" "$qname" "$default_ipv6"
            echoerr "DATA\t$qname.\tIN\tAAAA\t60\t-1\t$default_ipv6\n"
            ;;&
          NS|ANY)
            printf "DATA\t%s.\tIN\tNS\t60\t-1\t%s\n" "$qname" "$default_ns"
            echoerr "DATA\t$qname.\tIN\tNS\t60\t-1\t$default_ns\n"
            ;;&
          MX|ANY)
            printf "DATA\t%s.\tIN\tMX\t60\t-1\t10\t%s\n" "$qname" "$default_mx"
            echoerr "DATA\t$qname.\tIN\tMX\t60\t-1\t10\t$default_mx\n"
            ;;&
          SOA|ANY)
            printf "DATA\t%s.\tIN\tSOA\t60\t-1\t%s.\thostmaster.%s.\t1\t900\t900\t1080\t60\n" "$root_domain" "$default_ns" "$root_domain"
            echoerr "DATA\t$root_domain.\tIN\tSOA\t60\t-1\t$default_ns.\thostmaster.$root_domain.\t1\t900\t900\t1080\t60\n"
            ;;
        esac
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
