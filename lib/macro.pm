use strict;
use warnings;

package macro;

use Devel::Declare ();
use aliased 'Devel::Declare::Context::Simple' => 'DDContext';
use Sub::Install 'install_sub';

use namespace::clean;

sub import {
    my ($class, %macros) = @_;
    my $setup_class = caller;
    $class->setup_for($setup_class, %macros);
}

sub setup_for {
    my ($class, $setup_class, %macros) = @_;

    install_sub({
        code => sub () { 0 },
        into => $setup_class,
        as   => $_,
    }) for keys %macros;

    Devel::Declare->setup_for($setup_class => {
        (map {;
            my $macro = $_;
            $macro => {
                const => sub {
                    my $self = $class->new({
                        class => $setup_class,
                        macro => $macro,
                        subst => $macros{$macro},
                    });
                    $self->ctx->init(@_);

                    return $self->parse;
                },
            },
        } keys %macros)
    });

    return;
}

sub new {
    my ($class, $args) = @_;
    my $self = bless {
        ctx => DDContext->new,
        %$args,
    } => $class;

    return $self;
}

sub ctx { shift->{ctx} }

sub subst {
    my ($self) = @_;
    return q{ && 0 || (} . $self->{subst} . q{)};
}

sub parse {
    my ($self) = @_;
    $self->ctx->skip_declarator;

    my $line = $self->ctx->get_linestr;
    substr($line, $self->ctx->offset, 0) = $self->subst;
    $self->ctx->set_linestr($line);

    return;
}

1;
