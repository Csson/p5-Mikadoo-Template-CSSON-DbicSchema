use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::DecimalDetails {

    # VERSION
    # ABSTRACT: Short intro

    use Moose::Role;
    use experimental qw/postderef signatures/;

    sub column_details_for_decimals($self, $data_type) {
        my $attributes = $self->term_get_multi('Attributes', [qw/is_auto_increment unsigned is_nullable zerofill none/], ['none']);
        my $settings = {
            is_numeric => 1,
        };
    }
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
