use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::IntegerDetails {

    # VERSION
    # ABSTRACT: Short intro

    use Moose::Role;
    use experimental qw/postderef signatures/;

    sub column_details_for_integers($self, $data_type) {
        my $attributes = $self->term_get_multi('Attributes', [qw/is_auto_increment unsigned is_nullable zerofill none/], ['none']);
        my $settings = {
            is_numeric => 1,
        };

        $settings->{'is_auto_increment'} = 1 if any(@$attributes) eq 'is_auto_increment';
        $settings->{'is_nullable'} = 1 if any(@$attributes) eq 'is_nullable';
        $settings->{'extra'}{'unsigned'} = 1 if any(@$attributes) eq 'unsigned';
        $settings->{'extra'}{'zerofill'} = 1 if any(@$attributes) eq 'zerofill';

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
