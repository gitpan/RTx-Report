
use strict;
no warnings 'redefine';

sub Create {
    my $self = shift;
    my %args = ( 
                Name => '',
                Description => '',
                Driver => '',
                Database => '',
                Host => '',
                User => '',
                Password => '',
                Disabled => '0',

		  @_);
    $self->SUPER::Create(
                         Name => $args{'Name'},
                         Description => $args{'Description'},
                         Driver => $args{'Driver'},
                         DB => ($args{'Database'} || $args{'DB'}),
                         Host => $args{'Host'},
                         User => $args{'User'},
                         Password => $args{'Password'},
                         Disabled => $args{'Disabled'},
);

}

sub Database {
    my $self = shift;
    return $self->DB(@_);
}

sub SetDatabase {
    my $self = shift;
    return $self->SetDB(@_);
}

sub LoadByName {
    my $self = shift;
    my $identifier = shift;
    $self->LoadByCol("Name" => $identifier);
}

sub Handle {
    my $self = shift;
    my %args = (
	map { $_ => $self->$_ }
	    qw(Driver Database Host User Password),
    );
    $args{Port} = $1 if $args{Host} =~ s/:(\d+)$//;
    $self->{handle} = DBIx::SearchBuilder::Handle->new;
    $self->{handle}->Connect( %args );
    return $self->{handle};
}

1;


