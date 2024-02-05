#!/usr/bin/perl -w
# sample PowerDNS Coprocess backend with edns-client-subnet support
#

use strict;

$|=1;					# no buffering

my $line=<>;
chomp($line);

unless($line eq "HELO\t3" ) {
	print "FAIL\n";
	print STDERR "Received unexpected '$line', wrong ABI version?\n";
	<>;
	exit;
}
print "OK\tPerl backend firing up\n";	# print our banner

while(<>)
{
	print STDERR "$$ Received: $_";
	chomp();
	my @arr=split(/\t/);
	if(@arr < 8) {
		print "LOG	PowerDNS sent unparseable line\n";
		print "FAIL\n";
		next;
	}

	# Need the root domain for the SOA record and to ignore TLD's and . queries


	my ($type,$qname,$qclass,$qtype,$id,$ip,$localip,$ednsip)=split(/\t/);
#	my $domain = `/var/lib/powerdns/bin/powerdns domain:root $qname`;
	my $bits=21;
	my $auth = 1;

#	if (!defined($domain) || $domain eq '') {
#		print STDERR "$$ Domain is null or empty, skipping record processing\n";
#		print "END\n";
#		next;
#	}

    my $primary_ns;
    if (exists $ENV{"PIPE_DEFAULT_NS"}) {
        ($primary_ns) = split(',', $ENV{"PIPE_DEFAULT_NS"});
    }

	if(($qtype eq "SOA" || $qtype eq "ANY")) {
		print STDERR "$$ Sent SOA records\n";

        if (exists $ENV{"PIPE_DEFAULT_NS"}) {
            my @ns_records = split(',', $ENV{"PIPE_DEFAULT_NS"});
#			print "DATA	$bits	$auth	$qname	$qclass	SOA	3600	-1	$primary_ns hostmaster.$domain 2008080300 1800 3600 604800 3600\n";
			print "DATA\t$bits\t$auth\t$qname\t$qclass\tSOA\t3600\t-1\t$primary_ns\thostmaster.$primary_ns\t2008080300\t1800\t3600\t604800\t3600\n";
        } else {
#			print "DATA	$bits	$auth	$qname	$qclass	SOA	3600	-1	ns1.localhost hostmaster.$domain 2008080300 1800 3600 604800 3600\n";
			print "DATA\t$bits\t$auth\t$qname\t$qclass\tSOA\t3600\t-1\tns1.localhost\thostmaster.$primary_ns\t2008080300\t1800\t3600\t604800\t3600\n";
        }
	}

	if(($qtype eq "NS" || $qtype eq "ANY")) {
        print STDERR "$$ Sent NS records\n";

        if (exists $ENV{"PIPE_DEFAULT_NS"}) {
            my @ns_records = split(',', $ENV{"PIPE_DEFAULT_NS"});
            foreach my $ns (@ns_records) {
                print "DATA\t$bits\t$auth\t$qname\t$qclass\tNS\t3600\t-1\t$ns\n";
            }
        } else {
        	print "DATA\t$bits\t$auth\t$qname\t$qclass\tNS\t3600\t-1\tns1.domain.link\n";
			print "DATA\t$bits\t$auth\t$qname\t$qclass\tNS\t3600\t-1\tns2.domain.link\n";
        }
	}

	if(($qtype eq "TXT" || $qtype eq "ANY")) {
		print STDERR "$$ Sent TXT records\n";
		print "DATA\t$bits\t$auth\t$qname\t$qclass\tTXT\t3600\t-1\t\"Managed domain please visit https://domain.link!\"\n";
	}

	if(($qtype eq "A" || $qtype eq "ANY")) {
		print STDERR "$$ Sent A records\n";
        if (exists $ENV{"PIPE_DEFAULT_IPV4"}) {
            my @ipv4_addresses = split(',', $ENV{"PIPE_DEFAULT_IPV4"});
            foreach my $ipv4 (@ipv4_addresses) {
                print "DATA\t$bits\t$auth\t$qname\t$qclass\tA\t3600\t-1\t$ipv4\n";
            }
        } else {
			print "DATA\t$bits\t$auth\t$qname\t$qclass\tA\t3600\t-1\t127.0.0.1\n";
        }
	}

	if(($qtype eq "AAAA" || $qtype eq "ANY")) {
        print STDERR "$$ Sent AAAA records\n";
        if (exists $ENV{"PIPE_DEFAULT_IPV6"}) {
            my @ipv6_addresses = split(',', $ENV{"PIPE_DEFAULT_IPV6"});
            foreach my $ipv6 (@ipv6_addresses) {
                print "DATA\t$bits\t$auth\t$qname\t$qclass\tAAAA\t3600\t-1\t$ipv6\n";
            }
        } else {
			print "DATA\t$bits\t$auth\t$qname\t$qclass\tAAAA\t3600\t-1\t::1\n";
		}
	}

	if(($qtype eq "MX" || $qtype eq "ANY")) {
        print STDERR "$$ Sent MX records\n";

        if (exists $ENV{"PIPE_DEFAULT_MX"}) {
            my @mx_records = split(',', $ENV{"PIPE_DEFAULT_MX"});
            foreach my $mx_record (@mx_records) {
                my ($priority, $mailserver) = split(' ', $mx_record);
                print "DATA\t$bits\t$auth\t$qname\t$qclass\tMX\t3600\t-1\t$priority\t$mailserver\n";
            }
        } else {
			print "DATA\t$bits\t$auth\t$qname\t$qclass\tMX\t3600\t-1\t10\tmxa.srvxx.dev\n";
        }
	}

	print STDERR "$$ End of data\n";
	print "END\n";
}