use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::DecimalDetails;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0004';

use Moose::Role;
use experimental qw/postderef signatures/;

sub column_details_for_decimals($self, $data_type) {
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
        elsif($reply =~ m{[^\d.]}) {
            say 'Only numbers and . allowed';
            next DEFAULT;
        }
        $settings->{'default_value'} = $reply;
        last DEFAULT;
    }

    my $size = [];
    my @questions = $data_type eq 'float(p)' ? ('Precision in bits')
                                             :  ('Number of digits', 'Number of decimal points')
                                             ;

    QUESTION:
    for my $question (@questions) {

        LOOP:
        while(1) {
            my $number_of_digits = $self->term_get_text($question, { shortucts => [{ key => '[enter]', text => "Don't set" }]});

            next QUESTION if !defined $number_of_digits;
            if($number_of_digits =~ m{\D}) {
                say 'Only integers allowed';
                next LOOP;
            }
            elsif($number_of_digits < 0) {
                say 'Only non-negative integers allowed';
                next LOOP;
            }
            push @$size => $number_of_digits;
            next QUESTION;
        }
    }

    if(scalar @$size) {
        $settings->{'size'} = scalar @$size == 1 ? $size->[0] : $size;
    }

    return $settings;
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicResult::DecimalDetails;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicResult::DecimalDetails is ...

=head1 SEE ALSO

=cut
