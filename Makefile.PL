#!/usr/bin/env perl
# $File: //member/autrijus/RTx-Report/Makefile.PL $ $Author: autrijus $
# $Revision: #10 $ $Change: 8721 $ $DateTime: 2003/11/06 16:06:31 $

use 5.006;
use inc::Module::Install;

warn << '.';
### PLEASE NOTE ##############################################

This is *PRE-ALPHA* code.  Using this module for anything
(except for learning purporses) is strongly discouraged.

##############################################################
.

# XXX - figure out how to install po/ and html/

author		('Autrijus Tang (autrijus@autrijus.org)');
name		('RTx-Report');
abstract	('RT Report Extension');
version_from	('lib/RTx/Report.pm');
requires	(
    'XML::Twig'		    => '3.00',
    'DBIx::ReportBuilder'   => '0.00_13',
);

sign		(1);
license		('perl');
include_deps	('Test::More', 5.006);
build_requires	('Test::More', 0);

&Meta->write;
&Makefile->write;
