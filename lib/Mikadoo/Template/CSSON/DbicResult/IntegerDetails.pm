use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::IntegerDetails;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0006';

use Moose::Role;
with qw/Mikadoo::Template::CSSON::DbicResult::Numeric/;
use experimental qw/postderef signatures/;

sub column_details_for_integers($self, $data_type) {
    my $settings = $self->setup_numeric_attributes;

    DEFAULT:
    while(1) {
        my $reply = $self->term_get_text('Default value', { shortcuts => [{ key => '[enter]', text => "Don't set" }, { key => '!', text => 'Set as null'}]});

        if(!defined $reply) {
            last DEFAULT;
        }
        elsif($reply eq '!') {
            $settings->{'default_value'} = undef;
            last DEFAULT if $reply eq '!';
        }
        elsif($reply =~ m{\D}) {
            say 'Only integers';
            next DEFAULT;
        }
        $settings->{'default_value'} = $reply;
        last DEFAULT;
    }

    DISPLAY_WIDTH:
    while(1) {
        my $reply = $self->term_get_text('Max display width', { shortcuts => [{ key => '0..255', text => '' }, { key => '[enter]', text => "Don't set"}]});
        last DISPLAY_WIDTH if !defined $reply;

        if($reply !~ m{\D} && $reply >= 0 && $reply <= 255) {
            $settings->{'size'} = $reply;
            last DISPLAY_WIDTH;
        }
        say 'Illegal value';
    }

    return $settings;
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicResult::IntegerDetails;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicResult::IntegerDetails is ...

=head1 SEE ALSO

=cut
