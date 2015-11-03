use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::Numeric {

    # VERSION
    # ABSTRACT: Short intro

    use Moose::Role;
    use syntax 'junction';
    use Mojo::Util 'dumper';
    use experimental qw/postderef signatures/;

    sub setup_numeric_attributes($self) {

        # If attributes are added, also update the template.
        my $attributes = [map { split m/ \+ / } $self->term_get_multi('Attributes', ['is_auto_increment + unsigned', qw/is_auto_increment unsigned is_nullable zerofill none/], ['none'])->@*];
        my $settings = {
            is_numeric => 1,
        };

        $settings->{ $_ } = 1 for @$attributes;

        return $settings;
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicResult::Numeric;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicResult::Numeric is ...

=head1 SEE ALSO

=cut