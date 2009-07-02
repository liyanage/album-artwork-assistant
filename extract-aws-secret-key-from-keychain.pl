#!/usr/bin/perl

use strict;
use warnings;
use bytes;

use IO::File;

my ($key) = qx(security find-generic-password -g -s 'Amazon AWS Secret Key 1' 2>&1 1>/dev/null) =~ /"(.+)"/;
die "Unable to get key from keychain" unless $key;

my $gzipped = qx(echo -n $key | gzip -n --best -c);

my @values = map {ord($_)} split(//, $gzipped);

my $builddir = $ENV{CONFIGURATION_BUILD_DIR} || '';

die "CONFIGURATION_BUILD_DIR '$builddir' invalid" unless (-d $builddir);
die "Unable to mkdir output dir" if (system(qq(mkdir -p "$ENV{CONFIGURATION_BUILD_DIR}/include")) >> 8);

my $file = IO::File->new(">$ENV{CONFIGURATION_BUILD_DIR}/include/amazon_aws_secret_key.h");
die unless $file;
$file->print("#define AMAZON_AWS_SECRET_KEY_BYTES {" . join(', ', @values) . "}\n");
$file->print("#define AMAZON_AWS_SECRET_KEY_LENGTH " . @values . "\n");

