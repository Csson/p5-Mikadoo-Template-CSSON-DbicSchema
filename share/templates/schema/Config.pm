%   if($self->has_perl_version) {
                    use <%= $self->perl_version %>;
%   }
                    use strict;
                    use warnings;

                    package <%= $self->namespace %>::Config {
                        use Moo;
                        with 'Config::FromHash::Auto';
                        use Dir::Self;

                        sub package { __PACKAGE__ }
                        sub dir { __DIR__ }

                    }

                    1;
                    
<%= '__END__' %>

=pod

=head1 SYNOPSIS

    use <%= $self->namespace %>::Config;
    my $config = <%= $self->namespace %>::Config->new;
    my $value = $config->config->get('group/setting');

=head1 DESCRIPTION

<%= $self->namespace %>::Config is the configuration handler for L<<%= $self->namespace %>>.

=head1 SEE ALSO

=cut
