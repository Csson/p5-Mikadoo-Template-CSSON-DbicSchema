use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicSchema {

    # VERSION
    # ABSTRACT: Short intro

    use MooseX::App::Command;
    extends 'App::Mikadoo';
    use File::ShareDir::Tarball 'dist_dir';
    use experimental qw/postderef signatures/;

    sub run($self) {
        $self->dist(__PACKAGE__ =~ s{::}{-}rg);

        $self->namespace_under('lib');
    }

}

1;

__END__

=pod

=head1 SYNOPSIS

    use Mikadoo::Template::CSSON::DbicSchema::CSSON;

=head1 DESCRIPTION

Mikadoo::Template::CSSON::DbicSchema is ...

=head1 SEE ALSO

=cut
