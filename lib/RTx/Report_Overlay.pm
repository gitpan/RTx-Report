# $File: //member/autrijus/RTx-Report/lib/RTx/Report_Overlay.pm $ $Author: autrijus $
# $Revision: #17 $ $Change: 8478 $ $DateTime: 2003/10/19 01:40:28 $

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

use vars qw($RIGHTS);
use RT::ACL;
use DBIx::ReportBuilder;

$RIGHTS = {
    ShowACL		=> 'Display Access Control List',              # loc_pair
    ModifyACL		=> 'Modify Access Control List',               # loc_pair
#   CreateReport -- belongs to ::Reports
    SeeReport		=> 'Can this principal see this report',       # loc_pair
    PrintReport		=> 'Print report',			# loc_pair
    SaveReport		=> 'Save report',			# loc_pair
    DeleteReport	=> 'Delete report',			# loc_pair
    CopyReport		=> 'Copy report',			# loc_pair
    ImportReport	=> 'Import report',			# loc_pair
    ExportReport	=> 'Export report',			# loc_pair
    PartP		=> 'Insert and modify part P',		# loc_pair
    PartImg		=> 'Insert and modify part Img',	# loc_pair
    PartGraph		=> 'Insert and modify part Graph',	# loc_pair
    PartTable		=> 'Insert and modify part Table',	# loc_pair
    PartInclude		=> 'Insert and modify part Include',	# loc_pair
    ClauseJoin		=> 'Insert and modify clause Join',	# loc_pair
    ClauseLimit		=> 'Insert and modify clause Limit',	# loc_pair
    ClauseOrderby	=> 'Insert and modify clause Orderby',	# loc_pair
    ClauseCell		=> 'Insert and modify clause Cell',	# loc_pair
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


sub _Accessible {
    my $self = shift;
    my %Cols = (
        id            => 'read',
        Name          => 'read/write',
        Category      => 'read/write',
        Description   => 'read/write',
        Content       => 'read/write',
        Queue         => 'read/write',
        Owner         => 'read/write',
        Disabled      => 'read/write',
        Creator       => 'read/auto',
        Created       => 'read/auto',
        LastUpdatedBy => 'read/auto',
        LastUpdated   => 'read/auto'
    );
    return $self->SUPER::_Accessible( @_, %Cols );
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
            Object => $RT::System,
            Right    => 'SuperUser',
          ) or
        $args{'Principal'}->HasRight(
            Object => $RTx::Reports,
            Right    => $args{'Right'}
          ) or
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
    return $self->ParseContent($self->Content);
}

sub NewContent {
    my $self = shift;
    return DBIx::ReportBuilder->new->NewContent;
}

sub SetContentObj {
    my $self = shift;
    my $obj  = shift;
    $self->SetContent($obj->sprint);
}

my $_id;
sub ParseContent {
    my $self = shift;
    my $obj = DBIx::ReportBuilder->new(
	Handle	=> $self->Handle,
	Content	=> $_[0],
    );
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

sub HandleObj {
    my $self = shift;
    $self->ReportSourceObj->HandleObj;
}

sub Keys {
    qw(Name Description Category Author Disabled ReportSource Content);
}

sub Views {
    qw(Edit Preview PDF MSExcel);
}

sub Sets {
    qw(Parameter Page);
}

sub SearchHook {
    my $self = shift;
    return sub { $self->SearchHookCompany(@_) if $self->can('SearchHookCompany') };
}

1;
