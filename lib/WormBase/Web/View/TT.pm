package WormBase::Web::View::TT;

use strict;
use parent 'Catalyst::View::TT';
use Template::Constants ':debug';

use Template::Stash;

$Template::Stash::ROOT_OPS->{ ref } = sub {
   return ref ($_[0]);
};

__PACKAGE__->config({
		     INCLUDE_PATH => [
				      WormBase::Web->path_to( 'root', 'templates' ),
				      WormBase::Web->path_to( 'root', 'templates' , 'config'),
				     ],
		     PRE_PROCESS  => ['config/main','shared/page_elements.tt2'],
		     WRAPPER      => 'wrapper.tt2',
#		     ERROR        => 'error',
		     TEMPLATE_EXTENSION => '.tt2',
		     RECURSION    => 1,
			 EVAL_PERL => 1,
			 render_die => 1,
		     # Automatically pre- and post-chomp to keep
		     # templates simpler and output cleaner.
		     # Might want to use "2" instead, which collapses.
			 
		     PRE_CHOMP    => 2,
		     POST_CHOMP   => 2,
		     # NOT CURRENTLY IN USE!
#		     PLUGIN_BASE  => 'WormBase::Web::View::Template::Plugin',
		     PLUGINS      => {
#				      url    => 'WormBase::Web::View::Template::Plugin::URL',
#				      image  => 'Template::Plugin::Image',
#				      format => 'Template::Plugin::Format',
#				      util   => 'WormBase::Web::View::Template::Plugin::Util',
				     },
#		     TIMER        => 1,
#		     DEBUG        => DEBUG_DIRS | DEBUG_STASH | DEBUG_CONTEXT | DEBUG_PROVIDER | DEBUG_SERVICE,
		     CONSTANTS    => {
			 acedb_version => sub {
			     WormBase::Web->model('WormBaseAPI')->version
			 }
		     },
		    });



=head1 NAME

WormBase::Web::View::TT - Catalyst View

=head1 SYNOPSIS

See L<WormBase>

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Todd Harris

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

