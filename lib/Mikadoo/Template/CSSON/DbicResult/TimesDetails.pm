use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::TimesDetails {

    # VERSION
    # ABSTRACT: Short intro

    use Moose::Role;
    use syntax 'junction';
    use experimental qw/postderef signatures/;

    sub column_details_for_strings($self, $data_type) {

        my $settings = {
            numeric => 0,
        };

        my $updatables = $self->term_get_multi('Update value on', [qw/set_on_create set_on_update none/], 'set_on_create');

        if(any(@$updatables) eq 'none') {
            say '[none] chosen. Value will not be updated automatically.';
            return $settings;
        }

        $settings->{ $_ } = 1 for @$attributes;

        return $settings;
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicResult::TimesDetails;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicResult::TimesDetails is ...

=head1 SEE ALSO

=cut