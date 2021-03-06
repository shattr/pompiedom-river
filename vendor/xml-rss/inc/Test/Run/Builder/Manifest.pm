package Test::Run::Builder::Manifest;

use strict;
use warnings;

use Module::Build;

use vars qw(@ISA);

@ISA = (qw(Module::Build));

sub find_test_files
{
    require Test::Manifest;

    return [Test::Manifest::get_t_files()];
}

sub ACTION_runtest
{
    my ($self) = @_;
    my $p = $self->{properties};

    $self->depends_on('code');

    local @INC = @INC;

    # Make sure we test the module in blib/
    unshift @INC, (File::Spec->catdir($p->{base_dir}, $self->blib, 'lib'),
		 File::Spec->catdir($p->{base_dir}, $self->blib, 'arch'));

    $self->do_test_run_tests;
}

sub ACTION_distruntest {
  my ($self) = @_;

  $self->depends_on('distdir');

  my $start_dir = $self->cwd;
  my $dist_dir = $self->dist_dir;
  chdir $dist_dir or die "Cannot chdir to $dist_dir: $!";
  # XXX could be different names for scripts

  $self->run_perl_script('Build.PL') # XXX Should this be run w/ --nouse-rcfile
      or die "Error executing 'Build.PL' in dist directory: $!";
  $self->run_perl_script('Build')
      or die "Error executing 'Build' in dist directory: $!";
  $self->run_perl_script('Build', [], ['runtest'])
      or die "Error executing 'Build test' in dist directory";
  chdir $start_dir;
}

sub do_test_run_tests
{
    my $self = shift;

    require Test::Manifest;
    require Test::Run::CmdLine::Iface;

    my $test_run =
        Test::Run::CmdLine::Iface->new(
            {
                'test_files' => $self->find_test_files(),
            }   
            # 'backend_params' => $self->_get_backend_params(),
        );

    return $test_run->run();
}

sub ACTION_tags
{
    my $self = shift;
    return 
        $self->do_system(
            "ctags",
            qw(-f tags --recurse --totals
    		--exclude=blib/** --exclude=t/lib/**
    		--exclude=**/.svn/** --exclude='*~'),
            "--exclude=".$self->dist_name()."-*/**",
            qw(--languages=Perl --langmap=Perl:+.t)
        );
}

1;

