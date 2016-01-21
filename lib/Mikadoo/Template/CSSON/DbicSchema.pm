use 5.20.0;
use strict;
use warnings;

package Mikadoo::Template::CSSON::DbicSchema {

    # VERSION
    # ABSTRACT: Short intro

    use MooseX::App::Command;
    extends 'App::Mikadoo';
    use File::ShareDir::Tarball 'dist_dir';
    use Path::Tiny;
    use experimental qw/postderef signatures/;

    sub run($self) {
        $self->dist('Mikadoo-Template-CSSON-Dbic');

        $self->namespace_under('lib');

        $self->ask_perl_version({ from => 14 });
        $self->ask_experimentals;

        my $meta_location = path($self->location, qw<Schema Meta Dummy.pm>);
        $self->ensure_parents_exist($meta_location);
        say $meta_location->realpath;

        for my $file (qw<Schema.pm Config.pm>) {
            $self->render(path('schema', "$file.ep") => path($self->location, $file));
        }

        for my $file (qw<Result.pm ResultSet.pm ResultBase.pm ResultSetBase.pm>) {
            $self->render(path('schema', "$file.ep") => path($self->location, 'Schema', 'Meta', $file));
        }
=pod

        RESULT:
        while(1) {

            $self->result_name($self->term_get_text('Name of result source'));
            $self->enter_columns;
    
            $self->initialize_directories;
    
            $self->render(path(qw/result Result.pm.ep/) => $self->result_path);
            $self->render(path(qw/result ResultSet.pm.ep/) => $self->resultset_path);
            $self->clear_columns;

            my $reply = $self->term_get_one('Create more result classes?', [qw/yes no/], 'yes');
            last RESULT if $reply ne 'yes';
        }
=cut
        say 'Bye.';

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
