# $File: //member/autrijus/RTx-Report/lib/RTx/Reports_Overlay.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 7963 $ $DateTime: 2003/09/07 23:54:30 $

package RTx::Reports;
no warnings 'redefine';
use strict;

use RT::ACL;
use vars qw/$RIGHTS/;

# Reports rights are rights granted to the whole system
# XXX TODO Can't localize these outside of having an object around.
$RIGHTS = {
    Create         => 'Create',				# loc_pair
};

# Tell RT::ACE that this sort of object can get acls granted
$RT::ACE::OBJECT_TYPES{'RTx::Reports'} = 1;

foreach my $right ( keys %{$RIGHTS} ) {
    $RT::ACE::LOWERCASERIGHTNAMES{ lc $right } = $right;
}


=head2 AvailableRights

Returns a hash of available rights for this object. The keys are the right names and the values are a description of what the rights do

=begin testing

=cut

sub AvailableRights {
    my $self = shift;

    my $report = RTx::Report->new($RT::SystemUser);
    my $rr = $report->AvailableRights();

    # Build a merged list of all system wide rights, queue rights and group rights.
    my %rights = (%{$RIGHTS}, %{$rr});
    return(\%rights);
}

=head2 id

Returns RTx::Reports's id. It's 1. 

=cut

*Id = \&id;

sub id {
    return (1);
}

=head2 Load

Since this object is pretending to be an RT::Record, we need a load method.
It does nothing

=cut

sub Load {
	return (1);
}

sub ReportObj {
    my $self = shift;
    my $id   = shift;
    my $obj = RTx::Report->new($self->CurrentUser);
    $obj->LoadById($id);
    return $obj if $obj->Id;
    return;
}

$RTx::Reports ||= RTx::Reports->new($RT::SystemUser);

eval "require RTx::Reports_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RTx/Reports_Vendor.pm});
eval "require RTx::Reports_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RTx/Reports_Local.pm});

1;
