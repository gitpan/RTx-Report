#!/usr/bin/env perl
# $File: //member/autrijus/RTx-Report/Makefile.PL $ $Author: autrijus $
# $Revision: #5 $ $Change: 8138 $ $DateTime: 2003/09/14 20:21:02 $

use 5.006;
use inc::Module::Install;

include_deps   ('Test::More', 5.006);
build_requires ('Test::More', 0);

warn << '.';
### PLEASE NOTE ##############################################

This is *PRE-ALPHA* code.  Using this module for anything
(except for learning purporses) is strongly discouraged.

##############################################################
.

# XXX - figure out how to install po/ and html/

WriteMakefile (
    AUTHOR	    => 'Autrijus Tang (autrijus@autrijus.org)',
    NAME	    => 'RTx::Report',
    ABSTRACT	    => 'RT Report Extension',
    VERSION_FROM    => 'lib/RTx/Report_Overlay.pm',
    PREREQ_PM       => {
        'XML::Twig'		=> '3.00',
        'DBIx::ReportBuilder'	=> '0.00_07',
    },
);

