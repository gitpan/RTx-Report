# $File: //member/autrijus/RTx-Report/lib/RTx/Report_Overlay.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 7964 $ $DateTime: 2003/09/08 00:05:41 $

=head1 NAME

  RTx::Report - an RT Report object

=head1 SYNOPSIS

  use RTx::Report;

=head1 DESCRIPTION


=head1 METHODS

=begin testing 

use RTx::Report;

=end testing

=cut

use strict;
no warnings qw(redefine);
our $VERSION = '0.00_01';

use vars qw($RIGHTS);
use RT::Groups;
use RT::ACL;
use XML::Twig;

$RIGHTS = {
    SeeReport		=> 'Can this principal see this report',       # loc_pair
    ShowACL		=> 'Display Access Control List',              # loc_pair
    ModifyACL		=> 'Modify Access Control List',               # loc_pair
    Print		=> 'Print',
    Save		=> 'Save',
    Delete		=> 'Delete',
    Copy		=> 'Copy',
    Import		=> 'Import',
    Export		=> 'Export',
    P			=> 'P',
    IMG			=> 'IMG',
    GRAPH		=> 'GRAPH',
    TABLE		=> 'TABLE',
    SUBREPORT		=> 'SUBREPORT',
};

# Tell RT::ACE that this sort of object can get acls granted
$RT::ACE::OBJECT_TYPES{'RTx::Report'} = 1;

# TODO: This should be refactored out into an RT::ACLedObject or something
# stuff the rights into a hash of rights that can exist.

foreach my $right ( keys %{$RIGHTS} ) {
    $RT::ACE::LOWERCASERIGHTNAMES{ lc $right } = $right;
}
    

=head2 AvailableRights

Returns a hash of available rights for this object. The keys are the right names and the values are a description of what the rights do

=cut

sub AvailableRights {
    my $self = shift;
    return($RIGHTS);
}


# {{{ sub Create

=head2 Create

Create takes the name of the new report 
If you pass the ACL check, it creates the report and returns its report id.

=cut

sub Create {
    my $self = shift;
    my %args = (
        Name              => undef,
        Category	  => '',
        Description       => '',
	Content		  => '',
        @_
    );

    unless ( $self->CurrentUser->HasRight(Right => 'Create', Object => $RTx::Reports) )
    {    #Check them ACLs
        return ( 0, $self->loc("No permission to create reports") );
    }

    unless ( $self->ValidateName( $args{'Name'} ) ) {
        return ( 0, $self->loc('Report already exists') );
    }

    #TODO better input validation
    $RT::Handle->BeginTransaction();

    my $id = $self->SUPER::Create(%args);
    unless ($id) {
        $RT::Handle->Rollback();
        return ( 0, $self->loc('Report could not be created') );
    }

    $RT::Handle->Commit();
    return ( $id, $self->loc("Report created") );
}

# }}}

# {{{ sub Delete 

sub Delete {
    my $self = shift;
    return ( 0,
        $self->loc('Deleting this object would break referential integrity') );
}

# }}}

# {{{ sub SetDisabled

=head2 SetDisabled

Takes a boolean.
1 will cause this report to no longer be avaialble for tickets.
0 will re-enable this report

=cut

# }}}

# {{{ sub Load 

=head2 Load

Takes either a numerical id or a textual Name and loads the specified report.

=cut

sub Load {
    my $self = shift;

    my $identifier = shift;
    if ( !$identifier ) {
        return (undef);
    }

    if ( $identifier =~ /^(\d+)$/ ) {
        $self->SUPER::LoadById($identifier);
    }
    else {
        $self->LoadByCol( "Name", $identifier );
    }

    return ( $self->Id );

}

# }}}

# {{{ sub ValidateName

=head2 ValidateName NAME

Takes a report name. Returns true if it's an ok name for
a new report. Returns undef if there's already a report by that name.

=cut

sub ValidateName {
    my $self = shift;
    my $name = shift;

    my $tempreport = new RTx::Report($RT::SystemUser);
    $tempreport->Load($name);

    #If we couldn't load it :)
    unless ( $tempreport->id() ) {
        return (1);
    }

    #If this report exists, return undef
    #Avoid the ACL check.
    if ( $tempreport->Name() ) {
        return (undef);
    }

    #If the report doesn't exist, return 1
    else {
        return (1);
    }

}

# }}}

# {{{ ACCESS CONTROL

# {{{ sub _Set
sub _Set {
    my $self = shift;

    unless ( $self->CurrentUserHasRight('AdminReport') ) {
        return ( 0, $self->loc('Permission Denied') );
    }
    return ( $self->SUPER::_Set(@_) );
}

# }}}

# {{{ sub _Value

sub _Value {
    my $self = shift;

    unless ( $self->CurrentUserHasRight('SeeReport') ) {
        return (undef);
    }

    return ( $self->__Value(@_) );
}

# }}}

# {{{ sub CurrentUserHasRight

=head2 CurrentUserHasRight

Takes one argument. A textual string with the name of the right we want to check.
Returns true if the current user has that right for this report.
Returns undef otherwise.

=cut

sub CurrentUserHasRight {
    my $self  = shift;
    my $right = shift;

    return (
        $self->HasRight(
            Principal => $self->CurrentUser,
            Right     => "$right"
          )
    );

}

# }}}

# {{{ sub HasRight

=head2 HasRight

Takes a param hash with the fields 'Right' and 'Principal'.
Principal defaults to the current user.
Returns true if the principal has that right for this report.
Returns undef otherwise.

=cut

# TAKES: Right and optional "Principal" which defaults to the current user
sub HasRight {
    my $self = shift;
    my %args = (
        Right     => undef,
        Principal => $self->CurrentUser,
        @_
    );
    unless ( defined $args{'Principal'} ) {
        $RT::Logger->debug("Principal undefined in Report::HasRight");

    }
    return (
        $args{'Principal'}->HasRight(
            Object => $self,
            Right    => $args{'Right'}
          )
    );
}

# }}}

sub OwnerObj {
    my $self = shift;
    my $owner = new RT::User( $self->CurrentUser );
    $owner->Load( $self->__Value('Owner') );
    return ($owner);
}

sub LoadByName {
    my $self = shift;
    my $identifier = shift;
    $self->LoadByCol("Name" => $identifier);
}

sub ContentObj {
    my $self = shift;

    my $obj = XML::Twig->new( @_ );
    $obj->parse($self->Content);
    return $obj;
}

sub NewContent {
    my $self = shift;

    my $obj = XML::Twig->new( @_ );
    $obj->parse(
	'<?xml version="1.0" encoding="UTF-8"?>'.
	'<html xmlns="http://aut.dyndns.org/RG/xhtml" />'
    );

    my $root = $obj->root;
    my $body = $root->insert_new_elt( 'body' );
    my $head = $root->insert_new_elt( 'head' );
    $body->insert_new_elt( last_child => $_ )->insert_new_elt( 'p' )
	foreach qw(preamble header content footer postamble);
    $head->set_att(orientation => 'portrait');
    $head->set_att(paper => 'a4paper');

    return $obj->sprint;
}

sub SetContentObj {
    my $self = shift;
    my $obj  = shift;
    $self->SetContent($obj->sprint);
}

my $_id;
sub ParseContent {
    my $self = shift;
    my $obj = XML::Twig->new(
	twig_handlers => {
	    map { lc($_) => \&_id } $self->Objects,
	}
    );

    $_id = 0;
    $obj->parse($_[0]);
    return $obj;
}

sub _id {
    $_->set_id( ++$_id );
}

sub Author {
    my $self = shift;
    $self->OwnerObj->Name;
}

sub SetAuthor {
    my $self = shift;
    my $name = shift;
    my $OwnerObj = RT::User->new($self->CurrentUser);
    $OwnerObj->Load($name);
    $self->SetOwner($OwnerObj->Id) if $OwnerObj->Id;
}

sub ReportSourceObj {
    my $self = shift;
    my $ReportSourceObj = RTx::ReportSource->new($self->CurrentUser);
    $ReportSourceObj->Load($self->ReportSource);
    return $ReportSourceObj;
}

sub Handle {
    my $self = shift;
    $self->ReportSourceObj->Handle;
}

sub Keys {
    qw(Name Description Category Author Disabled ReportSource Content);
}

sub Vars {
    qw(Page PageCount Date Time ReportName);
}

sub Fields {
    qw(Data Function Formula Statistics Grouping);
}

sub Views {
    qw(Edit Preview PDF);
}

sub Objects {
    qw(P Img Table Graph Include);
}

sub Parts {
    qw(p img table graph include);
}

sub Clauses {
}

sub Sets {
    qw(Parameter Page); # XXX Condition
}

my %TypeMap = (
    P           => [ qw/align font size border/ ],
    VAR         => [ qw/align font size border/ ],
    IMG         => [ qw/alt width height/ ],
    TABLE       => [ qw/width height/ ],
    GRAPH       => [ qw/type style legend threed threed_shading cumulate show_values values_vertical rotate_chart title/ ],
    SUBREPORT   => []
);

sub Attrs {
    my ($self, $obj) = @_;
    return \%TypeMap unless $obj;
    @{$TypeMap{uc($obj)}};
}

1;
