use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::Numeric {

    # VERSION
    # ABSTRACT: Short intro

    use Moose::Role;
    use experimental qw/postderef signatures/;

    sub setup_numeric_attributes($self, $data_type) {
        my $attributes = $self->term_get_multi('Attributes', [qw/is_auto_increment unsigned is_nullable zerofill none/], ['none']);
        my $settings = {
            is_numeric => 1,
        };

        $settings->{'is_auto_increment'} = 1 if any(@$attributes) eq 'is_auto_increment';
        $settings->{'is_nullable'} = 1 if any(@$attributes) eq 'is_nullable';
        $settings->{'extra'}{'unsigned'} = 1 if any(@$attributes) eq 'unsigned';
        $settings->{'extra'}{'zerofill'} = 1 if any(@$attributes) eq 'zerofill';

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
