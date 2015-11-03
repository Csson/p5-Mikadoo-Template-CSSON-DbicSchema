use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicResult::StringDetails {

    # VERSION
    # ABSTRACT: Short intro

    use Moose::Role;
    use syntax 'junction';
    use experimental qw/postderef signatures/;

    sub column_details_for_strings($self, $data_type) {

        my $settings = {
            numeric => 0,
        };

        DEFAULT:
        while(1) {
            my $reply = $self->term_get_text('Default value', { shortcuts => [{ key => '[enter]', text => "Don't set" }, { key => '!', text => 'Set as null'}, { key => '_', text => 'Set as empty string'}]});
            
            if(!defined $reply) {
                last DEFAULT;
            }
            elsif($reply eq '!') {
                $settings->{'default_value'} = undef;
                last DEFAULT if $reply eq '!';
            }
            elsif($reply eq '_') {
                $settings->{'default_value'} = '';
                last DEFAULT;
            }
            $settings->{'default_value'} = $reply;
            last DEFAULT;
        }

        if(any(qw/char varchar text binary varbinary blob/) eq $data_type) {
            MAX_LENGTH:
            while(1) {
                my $reply = $self->term_get_text('Max display width', { shortcuts => [{ key => '[enter]', text => "Don't set"}]});
                last MAX_LENGTH if !defined $reply;
    
                if($reply !~ m{\D} && $reply >= 0) {
                    $settings->{'size'} = $reply;
                    last MAX_LENGTH;
                }
                say 'Illegal value';
            }
        }

        return $settings;
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicResult::StringDetails;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicResult::StringDetails is ...

=head1 SEE ALSO

=cut
